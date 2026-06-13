use std::collections::HashMap;

use yneko_core::{
    self, AnimeRankingSort as CoreAnimeRankingSort, AnimeSeason as CoreAnimeSeason,
    BangumiBrowseSort as CoreBangumiBrowseSort, YnekoError,
};

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

pub async fn search_subjects(query: String, page: u32) -> Result<Vec<SubjectSummary>, String> {
    yneko_metadata::BangumiClient::default()
        .search_subjects(&query, page)
        .await
        .map(|items| items.into_iter().map(Into::into).collect())
        .map_err(error_message)
}

pub async fn get_subject_detail(subject_id: i64) -> Result<SubjectDetail, String> {
    yneko_metadata::BangumiClient::default()
        .get_subject_detail(subject_id)
        .await
        .map(Into::into)
        .map_err(error_message)
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

pub async fn resolve_playback(
    subject_id: i64,
    episode_id: i64,
) -> Result<Vec<PlaybackCandidate>, String> {
    if subject_id <= 0 || episode_id <= 0 {
        return Err("invalid input: subject_id and episode_id must be positive".to_string());
    }
    Ok(Vec::new())
}

fn error_message(error: YnekoError) -> String {
    error.to_string()
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

impl From<yneko_core::SubjectDetail> for SubjectDetail {
    fn from(value: yneko_core::SubjectDetail) -> Self {
        Self {
            subject: value.subject.into(),
            episodes: value.episodes.into_iter().map(Into::into).collect(),
            is_favorite: value.is_favorite,
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

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn resolve_playback_rejects_invalid_ids() {
        let result = resolve_playback(0, 1).await;
        assert!(result.is_err());
    }
}
