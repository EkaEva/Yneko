use std::collections::HashMap;
use std::sync::OnceLock;
use std::time::Instant;

use yneko_core::{
    self, AnimeRankingSort as CoreAnimeRankingSort, AnimeSeason as CoreAnimeSeason,
    BangumiBrowseSort as CoreBangumiBrowseSort, CollectionStatus as CoreCollectionStatus,
    EpisodeBindingResolveResult as CoreEpisodeBindingResolveResult,
    EpisodeSourceBinding as CoreEpisodeSourceBinding,
    EpisodeStreamResolveResult as CoreEpisodeStreamResolveResult, FavoriteItem as CoreFavoriteItem,
    PlayStream as CorePlayStream, PlaybackProgress as CorePlaybackProgress,
    RuleGroupSummary as CoreRuleGroupSummary,
    RuleRepositoryIndexEntry as CoreRuleRepositoryIndexEntry,
    RuleRepositorySubscription as CoreRuleRepositorySubscription,
    RuleResolveAttempt as CoreRuleResolveAttempt,
    RuleSourceSearchResult as CoreRuleSourceSearchResult, SourceCandidate as CoreSourceCandidate,
    SourceImportResult as CoreSourceImportResult, SourcePackageRecord,
    SourcePackageSummary as CoreSourcePackageSummary, SourcePackageText as CoreSourcePackageText,
    SubjectSourceBinding as CoreSubjectSourceBinding, WatchHistoryItem as CoreWatchHistoryItem,
    YnekoError,
};
use yneko_source_rules::{
    PlaybackResolveContext, RuleEpisodeContext, RulePackageRecord, RuleSearchContext,
    RuleStreamContext,
};
use yneko_storage::StorageService;

#[derive(Debug, Clone)]
pub struct AppearanceSettings {
    pub theme_mode: String,
    pub color_scheme: String,
}

#[derive(Debug, Clone)]
pub struct SubjectSummary {
    pub id: i64,
    pub name: String,
    pub name_cn: Option<String>,
    pub aliases: Vec<String>,
    pub cover_url: Option<String>,
    pub summary: Option<String>,
    pub air_date: Option<String>,
    pub rating_score: Option<f32>,
    pub rating_rank: Option<u32>,
    pub tags: Vec<String>,
    pub total_episodes: u32,
}

#[derive(Debug, Clone)]
pub struct Episode {
    pub id: i64,
    pub subject_id: i64,
    pub sort: i32,
    pub title: String,
    pub title_cn: Option<String>,
    pub air_date: Option<String>,
}

#[derive(Debug, Clone)]
pub struct SubjectDetail {
    pub subject: SubjectSummary,
    pub episodes: Vec<Episode>,
    pub is_favorite: bool,
    pub progress: Option<PlaybackProgress>,
}

#[derive(Debug, Clone, Copy)]
pub enum CollectionStatus {
    Wish,
    Watching,
    Watched,
    Paused,
    Dropped,
}

#[derive(Debug, Clone)]
pub struct BangumiCalendarDay {
    pub weekday_id: u8,
    pub weekday_cn: String,
    pub weekday_en: String,
    pub items: Vec<SubjectSummary>,
}

#[derive(Debug, Clone, Copy)]
pub enum AnimeRankingSort {
    Rank,
    Heat,
    Collect,
    Date,
    Name,
}

#[derive(Debug, Clone, Copy)]
pub enum AnimeSeason {
    Winter,
    Spring,
    Summer,
    Autumn,
}

#[derive(Debug, Clone)]
pub struct AnimeRankingRequest {
    pub sort: AnimeRankingSort,
    pub filters: HashMap<String, String>,
    pub filter_group: Option<String>,
    pub filter: Option<String>,
    pub year: Option<u16>,
    pub season: Option<AnimeSeason>,
    pub keyword: String,
    pub page: u32,
    pub limit: u8,
}

#[derive(Debug, Clone)]
pub struct AnimeRankingApplied {
    pub sort: String,
    pub filters: HashMap<String, String>,
    pub filter_group: Option<String>,
    pub filter: Option<String>,
    pub year: Option<u16>,
    pub season: Option<String>,
    pub keyword: Option<String>,
    pub page: u32,
    pub limit: u8,
}

#[derive(Debug, Clone)]
pub struct AnimeRankingResponse {
    pub items: Vec<SubjectSummary>,
    pub page: u32,
    pub has_next: bool,
    pub applied: AnimeRankingApplied,
}

#[derive(Debug, Clone, Copy)]
pub enum BangumiBrowseSort {
    Rank,
    Date,
}

#[derive(Debug, Clone)]
pub struct BangumiBrowseRequest {
    pub sort: BangumiBrowseSort,
    pub year: Option<u16>,
    pub month: Option<u8>,
    pub limit: Option<u16>,
    pub offset: Option<u32>,
}

#[derive(Debug, Clone)]
pub struct PlaybackCandidate {
    pub id: String,
    pub subject_id: i64,
    pub episode_id: i64,
    pub source_package_id: String,
    pub title: String,
    pub url: String,
    pub headers: Vec<PlaybackHeader>,
}

#[derive(Debug, Clone)]
pub struct PlaybackHeader {
    pub name: String,
    pub value: String,
}

#[derive(Debug, Clone)]
pub struct PlayStream {
    pub id: String,
    pub rule_id: String,
    pub kind: String,
    pub url: String,
    pub referer_url: Option<String>,
    pub user_agent: Option<String>,
    pub headers: Vec<PlaybackHeader>,
}

