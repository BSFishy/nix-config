use std::{collections::BTreeMap, fs, path::Path};

use rusqlite::{Connection, OptionalExtension, params};
use serde_json::Value;

use crate::{SavePayload, error::BackendError};

pub struct Database {
    connection: Connection,
    database_path: String,
}

pub struct SaveSummary {
    pub inserted: u64,
    pub skipped: u64,
}

pub struct Stats {
    pub total_memories: u64,
    pub by_source: BTreeMap<String, u64>,
    pub database_path: String,
}

impl Database {
    pub fn open(database_path: &Path) -> Result<Self, BackendError> {
        if let Some(parent) = database_path.parent() {
            fs::create_dir_all(parent)?;
        }

        let connection = Connection::open(database_path)?;
        connection.pragma_update(None, "journal_mode", "WAL")?;
        connection.pragma_update(None, "foreign_keys", "ON")?;

        let database = Self {
            connection,
            database_path: database_path.display().to_string(),
        };
        database.initialize_schema()?;
        Ok(database)
    }

    pub fn stats(&self) -> Result<Stats, BackendError> {
        let total_memories = self.connection.query_row(
            "SELECT COUNT(*) FROM memories",
            [],
            |row| row.get::<_, i64>(0),
        )? as u64;

        let mut statement = self.connection.prepare(
            "SELECT source, COUNT(*) FROM memories GROUP BY source ORDER BY source",
        )?;
        let rows = statement.query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, i64>(1)? as u64))
        })?;

        let mut by_source = BTreeMap::new();
        for row in rows {
            let (source, count) = row?;
            by_source.insert(source, count);
        }

        Ok(Stats {
            total_memories,
            by_source,
            database_path: self.database_path.clone(),
        })
    }

    pub fn save_payload(
        &mut self,
        payload: &SavePayload,
        embedding_model: Option<&str>,
        embeddings: &[Option<Vec<f32>>],
    ) -> Result<SaveSummary, BackendError> {
        let transaction = self.connection.transaction()?;
        let mut inserted = 0_u64;
        let mut skipped = 0_u64;

        for (chunk_index, chunk) in payload.chunks.iter().enumerate() {
            let embedding = embeddings.get(chunk_index).cloned().flatten();
            let metadata = merge_metadata(payload.metadata.as_ref(), chunk.metadata.as_ref());
            let metadata_text = metadata.as_ref().map(serde_json::to_string).transpose()?;

            let existing_id = transaction
                .query_row(
                    "
                    SELECT id
                    FROM memories
                    WHERE session_key = ?1
                      AND source = ?2
                      AND created_at = ?3
                      AND chunk_index = ?4
                      AND content = ?5
                    LIMIT 1
                    ",
                    params![
                        payload.session_key,
                        payload.source,
                        chunk.created_at,
                        chunk_index as i64,
                        chunk.content,
                    ],
                    |row| row.get::<_, i64>(0),
                )
                .optional()?;

            if existing_id.is_some() {
                skipped += 1;
                continue;
            }

            let embedding_blob = embedding.as_ref().map(|value| f32_vec_to_blob(value));
            let embedding_dimensions = embedding.as_ref().map(|value| value.len() as i64);
            let embedding_status = if embedding.is_some() { "ready" } else { "pending" };

            transaction.execute(
                "
                INSERT INTO memories (
                  session_key,
                  session_file,
                  source,
                  created_at,
                  cwd,
                  git_branch,
                  leaf_id,
                  chunk_index,
                  content,
                  embedding,
                  embedding_dimensions,
                  embedding_model,
                  embedding_status,
                  metadata
                ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14)
                ",
                params![
                    payload.session_key,
                    payload.session_file,
                    payload.source,
                    chunk.created_at,
                    payload.cwd,
                    payload.git_branch,
                    payload.leaf_id,
                    chunk_index as i64,
                    chunk.content,
                    embedding_blob,
                    embedding_dimensions,
                    embedding_model,
                    embedding_status,
                    metadata_text,
                ],
            )?;
            inserted += 1;
        }

        transaction.commit()?;
        Ok(SaveSummary { inserted, skipped })
    }

    fn initialize_schema(&self) -> Result<(), BackendError> {
        self.connection.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS memories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              session_key TEXT NOT NULL,
              session_file TEXT,
              source TEXT NOT NULL,
              created_at TEXT NOT NULL,
              cwd TEXT,
              git_branch TEXT,
              leaf_id TEXT,
              chunk_index INTEGER NOT NULL,
              content TEXT NOT NULL,
              embedding BLOB,
              embedding_dimensions INTEGER,
              embedding_model TEXT,
              embedding_status TEXT NOT NULL DEFAULT 'pending',
              metadata TEXT
            );

            CREATE INDEX IF NOT EXISTS idx_memories_session_key ON memories(session_key);
            CREATE INDEX IF NOT EXISTS idx_memories_created_at ON memories(created_at);
            CREATE INDEX IF NOT EXISTS idx_memories_source ON memories(source);
            CREATE UNIQUE INDEX IF NOT EXISTS idx_memories_dedupe
              ON memories(session_key, source, created_at, chunk_index, content);
            ",
        )?;
        Ok(())
    }
}

fn f32_vec_to_blob(values: &[f32]) -> Vec<u8> {
    let mut bytes = Vec::with_capacity(values.len() * std::mem::size_of::<f32>());
    for value in values {
        bytes.extend_from_slice(&value.to_le_bytes());
    }
    bytes
}

fn merge_metadata(payload_metadata: Option<&Value>, chunk_metadata: Option<&Value>) -> Option<Value> {
    match (payload_metadata, chunk_metadata) {
        (None, None) => None,
        (Some(value), None) | (None, Some(value)) => Some(value.clone()),
        (Some(Value::Object(payload)), Some(Value::Object(chunk))) => {
            let mut merged = payload.clone();
            for (key, value) in chunk {
                merged.insert(key.clone(), value.clone());
            }
            Some(Value::Object(merged))
        }
        (Some(_), Some(value)) => Some(value.clone()),
    }
}
