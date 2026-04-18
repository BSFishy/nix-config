use std::{env, path::PathBuf};

#[derive(Debug, Clone)]
pub struct Config {
    pub database_path: PathBuf,
    pub model_path: Option<PathBuf>,
    pub tokenizer_path: Option<PathBuf>,
    pub model_name: String,
    pub ort_dylib_path: Option<PathBuf>,
    pub max_tokens: usize,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            database_path: env_path("PI_MEMORY_DB_PATH").unwrap_or_else(default_database_path),
            model_path: env_path("PI_MEMORY_MODEL_PATH"),
            tokenizer_path: env_path("PI_MEMORY_TOKENIZER_PATH"),
            model_name: env::var("PI_MEMORY_MODEL_NAME")
                .ok()
                .filter(|value| !value.trim().is_empty())
                .unwrap_or_else(|| "sentence-transformers/all-MiniLM-L6-v2".to_string()),
            ort_dylib_path: env_path("PI_MEMORY_ORT_DYLIB_PATH"),
            max_tokens: env::var("PI_MEMORY_MAX_TOKENS")
                .ok()
                .and_then(|value| value.parse::<usize>().ok())
                .filter(|value| *value > 0)
                .unwrap_or(256),
        }
    }
}

fn env_path(key: &str) -> Option<PathBuf> {
    env::var_os(key)
        .filter(|value| !value.is_empty())
        .map(PathBuf::from)
}

fn default_database_path() -> PathBuf {
    let home = env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("."));

    home.join(".pi").join("agent").join("memory.db")
}
