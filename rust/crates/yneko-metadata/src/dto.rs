use serde::{Deserialize, Serialize};
use yneko_core::{BangumiCalendarDay, Episode, SubjectDetail, SubjectSummary};

#[derive(Debug, Serialize)]
pub(super) struct SearchSubjectsRequest<'a> {
    pub(super) keyword: &'a str,
    pub(super) sort: &'static str,
    pub(super) filter: SearchSubjectsFilter,
}

#[derive(Debug, Serialize)]
pub(super) struct SearchSubjectsFilter {
    #[serde(rename = "type")]
    pub(super) subject_types: Vec<u8>,
    pub(super) nsfw: bool,
}

#[derive(Debug, Clone, Deserialize)]
pub(super) struct PagedSubject {
    #[serde(default)]
    pub(super) total: u32,
    #[serde(default)]
    pub(super) limit: u32,
    #[serde(default)]
    pub(super) offset: u32,
    #[serde(default)]
    pub(super) data: Vec<Subject>,
}

impl PagedSubject {
    pub(super) fn effective_limit(&self, requested_limit: u16) -> u32 {
        self.limit.max(u32::from(requested_limit))
    }
}

#[derive(Debug, Deserialize)]
pub(super) struct PagedEpisode {
    #[serde(default)]
    pub(super) total: u32,
    #[serde(default)]
    pub(super) limit: u32,
    #[serde(default)]
    pub(super) offset: u32,
    #[serde(default)]
    pub(super) data: Vec<BangumiEpisodeDto>,
}

impl PagedEpisode {
    pub(super) fn effective_limit(&self, requested_limit: u16) -> u32 {
        self.limit.max(u32::from(requested_limit))
    }
}

#[derive(Debug, Clone, Deserialize)]
pub(super) struct Subject {
    pub(super) id: i64,
    #[serde(default, rename = "type")]
    pub(super) subject_type: u8,
    #[serde(default)]
    name: String,
    #[serde(default)]
    name_cn: String,
    #[serde(default)]
    summary: Option<String>,
    #[serde(default)]
    date: Option<String>,
    #[serde(default)]
    images: Option<Images>,
    #[serde(default)]
    rating: Option<Rating>,
    #[serde(default)]
    rank: Option<u32>,
    #[serde(default)]
    tags: Vec<Tag>,
    #[serde(default)]
    eps: Option<SubjectEpisodes>,
    #[serde(default)]
    total_episodes: Option<u32>,
}

impl Subject {
    pub(super) fn into_subject(self) -> SubjectSummary {
        let name_cn = non_empty(self.name_cn);
        let name = non_empty(self.name).unwrap_or_else(|| name_cn.clone().unwrap_or_default());
        let total_episodes = self
            .total_episodes
            .or_else(|| self.eps.as_ref().and_then(SubjectEpisodes::total_count))
            .unwrap_or(0);

        SubjectSummary {
            id: self.id,
            name,
            name_cn,
            aliases: Vec::new(),
            cover_url: self.images.and_then(Images::best_cover),
            summary: self.summary.and_then(non_empty),
            air_date: self.date.and_then(non_empty),
            rating_score: self.rating.and_then(|rating| rating.score),
            rating_rank: self.rank,
            tags: self
                .tags
                .into_iter()
                .filter_map(|tag| non_empty(tag.name))
                .take(16)
                .collect(),
            total_episodes,
        }
    }

    pub(super) fn embedded_episodes(&self, subject_id: i64) -> Vec<Episode> {
        self.eps
            .clone()
            .and_then(SubjectEpisodes::into_items)
            .unwrap_or_default()
            .into_iter()
            .filter(|episode| episode.episode_type.unwrap_or(0) == 0)
            .map(|episode| episode.into_episode(subject_id))
            .collect()
    }
}

#[derive(Debug, Clone, Deserialize)]
#[serde(untagged)]
enum SubjectEpisodes {
    Count(u32),
    Items(Vec<BangumiEpisodeDto>),
}

impl SubjectEpisodes {
    fn total_count(&self) -> Option<u32> {
        match self {
            Self::Count(count) => Some(*count),
            Self::Items(episodes) => u32::try_from(episodes.len()).ok(),
        }
    }

    fn into_items(self) -> Option<Vec<BangumiEpisodeDto>> {
        match self {
            Self::Items(episodes) => Some(episodes),
            Self::Count(_) => None,
        }
    }
}

#[derive(Debug, Clone, Deserialize)]
struct Images {
    #[serde(default)]
    large: Option<String>,
    #[serde(default)]
    common: Option<String>,
    #[serde(default)]
    medium: Option<String>,
}

