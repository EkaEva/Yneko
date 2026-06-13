use serde::{Deserialize, Serialize};
use thiserror::Error;

pub type YnekoResult<T> = Result<T, YnekoError>;

#[derive(Debug, Error, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", content = "detail")]
pub enum YnekoError {
    #[error("feature is not implemented yet: {0}")]
    NotImplemented(String),
    #[error("invalid input: {0}")]
    InvalidInput(String),
    #[error("network request failed: {0}")]
    Network(String),
    #[error("source package rejected: {0}")]
    SourceRejected(String),
    #[error("storage operation failed: {0}")]
    Storage(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SubjectSummary {
    pub id: i64,
    pub name: String,
    pub name_cn: Option<String>,
    pub cover_url: Option<String>,
    pub summary: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Episode {
    pub id: i64,
    pub sort: i32,
    pub title: String,
    pub title_cn: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SubjectDetail {
    pub subject: SubjectSummary,
    pub episodes: Vec<Episode>,
    pub is_favorite: bool,
    pub progress: Option<PlaybackProgress>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceRepository {
    pub id: String,
    pub name: String,
    pub url: String,
    pub package_count: usize,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourcePackage {
    pub id: String,
    pub repository_id: Option<String>,
    pub name: String,
    pub version: String,
    pub enabled: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlaybackCandidate {
    pub id: String,
    pub subject_id: i64,
    pub episode_id: i64,
    pub source_package_id: String,
    pub title: String,
    pub url: String,
    pub headers: Vec<PlaybackHeader>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlaybackHeader {
    pub name: String,
    pub value: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlaybackProgress {
    pub subject_id: i64,
    pub episode_id: i64,
    pub position_ms: i64,
    pub duration_ms: Option<i64>,
    pub updated_at_ms: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WatchHistoryItem {
    pub subject: SubjectSummary,
    pub episode: Episode,
    pub progress: PlaybackProgress,
}

pub fn clean_query(query: &str) -> YnekoResult<String> {
    let clean = query.trim();
    if clean.is_empty() {
        return Err(YnekoError::InvalidInput(
            "query must not be empty".to_string(),
        ));
    }
    Ok(clean.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn clean_query_rejects_empty_text() {
        assert!(matches!(
            clean_query("  "),
            Err(YnekoError::InvalidInput(_))
        ));
    }

    #[test]
    fn clean_query_trims_text() {
        assert_eq!(clean_query("  yneko  ").expect("query"), "yneko");
    }
}
