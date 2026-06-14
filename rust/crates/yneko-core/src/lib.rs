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
    #[error("metadata is unavailable: {0}")]
    MetadataUnavailable(String),
    #[error("source package rejected: {0}")]
    SourceRejected(String),
    #[error("storage operation failed: {0}")]
    Storage(String),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SubjectSummary {
    pub id: i64,
    pub name: String,
    pub name_cn: Option<String>,
    #[serde(default)]
    pub aliases: Vec<String>,
    pub cover_url: Option<String>,
    pub summary: Option<String>,
    #[serde(default)]
    pub air_date: Option<String>,
    #[serde(default)]
    pub rating_score: Option<f32>,
    #[serde(default)]
    pub rating_rank: Option<u32>,
    #[serde(default)]
    pub tags: Vec<String>,
    #[serde(default)]
    pub total_episodes: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Episode {
    pub id: i64,
    pub subject_id: i64,
    pub sort: i32,
    pub title: String,
    pub title_cn: Option<String>,
    #[serde(default)]
    pub air_date: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SubjectDetail {
    pub subject: SubjectSummary,
    pub episodes: Vec<Episode>,
    pub is_favorite: bool,
    pub progress: Option<PlaybackProgress>,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BangumiBrowseSort {
    #[default]
    Rank,
    Date,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BangumiBrowseRequest {
    #[serde(default)]
    pub sort: BangumiBrowseSort,
    #[serde(default)]
    pub year: Option<u16>,
    #[serde(default)]
    pub month: Option<u8>,
    #[serde(default)]
    pub limit: Option<u16>,
    #[serde(default)]
    pub offset: Option<u32>,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AnimeRankingSort {
    Rank,
    #[default]
    Heat,
    Collect,
    Date,
    Name,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AnimeSeason {
    Winter,
    Spring,
    Summer,
    Autumn,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AnimeRankingRequest {
    #[serde(default)]
    pub sort: AnimeRankingSort,
    #[serde(default)]
    pub filters: std::collections::HashMap<String, String>,
    #[serde(default)]
    pub filter_group: Option<String>,
    #[serde(default)]
    pub filter: Option<String>,
    #[serde(default)]
    pub year: Option<u16>,
    #[serde(default)]
    pub season: Option<AnimeSeason>,
    #[serde(default)]
    pub keyword: String,
    #[serde(default = "default_anime_ranking_page")]
    pub page: u32,
    #[serde(default = "default_anime_ranking_limit")]
    pub limit: u8,
}

impl Default for AnimeRankingRequest {
    fn default() -> Self {
        Self {
            sort: AnimeRankingSort::Heat,
            filters: std::collections::HashMap::new(),
            filter_group: None,
            filter: None,
            year: None,
            season: None,
            keyword: String::new(),
            page: default_anime_ranking_page(),
            limit: default_anime_ranking_limit(),
        }
    }
}

fn default_anime_ranking_limit() -> u8 {
    24
}

fn default_anime_ranking_page() -> u32 {
    1
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AnimeRankingApplied {
    pub sort: String,
    #[serde(default)]
    pub filters: std::collections::HashMap<String, String>,
    #[serde(default)]
    pub filter_group: Option<String>,
    #[serde(default)]
    pub filter: Option<String>,
    #[serde(default)]
    pub year: Option<u16>,
    #[serde(default)]
    pub season: Option<String>,
    #[serde(default)]
    pub keyword: Option<String>,
    pub page: u32,
    pub limit: u8,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AnimeRankingResponse {
    pub items: Vec<SubjectSummary>,
    pub page: u32,
    pub has_next: bool,
    pub applied: AnimeRankingApplied,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BangumiCalendarDay {
    pub weekday_id: u8,
    pub weekday_cn: String,
    pub weekday_en: String,
    pub items: Vec<SubjectSummary>,
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
pub struct SourcePackageRecord {
    pub id: String,
    pub name: String,
    pub version: String,
    pub enabled: bool,
    pub format: String,
    pub source_url: Option<String>,
    pub diagnostics: Vec<String>,
    pub imported_at_ms: i64,
    pub updated_at_ms: i64,
    pub raw_text: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourcePackageSummary {
    pub id: String,
    pub name: String,
    pub version: String,
    pub enabled: bool,
    pub format: String,
    pub source_url: Option<String>,
    pub diagnostics: Vec<String>,
    pub imported_at_ms: i64,
    pub updated_at_ms: i64,
}

impl From<&SourcePackageRecord> for SourcePackageSummary {
    fn from(value: &SourcePackageRecord) -> Self {
        Self {
            id: value.id.clone(),
            name: value.name.clone(),
            version: value.version.clone(),
            enabled: value.enabled,
            format: value.format.clone(),
            source_url: value.source_url.clone(),
            diagnostics: value.diagnostics.clone(),
            imported_at_ms: value.imported_at_ms,
            updated_at_ms: value.updated_at_ms,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceImportResult {
    pub package: SourcePackageSummary,
    pub diagnostics: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourcePackageText {
    pub id: String,
    pub name: String,
    pub format: String,
    pub body: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuleGroupSummary {
    pub id: String,
    pub name: String,
    pub enabled: bool,
    pub rule_ids: Vec<String>,
    pub disabled_rule_ids: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuleRepositorySubscription {
    pub id: String,
    pub name: String,
    pub url: String,
    pub enabled: bool,
    pub updated_at_ms: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuleRepositoryIndexEntry {
    pub name: String,
    pub version: String,
    pub last_update_ms: Option<i64>,
    pub anti_crawler_enabled: bool,
    pub raw_url: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SourceCandidate {
    pub rule_id: String,
    pub rule_name: String,
    pub source_item_key: String,
    pub title: String,
    pub detail_url: String,
    pub search_url: Option<String>,
    pub confidence: String,
    pub score: Option<f32>,
    pub matched_keyword: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RuleSourceSearchResult {
    pub rule_id: String,
    pub rule_name: String,
    pub status: String,
    pub elapsed_ms: i64,
    pub candidates: Vec<SourceCandidate>,
    pub raw_candidates: Vec<SourceCandidate>,
    pub selected_keyword: Option<String>,
    pub selected_title: Option<String>,
    pub selected_score: Option<f32>,
    pub keyword_traces: Vec<String>,
    pub error: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SubjectSourceBinding {
    pub subject_id: i64,
    pub rule_id: String,
    pub source_item_key: String,
    pub source_title: String,
    pub detail_url: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EpisodeSourceBinding {
    pub subject_id: i64,
    pub episode_id: i64,
    pub episode_order: i32,
    pub rule_id: String,
    pub source_episode_key: String,
    pub title: String,
    pub play_url: String,
    pub fallback_play_urls: Vec<String>,
    pub referer_url: Option<String>,
    pub confidence: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuleResolveAttempt {
    pub rule_id: String,
    pub status: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EpisodeBindingResolveResult {
    pub bindings: Vec<EpisodeSourceBinding>,
    pub selected_candidate: Option<SourceCandidate>,
    pub selected_binding: Option<EpisodeSourceBinding>,
    pub attempts: Vec<RuleResolveAttempt>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlayStream {
    pub id: String,
    pub rule_id: String,
    pub kind: String,
    pub url: String,
    pub referer_url: Option<String>,
    pub user_agent: Option<String>,
    pub headers: Vec<PlaybackHeader>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EpisodeStreamResolveResult {
    pub streams: Vec<PlayStream>,
    pub attempts: Vec<RuleResolveAttempt>,
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

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
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
