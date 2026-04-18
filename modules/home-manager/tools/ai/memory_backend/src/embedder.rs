use std::path::{Path, PathBuf};

use ndarray::Array2;
use ort::{session::Session, value::TensorRef};
use tokenizers::Tokenizer;

use crate::error::BackendError;

pub struct Embedder {
    model_name: String,
    session: Option<Session>,
    tokenizer: Option<Tokenizer>,
    max_tokens: usize,
}

impl Embedder {
    pub fn initialize(
        model_name: String,
        model_path: Option<PathBuf>,
        tokenizer_path: Option<PathBuf>,
        ort_dylib_path: Option<PathBuf>,
        max_tokens: usize,
    ) -> Result<Self, BackendError> {
        if let Some(dylib_path) = ort_dylib_path {
            let committed = ort::init_from(dylib_path)
                .map_err(|error| BackendError::Ort(error.to_string()))?
                .with_name("pi-memory-backend")
                .commit();

            if !committed {
                return Err(BackendError::Ort(
                    "failed to initialize ONNX Runtime environment from configured dynamic library"
                        .to_string(),
                ));
            }
        }

        let session = if let Some(model_path) = model_path.as_ref() {
            Some(load_session(model_path)?)
        } else {
            None
        };

        let tokenizer = if let Some(tokenizer_path) = tokenizer_path.as_ref() {
            Some(load_tokenizer(tokenizer_path)?)
        } else {
            None
        };

        Ok(Self {
            model_name,
            session,
            tokenizer,
            max_tokens,
        })
    }

    pub fn model_name(&self) -> Option<&str> {
        if self.is_ready() {
            Some(self.model_name.as_str())
        } else {
            None
        }
    }

    pub fn is_ready(&self) -> bool {
        self.session.is_some() && self.tokenizer.is_some()
    }

    pub fn embed(&mut self, text: &str) -> Result<Option<Vec<f32>>, BackendError> {
        let (session, tokenizer) = match (&mut self.session, &self.tokenizer) {
            (Some(session), Some(tokenizer)) => (session, tokenizer),
            _ => return Ok(None),
        };

        let encoding = tokenizer
            .encode(text, true)
            .map_err(|error| BackendError::Tokenizer(error.to_string()))?;

        let input_ids = truncate_i64(encoding.get_ids(), self.max_tokens);
        let attention_mask = truncate_i64(encoding.get_attention_mask(), self.max_tokens);
        let token_type_ids = truncate_i64(encoding.get_type_ids(), self.max_tokens);

        let seq_len = input_ids.len();
        if seq_len == 0 {
            return Ok(Some(Vec::new()));
        }

        let input_ids = Array2::from_shape_vec((1, seq_len), input_ids)
            .map_err(|error| BackendError::Embedding(error.to_string()))?;
        let attention_mask = Array2::from_shape_vec((1, seq_len), attention_mask)
            .map_err(|error| BackendError::Embedding(error.to_string()))?;
        let token_type_ids = Array2::from_shape_vec((1, seq_len), token_type_ids)
            .map_err(|error| BackendError::Embedding(error.to_string()))?;

        let outputs = if has_input(session, "token_type_ids") {
            session
                .run(ort::inputs! {
                    "input_ids" => TensorRef::from_array_view(&input_ids).map_err(|error| BackendError::Ort(error.to_string()))?,
                    "attention_mask" => TensorRef::from_array_view(&attention_mask).map_err(|error| BackendError::Ort(error.to_string()))?,
                    "token_type_ids" => TensorRef::from_array_view(&token_type_ids).map_err(|error| BackendError::Ort(error.to_string()))?,
                })
                .map_err(|error| BackendError::Ort(error.to_string()))?
        } else {
            session
                .run(ort::inputs! {
                    "input_ids" => TensorRef::from_array_view(&input_ids).map_err(|error| BackendError::Ort(error.to_string()))?,
                    "attention_mask" => TensorRef::from_array_view(&attention_mask).map_err(|error| BackendError::Ort(error.to_string()))?,
                })
                .map_err(|error| BackendError::Ort(error.to_string()))?
        };

        let output = &outputs[0];
        let (shape, values) = output
            .try_extract_tensor::<f32>()
            .map_err(|error| BackendError::Ort(error.to_string()))?;

        let embedding = mean_pool(shape, values, attention_mask.as_slice().unwrap_or(&[]))?;
        Ok(Some(embedding))
    }
}

fn load_session(model_path: &Path) -> Result<Session, BackendError> {
    let mut session_builder = Session::builder().map_err(|error| BackendError::Ort(error.to_string()))?;
    session_builder = session_builder
        .with_intra_threads(1)
        .map_err(|error| BackendError::Ort(error.to_string()))?;

    session_builder
        .commit_from_file(model_path)
        .map_err(|error| BackendError::Ort(error.to_string()))
}

fn load_tokenizer(tokenizer_path: &Path) -> Result<Tokenizer, BackendError> {
    Tokenizer::from_file(tokenizer_path).map_err(|error| BackendError::Tokenizer(error.to_string()))
}

fn truncate_i64(values: &[u32], max_tokens: usize) -> Vec<i64> {
    values
        .iter()
        .take(max_tokens)
        .map(|value| i64::from(*value))
        .collect()
}

fn has_input(session: &Session, name: &str) -> bool {
    session.inputs().iter().any(|input| input.name() == name)
}

fn mean_pool(shape: &[i64], values: &[f32], attention_mask: &[i64]) -> Result<Vec<f32>, BackendError> {
    if shape.len() != 3 {
        return Err(BackendError::Embedding(format!(
            "expected embedding output rank 3, got shape {shape:?}"
        )));
    }

    let batch = shape[0] as usize;
    let seq_len = shape[1] as usize;
    let hidden = shape[2] as usize;

    if batch != 1 {
        return Err(BackendError::Embedding(format!(
            "expected batch size 1, got {batch}"
        )));
    }

    if values.len() != batch * seq_len * hidden {
        return Err(BackendError::Embedding("embedding output size did not match shape".to_string()));
    }

    if attention_mask.len() < seq_len {
        return Err(BackendError::Embedding(
            "attention mask shorter than sequence length".to_string(),
        ));
    }

    let mut pooled = vec![0.0_f32; hidden];
    let mut token_count = 0.0_f32;

    for token_index in 0..seq_len {
        if attention_mask[token_index] == 0 {
            continue;
        }

        token_count += 1.0;
        let offset = token_index * hidden;
        for hidden_index in 0..hidden {
            pooled[hidden_index] += values[offset + hidden_index];
        }
    }

    if token_count == 0.0 {
        return Ok(pooled);
    }

    for value in &mut pooled {
        *value /= token_count;
    }

    Ok(l2_normalize(pooled))
}

fn l2_normalize(mut values: Vec<f32>) -> Vec<f32> {
    let norm = values.iter().map(|value| value * value).sum::<f32>().sqrt();
    if norm == 0.0 {
        return values;
    }

    for value in &mut values {
        *value /= norm;
    }
    values
}
