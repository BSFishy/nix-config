mod config;
mod db;
mod embedder;
mod error;

use std::io::{self, BufRead, Write};

use config::Config;
use db::{Database, SaveSummary, Stats};
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
    by_source: std::collections::BTreeMap<String, u64>,
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
#[serde(untagged)]
enum SuccessResult {
    Health(HealthResult),
    Stats(StatsResult),
    Save(SaveResult),
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