#[derive(Debug, Clone)]
pub struct PlaybackProgress {
    pub subject_id: i64,
    pub episode_id: i64,
    pub position_ms: i64,
    pub duration_ms: Option<i64>,
    pub updated_at_ms: i64,
}

#[derive(Debug, Clone)]
pub struct FavoriteItem {
    pub subject: SubjectSummary,
    pub status: CollectionStatus,
    pub updated_at_ms: i64,
}

#[derive(Debug, Clone)]
pub struct WatchHistoryItem {
    pub subject: SubjectSummary,
    pub episode: Episode,
    pub progress: PlaybackProgress,
}

#[derive(Debug, Clone)]
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

#[derive(Debug, Clone)]
pub struct SourceImportResult {
    pub package: SourcePackageSummary,
    pub diagnostics: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct SourcePackageText {
    pub id: String,
    pub name: String,
    pub format: String,
    pub body: String,
}

#[derive(Debug, Clone)]
pub struct RuleGroupSummary {
    pub id: String,
    pub name: String,
    pub enabled: bool,
    pub rule_ids: Vec<String>,
    pub disabled_rule_ids: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct RuleRepositorySubscription {
    pub id: String,
    pub name: String,
    pub url: String,
    pub enabled: bool,
    pub updated_at_ms: i64,
}

#[derive(Debug, Clone)]
pub struct RuleRepositoryIndexEntry {
    pub name: String,
    pub version: String,
    pub last_update_ms: Option<i64>,
    pub anti_crawler_enabled: bool,
    pub raw_url: String,
}

#[derive(Debug, Clone)]
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

#[derive(Debug, Clone)]
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

#[derive(Debug, Clone)]
pub struct SubjectSourceBinding {
    pub subject_id: i64,
    pub rule_id: String,
    pub source_item_key: String,
    pub source_title: String,
    pub detail_url: String,
}

#[derive(Debug, Clone)]
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

#[derive(Debug, Clone)]
pub struct RuleResolveAttempt {
    pub rule_id: String,
    pub status: String,
    pub message: String,
}

#[derive(Debug, Clone)]
pub struct EpisodeBindingResolveResult {
    pub bindings: Vec<EpisodeSourceBinding>,
    pub selected_candidate: Option<SourceCandidate>,
    pub selected_binding: Option<EpisodeSourceBinding>,
    pub attempts: Vec<RuleResolveAttempt>,
}

#[derive(Debug, Clone)]
pub struct EpisodeStreamResolveResult {
    pub streams: Vec<PlayStream>,
    pub attempts: Vec<RuleResolveAttempt>,
}

pub async fn search_subjects(query: String, page: u32) -> Result<Vec<SubjectSummary>, String> {
    yneko_metadata::BangumiClient::default()
        .search_subjects(&query, page)
        .await
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn get_subject_detail(subject_id: i64) -> Result<SubjectDetail, String> {
    let detail = yneko_metadata::BangumiClient::default()
        .get_subject_detail(subject_id)
        .await
        .map_err(error_message)?;
    let storage = storage_service().await.map_err(error_message)?;
    let is_favorite = storage
        .is_favorite(subject_id)
        .await
        .map_err(error_message)?;
    let progress = storage
        .latest_playback_progress_for_subject(subject_id)
        .await
        .map_err(error_message)?;
    Ok(SubjectDetail {
        subject: detail.subject.into(),
        episodes: detail.episodes.into_iter().map(Into::into).collect(),
        is_favorite,
        progress: progress.map(Into::into),
    })
}

pub async fn get_calendar() -> Result<Vec<BangumiCalendarDay>, String> {
    yneko_metadata::BangumiClient::default()
        .get_calendar()
        .await
        .map(|days| days.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn get_anime_ranking(
    request: AnimeRankingRequest,
) -> Result<AnimeRankingResponse, String> {
    yneko_metadata::BangumiClient::default()
        .get_anime_ranking(request.into())
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn browse_subjects(request: BangumiBrowseRequest) -> Result<Vec<SubjectSummary>, String> {
    yneko_metadata::BangumiClient::default()
        .browse_subjects(request.into())
        .await
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn get_appearance_settings() -> Result<AppearanceSettings, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .get_appearance_settings()
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn save_appearance_settings(
    settings: AppearanceSettings,
) -> Result<AppearanceSettings, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .save_appearance_settings(settings.into())
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn resolve_playback(
    subject_id: i64,
    episode_id: i64,
) -> Result<Vec<PlaybackCandidate>, String> {
    if subject_id <= 0 || episode_id <= 0 {
        return Err("invalid input: subject_id and episode_id must be positive".to_string());
    }
    let detail = yneko_metadata::BangumiClient::default()
        .get_subject_detail(subject_id)
        .await
        .map_err(error_message)?;
    let Some(episode) = detail.episodes.iter().find(|item| item.id == episode_id) else {
        return Ok(Vec::new());
    };
    let context = PlaybackResolveContext {
        subject_id,
        episode_id,
        episode_order: episode.sort,
        title: detail
            .subject
            .name_cn
            .clone()
            .unwrap_or_else(|| detail.subject.name.clone()),
        episode_title: episode
            .title_cn
            .clone()
            .unwrap_or_else(|| episode.title.clone()),
    };
    let storage = storage_service().await.map_err(error_message)?;
    let packages = storage
        .list_enabled_source_package_records()
        .await
        .map_err(error_message)?;
    let mut candidates = Vec::new();
    for package in packages {
        let Ok(source) = yneko_source_rules::parse_source_package(&package.raw_text) else {
            continue;
        };
        let Ok(resolved) = yneko_source_rules::resolve_playback_candidates(&source, &context)
        else {
            continue;
        };
        candidates.extend(resolved.into_iter().map(Into::into));
    }
    Ok(candidates)
}

pub async fn import_source_text(text: String) -> Result<SourceImportResult, String> {
    import_source_text_with_url(text, None)
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn import_source_url(url: String) -> Result<SourceImportResult, String> {
    let trimmed = url.trim();
    if !(trimmed.starts_with("http://") || trimmed.starts_with("https://")) {
        return Err("invalid input: source URL must start with http:// or https://".to_string());
    }
    let text = reqwest::Client::new()
        .get(trimmed)
        .send()
        .await
        .map_err(|error| YnekoError::Network(error.to_string()))
        .map_err(error_message)?
        .error_for_status()
        .map_err(|error| YnekoError::Network(error.to_string()))
        .map_err(error_message)?
        .text()
        .await
        .map_err(|error| YnekoError::Network(error.to_string()))
        .map_err(error_message)?;
    import_source_text_with_url(text, Some(trimmed.to_string()))
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn list_source_packages() -> Result<Vec<SourcePackageSummary>, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .list_source_packages()
        .await
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn set_source_package_enabled(id: String, enabled: bool) -> Result<(), String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .set_source_package_enabled(&id, enabled)
        .await
        .map_err(error_message)
}

pub async fn delete_source_package(id: String) -> Result<(), String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .delete_source_package(&id)
        .await
        .map_err(error_message)
}

pub async fn get_source_package_text(id: String) -> Result<Option<SourcePackageText>, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .get_source_package_text(&id)
        .await
        .map(|value| value.map(Into::into))
        .map_err(error_message)
}

pub async fn list_rule_groups() -> Result<Vec<RuleGroupSummary>, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .list_rule_groups()
        .await
        .map(|groups| groups.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn save_rule_group(group: RuleGroupSummary) -> Result<RuleGroupSummary, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .upsert_rule_group(group.into())
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn delete_rule_group(id: String) -> Result<(), String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage.delete_rule_group(&id).await.map_err(error_message)
}

pub async fn list_rule_repository_subscriptions() -> Result<Vec<RuleRepositorySubscription>, String>
{
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .list_rule_repository_subscriptions()
        .await
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn save_rule_repository_subscription(
    subscription: RuleRepositorySubscription,
) -> Result<RuleRepositorySubscription, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .upsert_rule_repository_subscription(subscription.into())
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn delete_rule_repository_subscription(id: String) -> Result<(), String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .delete_rule_repository_subscription(&id)
        .await
        .map_err(error_message)
}

pub async fn load_rule_repository_index(
    subscription: RuleRepositorySubscription,
) -> Result<Vec<RuleRepositoryIndexEntry>, String> {
    let index_url = yneko_source_rules::repository_index_url(&subscription.url);
    let body = http_get_text(&index_url, Vec::new(), None)
        .await
        .map_err(error_message)?;
    yneko_source_rules::parse_repository_index(&subscription.url, &body)
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn import_repository_rule(
    group_id: String,
    entry: RuleRepositoryIndexEntry,
) -> Result<SourceImportResult, String> {
    let text = http_get_text(&entry.raw_url, Vec::new(), None)
        .await
        .map_err(error_message)?;
    let result = import_source_text_with_url(text, Some(entry.raw_url))
        .await
        .map_err(error_message)?;
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .add_rule_to_group(&group_id, &result.package.id)
        .await
        .map_err(error_message)?;
    Ok(result.into())
}

pub async fn search_rule_source(
    rule_id: String,
    subject_id: i64,
) -> Result<RuleSourceSearchResult, String> {
    let detail = yneko_metadata::BangumiClient::default()
        .get_subject_detail(subject_id)
        .await
        .map_err(error_message)?;
    let storage = storage_service().await.map_err(error_message)?;
    let records = storage
        .list_source_package_records()
        .await
        .map_err(error_message)?;
    let Some(record) = records.into_iter().find(|record| record.id == rule_id) else {
        return Err(format!("source package `{rule_id}` does not exist"));
    };
    search_record(package_record(record), detail.subject, Vec::new())
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn search_rule_sources(
    subject_id: i64,
    rule_ids: Vec<String>,
) -> Result<Vec<RuleSourceSearchResult>, String> {
    let detail = yneko_metadata::BangumiClient::default()
        .get_subject_detail(subject_id)
        .await
        .map_err(error_message)?;
    let storage = storage_service().await.map_err(error_message)?;
    let requested = if rule_ids.is_empty() {
        None
    } else {
        Some(rule_ids)
    };
    let mut records = storage
        .list_source_package_records()
        .await
        .map_err(error_message)?;
    records.retain(|record| record.enabled);
    if let Some(ids) = &requested {
        records.retain(|record| ids.contains(&record.id));
    }
    let subject = detail.subject;
    let mut results = Vec::new();
    for record in records {
        results.push(
            search_record(package_record(record), subject.clone(), Vec::new())
                .await
                .map(Into::into)
                .map_err(error_message)?,
        );
    }
    Ok(results)
}

pub async fn resolve_episode_bindings(
    subject_id: i64,
    episode_id: i64,
    candidate: SourceCandidate,
    fallback_candidates: Vec<SourceCandidate>,
) -> Result<EpisodeBindingResolveResult, String> {
    let detail = yneko_metadata::BangumiClient::default()
        .get_subject_detail(subject_id)
        .await
        .map_err(error_message)?;
    let Some(active_episode_sort) = detail
        .episodes
        .iter()
        .find(|item| item.id == episode_id)
        .map(|episode| episode.sort)
    else {
        return Err("episode does not belong to subject".to_string());
    };
    let storage = storage_service().await.map_err(error_message)?;
    let record = storage
        .list_source_package_records()
        .await
        .map_err(error_message)?
        .into_iter()
        .find(|record| record.id == candidate.rule_id)
        .ok_or_else(|| format!("source package `{}` does not exist", candidate.rule_id))?;
    let result = resolve_bindings_for_record(
        package_record(record),
        detail.subject,
        detail.episodes,
        active_episode_sort,
        candidate.into(),
        fallback_candidates.into_iter().map(Into::into).collect(),
    )
    .await
    .map_err(error_message)?;
    if let Some(selected_candidate) = &result.selected_candidate {
        storage
            .save_subject_source_binding(CoreSubjectSourceBinding {
                subject_id,
                rule_id: selected_candidate.rule_id.clone(),
                source_item_key: selected_candidate.source_item_key.clone(),
                source_title: selected_candidate.title.clone(),
                detail_url: selected_candidate.detail_url.clone(),
            })
            .await
            .map_err(error_message)?;
    }
    storage
        .save_episode_source_bindings(result.bindings.clone())
        .await
        .map_err(error_message)?;
    Ok(result.into())
}

pub async fn resolve_episode_streams(
    rule_id: String,
    play_url: String,
    fallback_play_urls: Vec<String>,
    referer_url: Option<String>,
) -> Result<EpisodeStreamResolveResult, String> {
    let storage = storage_service().await.map_err(error_message)?;
    let record = storage
        .list_source_package_records()
        .await
        .map_err(error_message)?
        .into_iter()
        .find(|record| record.id == rule_id)
        .ok_or_else(|| format!("source package `{rule_id}` does not exist"))?;
    resolve_streams_for_record(
        package_record(record),
        RuleStreamContext {
            rule_id,
            play_url,
            fallback_play_urls,
            referer_url,
        },
    )
    .await
    .map(Into::into)
    .map_err(error_message)
}

pub async fn list_favorites(status: Option<CollectionStatus>) -> Result<Vec<FavoriteItem>, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .list_favorites(status.map(Into::into))
        .await
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn save_favorite(
    subject: SubjectSummary,
    status: CollectionStatus,
) -> Result<FavoriteItem, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .save_favorite(subject.into(), status.into())
        .await
        .map(Into::into)
        .map_err(error_message)
}

pub async fn delete_favorite(subject_id: i64) -> Result<(), String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .delete_favorite(subject_id)
        .await
        .map_err(error_message)
}

pub async fn save_playback_progress(
    subject: SubjectSummary,
    episode: Episode,
    position_ms: i64,
    duration_ms: Option<i64>,
) -> Result<PlaybackProgress, String> {
    if position_ms < 0 {
        return Err("invalid input: position_ms must not be negative".to_string());
    }
    if duration_ms.is_some_and(|value| value < 0) {
        return Err("invalid input: duration_ms must not be negative".to_string());
    }
    if subject.id != episode.subject_id {
        return Err("invalid input: episode must belong to subject".to_string());
    }
    let progress = CorePlaybackProgress {
        subject_id: subject.id,
        episode_id: episode.id,
        position_ms,
        duration_ms,
        updated_at_ms: yneko_storage::now_ms(),
    };
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .save_playback_progress_with_snapshots(
            progress.clone(),
            Some(subject.into()),
            Some(episode.into()),
        )
        .await
        .map_err(error_message)?;
    Ok(progress.into())
}

pub async fn get_playback_progress(
    subject_id: i64,
    episode_id: i64,
) -> Result<Option<PlaybackProgress>, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .get_playback_progress(subject_id, episode_id)
        .await
        .map(|value| value.map(Into::into))
        .map_err(error_message)
}

pub async fn list_watch_history(limit: Option<u32>) -> Result<Vec<WatchHistoryItem>, String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .list_watch_history(limit)
        .await
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn delete_watch_history_item(subject_id: i64, episode_id: i64) -> Result<(), String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage
        .delete_watch_history_item(subject_id, episode_id)
        .await
        .map_err(error_message)
}

pub async fn clear_watch_history() -> Result<(), String> {
    let storage = storage_service().await.map_err(error_message)?;
    storage.clear_watch_history().await.map_err(error_message)
}

fn error_message(error: YnekoError) -> String {
    error.to_string()
}

async fn import_source_text_with_url(
    text: String,
    source_url: Option<String>,
) -> Result<CoreSourceImportResult, YnekoError> {
    let package = yneko_source_rules::parse_source_package(&text)?;
    let diagnostics = yneko_source_rules::package_diagnostics(&package);
    let now = yneko_storage::now_ms();
    let record = SourcePackageRecord {
        id: package.id,
        name: package.name,
        version: package.version,
        enabled: true,
        format: yneko_source_rules::detect_rule_format(&text),
        source_url,
        diagnostics: diagnostics.clone(),
        imported_at_ms: now,
        updated_at_ms: now,
        raw_text: text,
    };
    let storage = storage_service().await?;
    let summary = storage.upsert_source_package(record).await?;
    Ok(CoreSourceImportResult {
        package: summary,
        diagnostics,
    })
}

async fn search_record(
    record: RulePackageRecord,
    subject: yneko_core::SubjectSummary,
    related_titles: Vec<String>,
) -> Result<CoreRuleSourceSearchResult, YnekoError> {
    let package = yneko_source_rules::parse_source_package(&record.raw_text)?;
    let start = Instant::now();
    let request = match yneko_source_rules::plan_search_request(
        package.clone(),
        &RuleSearchContext {
            subject,
            related_titles,
        },
    ) {
        Ok(request) => request,
        Err(error) => {
            return Ok(CoreRuleSourceSearchResult {
                rule_id: package.id,
                rule_name: package.name,
                status: "error".to_string(),
                elapsed_ms: 0,
                candidates: Vec::new(),
                raw_candidates: Vec::new(),
                selected_keyword: None,
                selected_title: None,
                selected_score: None,
                keyword_traces: Vec::new(),
                error: Some(error.to_string()),
            });
        }
    };
    let body = http_get_text(
        &request.request.url,
        request.request.headers.clone(),
        request.request.timeout_ms,
    )
    .await?;
    Ok(yneko_source_rules::parse_search_response(
        &request.rule,
        &request.keyword,
        &body,
        start.elapsed().as_millis() as i64,
    ))
}

async fn resolve_bindings_for_record(
    record: RulePackageRecord,
    subject: yneko_core::SubjectSummary,
    episodes: Vec<yneko_core::Episode>,
    episode_order: i32,
    candidate: CoreSourceCandidate,
    fallback_candidates: Vec<CoreSourceCandidate>,
) -> Result<CoreEpisodeBindingResolveResult, YnekoError> {
    let package = yneko_source_rules::parse_source_package(&record.raw_text)?;
    let request = yneko_source_rules::plan_episode_request(package.clone(), &candidate)?;
    let body = http_get_text(
        &request.request.url,
        request.request.headers.clone(),
        request.request.timeout_ms,
    )
    .await?;
    let bindings = yneko_source_rules::parse_episode_response(
        &request.rule,
        &RuleEpisodeContext {
            subject: subject.clone(),
            episodes,
            episode_order,
            candidate: candidate.clone(),
            fallback_candidates,
        },
        &body,
    )?;
    let selected_binding = bindings
        .iter()
        .find(|binding| binding.episode_order == episode_order)
        .cloned()
        .or_else(|| bindings.first().cloned());
    let attempts = if bindings.is_empty() {
        vec![yneko_source_rules::failure_attempt(
            &package.id,
            "没有匹配到剧集",
        )]
    } else {
        vec![yneko_source_rules::success_attempt(
            &package.id,
            format!("解析到 {} 个剧集绑定", bindings.len()),
        )]
    };
    Ok(CoreEpisodeBindingResolveResult {
        bindings,
        selected_candidate: Some(candidate),
        selected_binding,
        attempts,
    })
}

async fn resolve_streams_for_record(
    record: RulePackageRecord,
    context: RuleStreamContext,
) -> Result<CoreEpisodeStreamResolveResult, YnekoError> {
    let package = yneko_source_rules::parse_source_package(&record.raw_text)?;
    let request = yneko_source_rules::plan_stream_request(package.clone(), &context)?;
    let body = http_get_text(
        &request.request.url,
        request.request.headers.clone(),
        request.request.timeout_ms,
    )
    .await?;
    let streams = yneko_source_rules::parse_stream_response(&request.rule, &context, &body)?;
    let attempts = if streams.is_empty() {
        vec![yneko_source_rules::failure_attempt(
            &package.id,
            "没有解析到播放流",
        )]
    } else {
        vec![yneko_source_rules::success_attempt(
            &package.id,
            format!("解析到 {} 条播放流", streams.len()),
        )]
    };
    Ok(CoreEpisodeStreamResolveResult { streams, attempts })
}

async fn http_get_text(
    url: &str,
    headers: Vec<yneko_core::PlaybackHeader>,
    timeout_ms: Option<u64>,
) -> Result<String, YnekoError> {
    let mut builder = reqwest::Client::builder();
    if let Some(timeout_ms) = timeout_ms {
        builder = builder.timeout(std::time::Duration::from_millis(timeout_ms));
    }
    let client = builder
        .build()
        .map_err(|error| YnekoError::Network(error.to_string()))?;
    let mut request = client.get(url);
    for header in headers {
        request = request.header(header.name, header.value);
    }
    request
        .send()
        .await
        .map_err(|error| YnekoError::Network(error.to_string()))?
        .error_for_status()
        .map_err(|error| YnekoError::Network(error.to_string()))?
        .text()
        .await
        .map_err(|error| YnekoError::Network(error.to_string()))
}

async fn storage_service() -> Result<StorageService, YnekoError> {
    static STORAGE: OnceLock<StorageService> = OnceLock::new();
    if let Some(storage) = STORAGE.get() {
        return Ok(storage.clone());
    }
    let storage = StorageService::open_default().await?;
    let _ = STORAGE.set(storage.clone());
    Ok(storage)
}

impl From<yneko_core::SubjectSummary> for SubjectSummary {
    fn from(value: yneko_core::SubjectSummary) -> Self {
        Self {
            id: value.id,
            name: value.name,
            name_cn: value.name_cn,
            aliases: value.aliases,
            cover_url: value.cover_url,
            summary: value.summary,
            air_date: value.air_date,
            rating_score: value.rating_score,
            rating_rank: value.rating_rank,
            tags: value.tags,
            total_episodes: value.total_episodes,
        }
    }
}

impl From<SubjectSummary> for yneko_core::SubjectSummary {
    fn from(value: SubjectSummary) -> Self {
        Self {
            id: value.id,
            name: value.name,
            name_cn: value.name_cn,
            aliases: value.aliases,
            cover_url: value.cover_url,
            summary: value.summary,
            air_date: value.air_date,
            rating_score: value.rating_score,
            rating_rank: value.rating_rank,
            tags: value.tags,
            total_episodes: value.total_episodes,
        }
    }
}

impl From<yneko_core::Episode> for Episode {
    fn from(value: yneko_core::Episode) -> Self {
        Self {
            id: value.id,
            subject_id: value.subject_id,
            sort: value.sort,
            title: value.title,
            title_cn: value.title_cn,
            air_date: value.air_date,
        }
    }
}

impl From<Episode> for yneko_core::Episode {
    fn from(value: Episode) -> Self {
        Self {
            id: value.id,
            subject_id: value.subject_id,
            sort: value.sort,
            title: value.title,
            title_cn: value.title_cn,
            air_date: value.air_date,
        }
    }
}

impl From<yneko_core::SubjectDetail> for SubjectDetail {
    fn from(value: yneko_core::SubjectDetail) -> Self {
        Self {
            subject: value.subject.into(),
            episodes: value.episodes.into_iter().map(Into::into).collect(),
            is_favorite: value.is_favorite,
            progress: value.progress.map(Into::into),
        }
    }
}

impl From<CoreCollectionStatus> for CollectionStatus {
    fn from(value: CoreCollectionStatus) -> Self {
        match value {
            CoreCollectionStatus::Wish => Self::Wish,
            CoreCollectionStatus::Watching => Self::Watching,
            CoreCollectionStatus::Watched => Self::Watched,
            CoreCollectionStatus::Paused => Self::Paused,
            CoreCollectionStatus::Dropped => Self::Dropped,
        }
    }
}

impl From<CollectionStatus> for CoreCollectionStatus {
    fn from(value: CollectionStatus) -> Self {
        match value {
            CollectionStatus::Wish => Self::Wish,
            CollectionStatus::Watching => Self::Watching,
            CollectionStatus::Watched => Self::Watched,
            CollectionStatus::Paused => Self::Paused,
            CollectionStatus::Dropped => Self::Dropped,
        }
    }
}

impl From<yneko_core::BangumiCalendarDay> for BangumiCalendarDay {
    fn from(value: yneko_core::BangumiCalendarDay) -> Self {
        Self {
            weekday_id: value.weekday_id,
            weekday_cn: value.weekday_cn,
            weekday_en: value.weekday_en,
            items: value.items.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<AnimeRankingSort> for CoreAnimeRankingSort {
    fn from(value: AnimeRankingSort) -> Self {
        match value {
            AnimeRankingSort::Rank => Self::Rank,
            AnimeRankingSort::Heat => Self::Heat,
            AnimeRankingSort::Collect => Self::Collect,
            AnimeRankingSort::Date => Self::Date,
            AnimeRankingSort::Name => Self::Name,
        }
    }
}

impl From<AnimeSeason> for CoreAnimeSeason {
    fn from(value: AnimeSeason) -> Self {
        match value {
            AnimeSeason::Winter => Self::Winter,
            AnimeSeason::Spring => Self::Spring,
            AnimeSeason::Summer => Self::Summer,
            AnimeSeason::Autumn => Self::Autumn,
        }
    }
}

impl From<AnimeRankingRequest> for yneko_core::AnimeRankingRequest {
    fn from(value: AnimeRankingRequest) -> Self {
        Self {
            sort: value.sort.into(),
            filters: value.filters,
            filter_group: value.filter_group,
            filter: value.filter,
            year: value.year,
            season: value.season.map(Into::into),
            keyword: value.keyword,
            page: value.page,
            limit: value.limit,
        }
    }
}

impl From<yneko_core::AnimeRankingApplied> for AnimeRankingApplied {
    fn from(value: yneko_core::AnimeRankingApplied) -> Self {
        Self {
            sort: value.sort,
            filters: value.filters,
            filter_group: value.filter_group,
            filter: value.filter,
            year: value.year,
            season: value.season,
            keyword: value.keyword,
            page: value.page,
            limit: value.limit,
        }
    }
}

impl From<yneko_core::AnimeRankingResponse> for AnimeRankingResponse {
    fn from(value: yneko_core::AnimeRankingResponse) -> Self {
        Self {
            items: value.items.into_iter().map(Into::into).collect(),
            page: value.page,
            has_next: value.has_next,
            applied: value.applied.into(),
        }
    }
}

impl From<BangumiBrowseSort> for CoreBangumiBrowseSort {
    fn from(value: BangumiBrowseSort) -> Self {
        match value {
            BangumiBrowseSort::Rank => Self::Rank,
            BangumiBrowseSort::Date => Self::Date,
        }
    }
}

impl From<BangumiBrowseRequest> for yneko_core::BangumiBrowseRequest {
    fn from(value: BangumiBrowseRequest) -> Self {
        Self {
            sort: value.sort.into(),
            year: value.year,
            month: value.month,
            limit: value.limit,
            offset: value.offset,
        }
    }
}

impl From<yneko_core::PlaybackCandidate> for PlaybackCandidate {
    fn from(value: yneko_core::PlaybackCandidate) -> Self {
        Self {
            id: value.id,
            subject_id: value.subject_id,
            episode_id: value.episode_id,
            source_package_id: value.source_package_id,
            title: value.title,
            url: value.url,
            headers: value.headers.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<yneko_core::PlaybackHeader> for PlaybackHeader {
    fn from(value: yneko_core::PlaybackHeader) -> Self {
        Self {
            name: value.name,
            value: value.value,
        }
    }
}

impl From<PlaybackHeader> for yneko_core::PlaybackHeader {
    fn from(value: PlaybackHeader) -> Self {
        Self {
            name: value.name,
            value: value.value,
        }
    }
}

impl From<CorePlayStream> for PlayStream {
    fn from(value: CorePlayStream) -> Self {
        Self {
            id: value.id,
            rule_id: value.rule_id,
            kind: value.kind,
            url: value.url,
            referer_url: value.referer_url,
            user_agent: value.user_agent,
            headers: value.headers.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<CoreSourcePackageSummary> for SourcePackageSummary {
    fn from(value: CoreSourcePackageSummary) -> Self {
        Self {
            id: value.id,
            name: value.name,
            version: value.version,
            enabled: value.enabled,
            format: value.format,
            source_url: value.source_url,
            diagnostics: value.diagnostics,
            imported_at_ms: value.imported_at_ms,
            updated_at_ms: value.updated_at_ms,
        }
    }
}

impl From<CoreSourceImportResult> for SourceImportResult {
    fn from(value: CoreSourceImportResult) -> Self {
        Self {
            package: value.package.into(),
            diagnostics: value.diagnostics,
        }
    }
}

impl From<CoreSourcePackageText> for SourcePackageText {
    fn from(value: CoreSourcePackageText) -> Self {
        Self {
            id: value.id,
            name: value.name,
            format: value.format,
            body: value.body,
        }
    }
}

impl From<CoreRuleGroupSummary> for RuleGroupSummary {
    fn from(value: CoreRuleGroupSummary) -> Self {
        Self {
            id: value.id,
            name: value.name,
            enabled: value.enabled,
            rule_ids: value.rule_ids,
            disabled_rule_ids: value.disabled_rule_ids,
        }
    }
}

impl From<RuleGroupSummary> for CoreRuleGroupSummary {
    fn from(value: RuleGroupSummary) -> Self {
        Self {
            id: value.id,
            name: value.name,
            enabled: value.enabled,
            rule_ids: value.rule_ids,
            disabled_rule_ids: value.disabled_rule_ids,
        }
    }
}

impl From<CoreRuleRepositorySubscription> for RuleRepositorySubscription {
    fn from(value: CoreRuleRepositorySubscription) -> Self {
        Self {
            id: value.id,
            name: value.name,
            url: value.url,
            enabled: value.enabled,
            updated_at_ms: value.updated_at_ms,
        }
    }
}

impl From<RuleRepositorySubscription> for CoreRuleRepositorySubscription {
    fn from(value: RuleRepositorySubscription) -> Self {
        Self {
            id: value.id,
            name: value.name,
            url: value.url,
            enabled: value.enabled,
            updated_at_ms: value.updated_at_ms,
        }
    }
}

impl From<CoreRuleRepositoryIndexEntry> for RuleRepositoryIndexEntry {
    fn from(value: CoreRuleRepositoryIndexEntry) -> Self {
        Self {
            name: value.name,
            version: value.version,
            last_update_ms: value.last_update_ms,
            anti_crawler_enabled: value.anti_crawler_enabled,
            raw_url: value.raw_url,
        }
    }
}

impl From<RuleRepositoryIndexEntry> for CoreRuleRepositoryIndexEntry {
    fn from(value: RuleRepositoryIndexEntry) -> Self {
        Self {
            name: value.name,
            version: value.version,
            last_update_ms: value.last_update_ms,
            anti_crawler_enabled: value.anti_crawler_enabled,
            raw_url: value.raw_url,
        }
    }
}

impl From<CoreSourceCandidate> for SourceCandidate {
    fn from(value: CoreSourceCandidate) -> Self {
        Self {
            rule_id: value.rule_id,
            rule_name: value.rule_name,
            source_item_key: value.source_item_key,
            title: value.title,
            detail_url: value.detail_url,
            search_url: value.search_url,
            confidence: value.confidence,
            score: value.score,
            matched_keyword: value.matched_keyword,
        }
    }
}

impl From<SourceCandidate> for CoreSourceCandidate {
    fn from(value: SourceCandidate) -> Self {
        Self {
            rule_id: value.rule_id,
            rule_name: value.rule_name,
            source_item_key: value.source_item_key,
            title: value.title,
            detail_url: value.detail_url,
            search_url: value.search_url,
            confidence: value.confidence,
            score: value.score,
            matched_keyword: value.matched_keyword,
        }
    }
}

impl From<CoreRuleSourceSearchResult> for RuleSourceSearchResult {
    fn from(value: CoreRuleSourceSearchResult) -> Self {
        Self {
            rule_id: value.rule_id,
            rule_name: value.rule_name,
            status: value.status,
            elapsed_ms: value.elapsed_ms,
            candidates: value.candidates.into_iter().map(Into::into).collect(),
            raw_candidates: value.raw_candidates.into_iter().map(Into::into).collect(),
            selected_keyword: value.selected_keyword,
            selected_title: value.selected_title,
            selected_score: value.selected_score,
            keyword_traces: value.keyword_traces,
            error: value.error,
        }
    }
}

impl From<CoreSubjectSourceBinding> for SubjectSourceBinding {
    fn from(value: CoreSubjectSourceBinding) -> Self {
        Self {
            subject_id: value.subject_id,
            rule_id: value.rule_id,
            source_item_key: value.source_item_key,
            source_title: value.source_title,
            detail_url: value.detail_url,
        }
    }
}

impl From<CoreEpisodeSourceBinding> for EpisodeSourceBinding {
    fn from(value: CoreEpisodeSourceBinding) -> Self {
        Self {
            subject_id: value.subject_id,
            episode_id: value.episode_id,
            episode_order: value.episode_order,
            rule_id: value.rule_id,
            source_episode_key: value.source_episode_key,
            title: value.title,
            play_url: value.play_url,
            fallback_play_urls: value.fallback_play_urls,
            referer_url: value.referer_url,
            confidence: value.confidence,
        }
    }
}

impl From<EpisodeSourceBinding> for CoreEpisodeSourceBinding {
    fn from(value: EpisodeSourceBinding) -> Self {
        Self {
            subject_id: value.subject_id,
            episode_id: value.episode_id,
            episode_order: value.episode_order,
            rule_id: value.rule_id,
            source_episode_key: value.source_episode_key,
            title: value.title,
            play_url: value.play_url,
            fallback_play_urls: value.fallback_play_urls,
            referer_url: value.referer_url,
            confidence: value.confidence,
        }
    }
}

impl From<CoreRuleResolveAttempt> for RuleResolveAttempt {
    fn from(value: CoreRuleResolveAttempt) -> Self {
        Self {
            rule_id: value.rule_id,
            status: value.status,
            message: value.message,
        }
    }
}

impl From<CoreEpisodeBindingResolveResult> for EpisodeBindingResolveResult {
    fn from(value: CoreEpisodeBindingResolveResult) -> Self {
        Self {
            bindings: value.bindings.into_iter().map(Into::into).collect(),
            selected_candidate: value.selected_candidate.map(Into::into),
            selected_binding: value.selected_binding.map(Into::into),
            attempts: value.attempts.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<CoreEpisodeStreamResolveResult> for EpisodeStreamResolveResult {
    fn from(value: CoreEpisodeStreamResolveResult) -> Self {
        Self {
            streams: value.streams.into_iter().map(Into::into).collect(),
            attempts: value.attempts.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<CorePlaybackProgress> for PlaybackProgress {
    fn from(value: CorePlaybackProgress) -> Self {
        Self {
            subject_id: value.subject_id,
            episode_id: value.episode_id,
            position_ms: value.position_ms,
            duration_ms: value.duration_ms,
            updated_at_ms: value.updated_at_ms,
        }
    }
}

impl From<CoreFavoriteItem> for FavoriteItem {
    fn from(value: CoreFavoriteItem) -> Self {
        Self {
            subject: value.subject.into(),
            status: value.status.into(),
            updated_at_ms: value.updated_at_ms,
        }
    }
}

impl From<CoreWatchHistoryItem> for WatchHistoryItem {
    fn from(value: CoreWatchHistoryItem) -> Self {
        Self {
            subject: value.subject.into(),
            episode: value.episode.into(),
            progress: value.progress.into(),
        }
    }
}

impl From<yneko_storage::AppearanceSettings> for AppearanceSettings {
    fn from(value: yneko_storage::AppearanceSettings) -> Self {
        Self {
            theme_mode: value.theme_mode,
            color_scheme: value.color_scheme,
        }
    }
}

impl From<AppearanceSettings> for yneko_storage::AppearanceSettings {
    fn from(value: AppearanceSettings) -> Self {
        Self {
            theme_mode: value.theme_mode,
            color_scheme: value.color_scheme,
        }
    }
}

fn package_record(value: SourcePackageRecord) -> RulePackageRecord {
    RulePackageRecord {
        id: value.id,
        name: value.name,
        raw_text: value.raw_text,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn resolve_playback_rejects_invalid_ids() {
        let result = resolve_playback(0, 1).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn appearance_settings_round_trip_normalizes_invalid_values() {
        let storage = StorageService::open_memory().await.expect("storage");
        let defaults: AppearanceSettings = storage
            .get_appearance_settings()
            .await
            .expect("defaults")
            .into();
        assert_eq!(defaults.theme_mode, "light");
        assert_eq!(defaults.color_scheme, "yneko");

        let saved: AppearanceSettings = storage
            .save_appearance_settings(
                AppearanceSettings {
                    theme_mode: "dark".to_string(),
                    color_scheme: "cocoa".to_string(),
                }
                .into(),
            )
            .await
            .expect("save")
            .into();
        assert_eq!(saved.theme_mode, "dark");
        assert_eq!(saved.color_scheme, "cocoa");

        let normalized: AppearanceSettings = storage
            .save_appearance_settings(
                AppearanceSettings {
                    theme_mode: "system".to_string(),
                    color_scheme: "violet".to_string(),
                }
                .into(),
            )
            .await
            .expect("normalize")
            .into();
        assert_eq!(normalized.theme_mode, "light");
        assert_eq!(normalized.color_scheme, "yneko");
    }
}
