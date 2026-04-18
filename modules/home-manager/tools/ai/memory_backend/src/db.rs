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

#[derive(Debug, Clone)]
pub struct SearchHit {
    pub id: i64,
    pub source: String,
    pub created_at: String,
    pub session_key: String,
    pub session_file: Option<String>,
    pub cwd: Option<String>,
    pub git_branch: Option<String>,
    pub leaf_id: Option<String>,
    pub content: String,
    pub metadata: Option<Value>,
    pub score: f32,
}

struct CandidateMemory {
    id: i64,
    source: String,
    created_at: String,
    session_key: String,
    session_file: Option<String>,
    cwd: Option<String>,
    git_branch: Option<String>,
    leaf_id: Option<String>,
    content: String,
    metadata: Option<Value>,
    embedding: Vec<f32>,
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

    pub fn search(
        &self,
        query_embedding: &[f32],
        top_k: usize,
        threshold: Option<f32>,
        cwd: Option<&str>,
    ) -> Result<Vec<SearchHit>, BackendError> {
        if query_embedding.is_empty() || top_k == 0 {
            return Ok(Vec::new());
        }

        let candidates = self.load_candidates(cwd)?;
        let mut hits = candidates
            .into_iter()
            .filter_map(|candidate| {
                let score = cosine_similarity(query_embedding, &candidate.embedding)?;
                if let Some(threshold) = threshold {
                    if score < threshold {
                        return None;
                    }
                }

                Some(SearchHit {
                    id: candidate.id,
                    source: candidate.source,
                    created_at: candidate.created_at,
                    session_key: candidate.session_key,
                    session_file: candidate.session_file,
                    cwd: candidate.cwd,
                    git_branch: candidate.git_branch,
                    leaf_id: candidate.leaf_id,
                    content: candidate.content,
                    metadata: candidate.metadata,
                    score,
                })
            })
            .collect::<Vec<_>>();

        hits.sort_by(|left, right| right.score.total_cmp(&left.score));
        if hits.len() > top_k {
            hits.truncate(top_k);
        }

        Ok(hits)
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

    fn load_candidates(&self, cwd: Option<&str>) -> Result<Vec<CandidateMemory>, BackendError> {
        let sql = if cwd.is_some() {
            "
            SELECT id, source, created_at, session_key, session_file, cwd, git_branch, leaf_id, content, metadata, embedding
            FROM memories
            WHERE embedding_status = 'ready'
              AND embedding IS NOT NULL
              AND cwd = ?1
            "
        } else {
            "
            SELECT id, source, created_at, session_key, session_file, cwd, git_branch, leaf_id, content, metadata, embedding
            FROM memories
            WHERE embedding_status = 'ready'
              AND embedding IS NOT NULL
            "
        };

        let mut statement = self.connection.prepare(sql)?;
        let rows = if let Some(cwd) = cwd {
            statement.query_map([cwd], row_to_candidate)?
        } else {
            statement.query_map([], row_to_candidate)?
        };

        let mut candidates = Vec::new();
        for row in rows {
            candidates.push(row?);
        }
        Ok(candidates)
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
            CREATE INDEX IF NOT EXISTS idx_memories_cwd ON memories(cwd);
            CREATE INDEX IF NOT EXISTS idx_memories_embedding_status ON memories(embedding_status);
            CREATE UNIQUE INDEX IF NOT EXISTS idx_memories_dedupe
              ON memories(session_key, source, created_at, chunk_index, content);
            ",
        )?;
        Ok(())
    }
}

fn row_to_candidate(row: &rusqlite::Row<'_>) -> Result<CandidateMemory, rusqlite::Error> {
    let metadata_text = row.get::<_, Option<String>>(9)?;
    let metadata = metadata_text
        .as_deref()
        .map(serde_json::from_str::<Value>)
        .transpose()
        .map_err(|error| rusqlite::Error::FromSqlConversionFailure(9, rusqlite::types::Type::Text, Box::new(error)))?;

    let embedding_blob = row.get::<_, Vec<u8>>(10)?;
    let embedding = blob_to_f32_vec(&embedding_blob)
        .map_err(|error| rusqlite::Error::FromSqlConversionFailure(10, rusqlite::types::Type::Blob, Box::new(error)))?;

    Ok(CandidateMemory {
        id: row.get(0)?,
        source: row.get(1)?,
        created_at: row.get(2)?,
        session_key: row.get(3)?,
        session_file: row.get(4)?,
        cwd: row.get(5)?,
        git_branch: row.get(6)?,
        leaf_id: row.get(7)?,
        content: row.get(8)?,
        metadata,
        embedding,
    })
}

fn cosine_similarity(left: &[f32], right: &[f32]) -> Option<f32> {
    if left.is_empty() || right.is_empty() || left.len() != right.len() {
        return None;
    }

    let mut dot = 0.0_f32;
    let mut left_norm = 0.0_f32;
    let mut right_norm = 0.0_f32;

    for (l, r) in left.iter().zip(right.iter()) {
        dot += l * r;
        left_norm += l * l;
        right_norm += r * r;
    }

    if left_norm == 0.0 || right_norm == 0.0 {
        return None;
    }

    Some(dot / (left_norm.sqrt() * right_norm.sqrt()))
}

fn blob_to_f32_vec(bytes: &[u8]) -> Result<Vec<f32>, BackendError> {
    if bytes.len() % std::mem::size_of::<f32>() != 0 {
        return Err(BackendError::Embedding(
            "embedding blob length was not a multiple of 4 bytes".to_string(),
        ));
    }

    let mut values = Vec::with_capacity(bytes.len() / std::mem::size_of::<f32>());
    for chunk in bytes.chunks_exact(std::mem::size_of::<f32>()) {
        values.push(f32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]));
    }
    Ok(values)
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