impl Images {
    fn best_cover(self) -> Option<String> {
        self.large
            .or(self.common)
            .or(self.medium)
            .and_then(|url| normalize_image_url(&url))
    }
}

#[derive(Debug, Clone, Deserialize)]
struct Rating {
    #[serde(default)]
    score: Option<f32>,
}

#[derive(Debug, Clone, Deserialize)]
struct Tag {
    #[serde(default)]
    name: String,
}

#[derive(Debug, Clone, Deserialize)]
pub(super) struct BangumiEpisodeDto {
    id: i64,
    #[serde(default, rename = "type")]
    pub(super) episode_type: Option<u8>,
    #[serde(default)]
    sort: f32,
    #[serde(default)]
    name: String,
    #[serde(default)]
    name_cn: String,
    #[serde(default)]
    airdate: Option<String>,
}

impl BangumiEpisodeDto {
    pub(super) fn into_episode(self, subject_id: i64) -> Episode {
        let sort = if self.sort.is_finite() && self.sort > 0.0 {
            self.sort.round() as i32
        } else {
            0
        };
        let title_cn = non_empty(self.name_cn);
        let title = title_cn
            .clone()
            .or_else(|| non_empty(self.name))
            .unwrap_or_else(|| format!("第 {sort:02} 集"));

        Episode {
            id: self.id,
            subject_id,
            sort,
            title,
            title_cn,
            air_date: self.airdate.and_then(non_empty),
        }
    }
}

#[derive(Debug, Deserialize)]
pub(super) struct CalendarDay {
    #[serde(default)]
    weekday: CalendarWeekday,
    #[serde(default)]
    items: Vec<LegacySubject>,
}

impl CalendarDay {
    pub(super) fn into_day(self) -> BangumiCalendarDay {
        BangumiCalendarDay {
            weekday_id: self.weekday.id,
            weekday_cn: non_empty(self.weekday.cn).unwrap_or_else(|| String::from("未知")),
            weekday_en: non_empty(self.weekday.en).unwrap_or_else(|| String::from("Unknown")),
            items: self
                .items
                .into_iter()
                .filter(|subject| subject.subject_type == 2)
                .map(LegacySubject::into_subject)
                .collect(),
        }
    }
}

#[derive(Debug, Default, Deserialize)]
struct CalendarWeekday {
    #[serde(default)]
    id: u8,
    #[serde(default)]
    cn: String,
    #[serde(default)]
    en: String,
}

#[derive(Debug, Deserialize)]
struct LegacySubject {
    id: i64,
    #[serde(default, rename = "type")]
    subject_type: u8,
    #[serde(default)]
    name: String,
    #[serde(default)]
    name_cn: String,
    #[serde(default)]
    summary: Option<String>,
    #[serde(default)]
    air_date: Option<String>,
    #[serde(default)]
    images: Option<Images>,
    #[serde(default)]
    rating: Option<Rating>,
    #[serde(default)]
    rank: Option<u32>,
    #[serde(default)]
    eps: Option<u32>,
    #[serde(default)]
    eps_count: Option<u32>,
}

impl LegacySubject {
    fn into_subject(self) -> SubjectSummary {
        let name_cn = non_empty(self.name_cn);
        let name = non_empty(self.name).unwrap_or_else(|| name_cn.clone().unwrap_or_default());
        SubjectSummary {
            id: self.id,
            name,
            name_cn,
            aliases: Vec::new(),
            cover_url: self.images.and_then(Images::best_cover),
            summary: self.summary.and_then(non_empty),
            air_date: self.air_date.and_then(non_empty),
            rating_score: self.rating.and_then(|rating| rating.score),
            rating_rank: self.rank,
            tags: Vec::new(),
            total_episodes: self.eps.or(self.eps_count).unwrap_or(0),
        }
    }
}

pub(super) fn detail_from_parts(subject: SubjectSummary, episodes: Vec<Episode>) -> SubjectDetail {
    SubjectDetail {
        subject,
        episodes,
        is_favorite: false,
        progress: None,
    }
}

pub(super) fn non_empty(value: String) -> Option<String> {
    let value = value.trim().to_owned();
    (!value.is_empty()).then_some(value)
}

pub(super) fn normalize_image_url(url: &str) -> Option<String> {
    let url = url.trim();
    if url.is_empty() {
        None
    } else if let Some(path) = url.strip_prefix("//") {
        Some(format!("https://{path}"))
    } else if let Some(path) = url.strip_prefix("http://") {
        Some(format!("https://{path}"))
    } else {
        Some(url.to_owned())
    }
}
