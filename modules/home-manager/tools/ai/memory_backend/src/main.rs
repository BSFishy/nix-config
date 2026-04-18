mod config;
mod db;
mod embedder;
mod error;

use std::{collections::BTreeMap, io::{self, BufRead, Write}};

use config::Config;
use db::{Database, SaveSummary, SearchHit, Stats};
use embedder::Embedder;
use error::BackendError;
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
enum Request {
    #[serde(rename = "health")]
    Health { id: String },
    #[serde(rename = "stats")]
    Stats { id: String },
    #[serde(rename = "save")]
    Save { id: String, payload: SavePayload },
    #[serde(rename = "search")]
    Search { id: String, payload: SearchPayload },
}

#[derive(Debug, Deserialize)]
struct SavePayload {
    source: String,
    #[serde(rename = "sessionKey")]
    session_key: String,
    #[serde(rename = "sessionFile")]
    session_file: Option<String>,
    cwd: Option<String>,
    #[serde(rename = "gitBranch")]
    git_branch: Option<String>,
    #[serde(rename = "leafId")]
    leaf_id: Option<String>,
    chunks: Vec<MemoryChunk>,
    metadata: Option<Value>,
}

#[derive(Debug, Deserialize)]
struct SearchPayload {
    query: String,
    #[serde(rename = "topK")]
    top_k: Option<usize>,
    threshold: Option<f32>,
    cwd: Option<String>,
}

#[derive(Debug, Deserialize)]
struct MemoryChunk {
    content: String,
    #[serde(rename = "createdAt")]
    created_at: String,
    metadata: Option<Value>,
}

#[derive(Debug, Serialize)]
struct StatsResult {
    #[serde(rename = "totalMemories")]
    total_memories: u64,
    #[serde(rename = "bySource")]
    by_source: BTreeMap<String, u64>,
    #[serde(rename = "databasePath")]
    database_path: String,
}

#[derive(Debug, Serialize)]
struct SaveResult {
    inserted: u64,
    skipped: u64,
}

#[derive(Debug, Serialize)]
struct HealthResult {
    ok: bool,
}

#[derive(Debug, Serialize)]
struct SearchResult {
    hits: Vec<SearchHitResult>,
}

#[derive(Debug, Serialize)]
struct SearchHitResult {
    id: i64,
    source: String,
    #[serde(rename = "createdAt")]
    created_at: String,
    #[serde(rename = "sessionKey")]
    session_key: String,
    #[serde(rename = "sessionFile")]
    session_file: Option<String>,
    cwd: Option<String>,
    #[serde(rename = "gitBranch")]
    git_branch: Option<String>,
    #[serde(rename = "leafId")]
    leaf_id: Option<String>,
    content: String,
    metadata: Option<Value>,
    score: f32,
}

#[derive(Debug, Serialize)]
#[serde(untagged)]
enum SuccessResult {
    Health(HealthResult),
    Stats(StatsResult),
    Save(SaveResult),
    Search(SearchResult),
}

#[derive(Debug, Serialize)]
#[serde(tag = "ok")]
enum Response {
    #[serde(rename = "true")]
    Success { id: String, result: SuccessResult },
    #[serde(rename = "false")]
    Error { id: String, error: String },
}

struct BackendState {
    database: Database,
    embedder: Embedder,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_env();
    let mut backend = BackendState::initialize(config)?;

    let stdin = io::stdin();
    let mut stdout = io::stdout().lock();

    for line_result in stdin.lock().lines() {
        let line = line_result?;
        if line.trim().is_empty() {
            continue;
        }

        let response = match serde_json::from_str::<Request>(&line) {
            Ok(request) => backend.handle_request(request),
            Err(error) => Response::Error {
                id: "unknown".to_string(),
                error: format!("invalid request: {error}"),
            },
        };

        serde_json::to_writer(&mut stdout, &response)?;
        stdout.write_all(b"\n")?;
        stdout.flush()?;
    }

    Ok(())
}

impl BackendState {
    fn initialize(config: Config) -> Result<Self, BackendError> {
        let database = Database::open(&config.database_path)?;
        let embedder = Embedder::initialize(
            config.model_name,
            config.model_path,
            config.tokenizer_path,
            config.ort_dylib_path,
            config.max_tokens,
        )?;
        Ok(Self { database, embedder })
    }

    fn handle_request(&mut self, request: Request) -> Response {
        match request {
            Request::Health { id } => Response::Success {
                id,
                result: SuccessResult::Health(HealthResult { ok: true }),
            },
            Request::Stats { id } => match self.database.stats() {
                Ok(stats) => Response::Success {
                    id,
                    result: SuccessResult::Stats(stats.into()),
                },
                Err(error) => Response::Error {
                    id,
                    error: error.to_string(),
                },
            },
            Request::Save { id, payload } => match self.handle_save(payload) {
                Ok(summary) => Response::Success {
                    id,
                    result: SuccessResult::Save(summary.into()),
                },
                Err(error) => Response::Error {
                    id,
                    error: error.to_string(),
                },
            },
            Request::Search { id, payload } => match self.handle_search(payload) {
                Ok(hits) => Response::Success {
                    id,
                    result: SuccessResult::Search(SearchResult {
                        hits: hits.into_iter().map(Into::into).collect(),
                    }),
                },
                Err(error) => Response::Error {
                    id,
                    error: error.to_string(),
                },
            },
        }
    }

    fn handle_save(&mut self, payload: SavePayload) -> Result<SaveSummary, BackendError> {
        let mut embeddings = Vec::with_capacity(payload.chunks.len());
        for chunk in &payload.chunks {
            embeddings.push(self.embedder.embed(&chunk.content)?);
        }

        self.database
            .save_payload(&payload, self.embedder.model_name(), &embeddings)
    }

    fn handle_search(&mut self, payload: SearchPayload) -> Result<Vec<SearchHit>, BackendError> {
        let Some(query_embedding) = self.embedder.embed(&payload.query)? else {
            return Ok(Vec::new());
        };

        let top_k = payload.top_k.unwrap_or(5).max(1);
        self.database
            .search(&query_embedding, top_k, payload.threshold, payload.cwd.as_deref())
    }
}

impl From<Stats> for StatsResult {
    fn from(value: Stats) -> Self {
        Self {
            total_memories: value.total_memories,
            by_source: value.by_source,
            database_path: value.database_path,
        }
    }
}

impl From<SaveSummary> for SaveResult {
    fn from(value: SaveSummary) -> Self {
        Self {
            inserted: value.inserted,
            skipped: value.skipped,
        }
    }
}

impl From<SearchHit> for SearchHitResult {
    fn from(value: SearchHit) -> Self {
        Self {
            id: value.id,
            source: value.source,
            created_at: value.created_at,
            session_key: value.session_key,
            session_file: value.session_file,
            cwd: value.cwd,
            git_branch: value.git_branch,
            leaf_id: value.leaf_id,
            content: value.content,
            metadata: value.metadata,
            score: value.score,
        }
    }
}
