use yneko_core::{PlaybackProgress, YnekoError, YnekoResult};

pub const INITIAL_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS playback_progress (
  subject_id INTEGER NOT NULL,
  episode_id INTEGER NOT NULL,
  position_ms INTEGER NOT NULL,
  duration_ms INTEGER,
  updated_at_ms INTEGER NOT NULL,
  PRIMARY KEY (subject_id, episode_id)
);
"#;

#[derive(Debug, Clone, Default)]
pub struct StorageService;

impl StorageService {
    pub fn new() -> Self {
        Self
    }

    pub async fn save_playback_progress(&self, progress: PlaybackProgress) -> YnekoResult<()> {
        if progress.subject_id <= 0 || progress.episode_id <= 0 {
            return Err(YnekoError::InvalidInput(
                "subject_id and episode_id must be positive".to_string(),
            ));
        }
        Err(YnekoError::NotImplemented(
            "SQLite playback progress repository".to_string(),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn schema_contains_progress_table() {
        assert!(INITIAL_SCHEMA.contains("playback_progress"));
    }
}
