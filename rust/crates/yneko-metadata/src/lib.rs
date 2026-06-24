use std::{sync::Arc, time::Duration};

use reqwest::{
    Client, StatusCode, Url,
    header::{AUTHORIZATION, HeaderMap, HeaderValue, USER_AGENT},
};
use serde::de::DeserializeOwned;
use tokio::sync::Semaphore;
use yneko_core::{
    AnimeRankingRequest, AnimeRankingResponse, BangumiBrowseRequest, BangumiBrowseSort,
    BangumiCalendarDay, SubjectDetail, SubjectSummary, YnekoError, YnekoResult, clean_query,
};

mod browser;
mod cache;
mod dto;

use browser::{
    anime_browser_url, anime_ranking_applied, anime_tag_browser_url, browser_page_has_next,
    filter_ranking_items, max_filtered_browser_scan_page, normalize_anime_ranking_request,
    parse_browser_trends, requires_filtered_browser_pagination,
};
use cache::MetadataRequestCache;
use dto::{
    CalendarDay, PagedEpisode, PagedSubject, SearchSubjectsFilter, SearchSubjectsRequest, Subject,
    detail_from_parts,
};

const BANGUMI_API_BASE: &str = "https://api.bgm.tv";
const USER_AGENT_VALUE: &str = concat!(
    "Yneko/",
    env!("CARGO_PKG_VERSION"),
    " (https://github.com/EkaEva/Yneko)"
);
const REQUEST_TIMEOUT_SECONDS: u64 = 15;
const SEARCH_PAGE_LIMIT: u16 = 20;
const BROWSE_DEFAULT_LIMIT: u16 = 30;
const BROWSE_MAX_LIMIT: u16 = 50;
const EPISODE_PAGE_LIMIT: u16 = 200;
const API_CACHE_TTL_SECONDS: u64 = 5 * 60;
const BROWSER_CACHE_TTL_SECONDS: u64 = 5 * 60;
const FAILURE_BACKOFF_SECONDS: u64 = 15;
const API_MAX_CONCURRENT_REQUESTS: usize = 4;
const BROWSER_MAX_CONCURRENT_REQUESTS: usize = 2;

#[derive(Debug, Clone)]
pub struct BangumiClient {
    http: Client,
    api_base: Url,
    request_cache: Arc<MetadataRequestCache>,
    api_limiter: Arc<Semaphore>,
    browser_limiter: Arc<Semaphore>,
}

impl Default for BangumiClient {
    fn default() -> Self {
        Self::new(None).expect("default Bangumi client should build")
    }
}

impl BangumiClient {
    pub fn new(token: Option<String>) -> YnekoResult<Self> {
        Self::with_base_url(BANGUMI_API_BASE, token)
    }

    pub fn with_base_url(base_url: &str, token: Option<String>) -> YnekoResult<Self> {
        let mut headers = HeaderMap::new();
        headers.insert(USER_AGENT, HeaderValue::from_static(USER_AGENT_VALUE));
        let token = token
            .map(|value| value.trim().to_owned())
            .filter(|value| !value.is_empty());
        if let Some(token) = token {
            headers.insert(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("Bearer {token}")).map_err(|error| {
                    YnekoError::MetadataUnavailable(format!(
                        "invalid Bangumi token header: {error}"
                    ))
                })?,
            );
        }

        let http = Client::builder()
            .default_headers(headers)
            .timeout(Duration::from_secs(REQUEST_TIMEOUT_SECONDS))
            .build()
            .map_err(|error| {
                YnekoError::MetadataUnavailable(format!("failed to build Bangumi client: {error}"))
            })?;

        let api_base = Url::parse(base_url).map_err(|error| {
            YnekoError::MetadataUnavailable(format!("invalid Bangumi API base: {error}"))
        })?;

        Ok(Self {
            http,
            api_base,
            request_cache: Arc::new(MetadataRequestCache::new()),
            api_limiter: Arc::new(Semaphore::new(API_MAX_CONCURRENT_REQUESTS)),
            browser_limiter: Arc::new(Semaphore::new(BROWSER_MAX_CONCURRENT_REQUESTS)),
        })
    }

    pub fn base_url(&self) -> &str {
        self.api_base.as_str().trim_end_matches('/')
    }

    pub async fn search_subjects(
        &self,
        query: &str,
        page: u32,
    ) -> YnekoResult<Vec<SubjectSummary>> {
        let query = clean_query(query)?;
        let page = page.max(1);
        let offset = page
            .saturating_sub(1)
            .saturating_mul(u32::from(SEARCH_PAGE_LIMIT));
        let page = self
            .search_subject_page(&query, "match", SEARCH_PAGE_LIMIT, offset)
            .await?;
        Ok(page
            .data
            .into_iter()
            .filter(|subject| subject.subject_type == 2)
            .map(Subject::into_subject)
            .collect())
    }

    pub async fn search_subjects_by_tag(
        &self,
        tag: &str,
        page: u32,
        limit: u16,
    ) -> YnekoResult<Vec<SubjectSummary>> {
        let tag = clean_query(tag)?;
        let page = page.max(1);
        let offset = page.saturating_sub(1).saturating_mul(u32::from(limit));
        self.search_subjects_by_tag_sorted_limit_offset(&tag, "collects", limit, offset)
            .await
    }

    pub async fn get_subject_detail(&self, subject_id: i64) -> YnekoResult<SubjectDetail> {
        if subject_id <= 0 {
            return Err(YnekoError::InvalidInput(
                "subject_id must be positive".to_string(),
            ));
        }
        let url = self
            .api_base
            .join(&format!("/v0/subjects/{subject_id}"))
            .map_err(metadata_error)?;
        let raw = self
            .request_json::<Subject>(self.http.get(url), "subject detail")
            .await?;
        let embedded_episodes = raw.embedded_episodes(subject_id);
        let subject = raw.into_subject();
        let fetched_episodes = self.episodes(subject_id).await;
        let episodes = match fetched_episodes {
            Ok(episodes) if !episodes.is_empty() => episodes,
            Ok(_) => embedded_episodes,
            Err(_error) if !embedded_episodes.is_empty() => embedded_episodes,
            Err(error) => return Err(error),
        };

        Ok(detail_from_parts(subject, episodes))
    }

    pub async fn episodes(&self, subject_id: i64) -> YnekoResult<Vec<yneko_core::Episode>> {
        if subject_id <= 0 {
            return Err(YnekoError::InvalidInput(
                "subject_id must be positive".to_string(),
            ));
        }

        let mut offset = 0;
        let mut episodes = Vec::new();

        loop {
            let url = self
                .api_base
                .join(&format!(
                    "/v0/episodes?subject_id={subject_id}&type=0&limit={EPISODE_PAGE_LIMIT}&offset={offset}"
                ))
                .map_err(metadata_error)?;
            let page = self
                .request_json::<PagedEpisode>(self.http.get(url), "subject episodes")
                .await?;
            let next_offset = next_page_offset(
                page.total,
                page.effective_limit(EPISODE_PAGE_LIMIT),
                page.offset,
                page.data.len(),
            );
            episodes.extend(
                page.data
                    .into_iter()
                    .filter(|episode| episode.episode_type.unwrap_or(0) == 0)
                    .map(|episode| episode.into_episode(subject_id)),
            );

            if let Some(next) = next_offset {
                offset = next;
            } else {
                break;
            }
        }

        Ok(episodes)
    }

    pub async fn get_calendar(&self) -> YnekoResult<Vec<BangumiCalendarDay>> {
        let url = self.api_base.join("/calendar").map_err(metadata_error)?;
        let days = self
            .request_json::<Vec<CalendarDay>>(self.http.get(url), "calendar")
            .await?;
        Ok(days.into_iter().map(CalendarDay::into_day).collect())
    }

    pub async fn browse_subjects(
        &self,
        request: BangumiBrowseRequest,
    ) -> YnekoResult<Vec<SubjectSummary>> {
        let mut url = self.api_base.join("/v0/subjects").map_err(metadata_error)?;
        {
            let mut query = url.query_pairs_mut();
            query.append_pair("type", "2");
            query.append_pair("sort", browse_sort_value(request.sort));
            query.append_pair(
                "limit",
                &request
                    .limit
                    .unwrap_or(BROWSE_DEFAULT_LIMIT)
                    .clamp(1, BROWSE_MAX_LIMIT)
                    .to_string(),
            );
            query.append_pair("offset", &request.offset.unwrap_or(0).to_string());
            if let Some(year) = request.year {
                query.append_pair("year", &year.to_string());
            }
            if let Some(month) = request.month.filter(|month| (1..=12).contains(month)) {
                query.append_pair("month", &month.to_string());
            }
        }

        let page = self
            .request_json::<PagedSubject>(self.http.get(url), "browse subjects")
            .await?;
        Ok(page
            .data
            .into_iter()
            .filter(|subject| subject.subject_type == 2)
            .map(Subject::into_subject)
            .collect())
    }

    pub async fn get_anime_ranking(
        &self,
        request: AnimeRankingRequest,
    ) -> YnekoResult<AnimeRankingResponse> {
        let request = normalize_anime_ranking_request(request);

        if request.keyword.trim().is_empty() {
            let (items, has_next) = self.anime_ranking_from_browser(&request).await?;
            let applied = anime_ranking_applied(&request);
            return Ok(AnimeRankingResponse {
                items,
                has_next,
                page: applied.page,
                applied,
            });
        }

        let page = request.page.saturating_sub(1);
        let offset = page.saturating_mul(u32::from(request.limit));
        let mut items = self
            .search_subjects_sorted_limit_offset(
                &request.keyword,
                "rank",
                u16::from(request.limit),
                offset,
            )
            .await?;
        filter_ranking_items(&mut items, &request);
        let applied = anime_ranking_applied(&request);
        let has_next = items.len() >= usize::from(applied.limit);
        items.truncate(usize::from(applied.limit));
        Ok(AnimeRankingResponse {
            items,
            has_next,
            page: applied.page,
            applied,
        })
    }

    async fn search_subjects_sorted_limit_offset(
        &self,
        keyword: &str,
        sort: &str,
        limit: u16,
        initial_offset: u32,
    ) -> YnekoResult<Vec<SubjectSummary>> {
        let keyword = clean_query(keyword)?;
        let target_limit = limit.max(1);
        let mut subjects = Vec::new();
        let mut offset = initial_offset;

        while subjects.len() < usize::from(target_limit) {
            let remaining = usize::from(target_limit) - subjects.len();
            let page_limit = u16::try_from(remaining)
                .unwrap_or(SEARCH_PAGE_LIMIT)
                .clamp(1, SEARCH_PAGE_LIMIT);
            let page = self
                .search_subject_page(&keyword, sort, page_limit, offset)
                .await?;
            let next_offset = next_page_offset(
                page.total,
                page.effective_limit(page_limit),
                page.offset,
                page.data.len(),
            );
            subjects.extend(
                page.data
                    .into_iter()
                    .filter(|subject| subject.subject_type == 2)
                    .map(Subject::into_subject),
            );

            if let Some(next) = next_offset {
                offset = next;
            } else {
                break;
            }
        }

        subjects.truncate(usize::from(target_limit));
        Ok(subjects)
    }

    async fn search_subjects_by_tag_sorted_limit_offset(
        &self,
        tag: &str,
        sort: &str,
        limit: u16,
        initial_offset: u32,
    ) -> YnekoResult<Vec<SubjectSummary>> {
        let target_limit = limit.max(1);
        let mut subjects = Vec::new();
        let mut seen_count = 0usize;
        let skip = initial_offset as usize;
        let mut page = 1;
        let mut seen_ids = std::collections::HashSet::new();

        while subjects.len() < usize::from(target_limit) {
            let url = anime_tag_browser_url(tag, sort, page)?;
            let html = self.fetch_browser_html(url).await?;
            let page_has_next = browser_page_has_next(&html);
            let page_subjects = parse_browser_trends(&html, usize::MAX)?;

            for subject in page_subjects {
                if seen_count >= skip && seen_ids.insert(subject.id) {
                    subjects.push(subject);
                    if subjects.len() >= usize::from(target_limit) {
                        break;
                    }
                }
                seen_count = seen_count.saturating_add(1);
            }

            if !page_has_next {
                break;
            }

            page = page.saturating_add(1);
        }

        subjects.truncate(usize::from(target_limit));
        Ok(subjects)
    }

    async fn search_subject_page(
        &self,
        keyword: &str,
        sort: &str,
        limit: u16,
        offset: u32,
    ) -> YnekoResult<PagedSubject> {
        let url = self
            .api_base
            .join(&format!(
                "/v0/search/subjects?limit={limit}&offset={offset}"
            ))
            .map_err(metadata_error)?;
        self.request_json::<PagedSubject>(
            self.http.post(url).json(&SearchSubjectsRequest {
                keyword: keyword.trim(),
                sort: normalize_search_sort(sort),
                filter: SearchSubjectsFilter {
                    subject_types: vec![2],
                    nsfw: false,
                },
            }),
            "search subjects",
        )
        .await
    }

    async fn anime_ranking_from_browser(
        &self,
        request: &AnimeRankingRequest,
    ) -> YnekoResult<(Vec<SubjectSummary>, bool)> {
        if !requires_filtered_browser_pagination(request) {
            let url = anime_browser_url(request, request.page)?;
            let html = self.fetch_browser_html(url).await?;
            let items = parse_browser_trends(&html, usize::from(request.limit))?;
            return Ok((items, browser_page_has_next(&html)));
        }

        let page_limit = usize::from(request.limit);
        let skip = request
            .page
            .saturating_sub(1)
            .saturating_mul(u32::from(request.limit)) as usize;
        let mut page = 1;
        let mut seen_matches = 0usize;
        let mut items = Vec::with_capacity(page_limit.saturating_add(1));

        while page <= max_filtered_browser_scan_page() && items.len() <= page_limit {
            let url = anime_browser_url(request, page)?;
            let html = self.fetch_browser_html(url).await?;
            let page_has_next = browser_page_has_next(&html);
            let mut page_items = parse_browser_trends(&html, usize::MAX)?;
            filter_ranking_items(&mut page_items, request);

            for item in page_items {
                if seen_matches >= skip {
                    items.push(item);
                    if items.len() > page_limit {
                        break;
                    }
                }
                seen_matches = seen_matches.saturating_add(1);
            }

            if items.len() > page_limit || !page_has_next {
                break;
            }

            page = page.saturating_add(1);
        }

        let has_next = items.len() > page_limit;
        items.truncate(page_limit);
        Ok((items, has_next))
    }

    async fn fetch_browser_html(&self, url: Url) -> YnekoResult<String> {
        self.request_text(self.http.get(url), "anime ranking").await
    }

    async fn request_json<T: DeserializeOwned>(
        &self,
        request: reqwest::RequestBuilder,
        context: &str,
    ) -> YnekoResult<T> {
        let body = self
            .request_cached_text(request, context, RequestKind::Api)
            .await?;

        serde_json::from_str::<T>(&body).map_err(|error| {
            metadata_error(format!(
                "failed to parse Bangumi {context} response: {error}"
            ))
        })
    }

    async fn request_text(
        &self,
        request: reqwest::RequestBuilder,
        context: &str,
    ) -> YnekoResult<String> {
        self.request_cached_text(request, context, RequestKind::Browser)
            .await
    }

    async fn request_cached_text(
        &self,
        request: reqwest::RequestBuilder,
        context: &str,
        kind: RequestKind,
    ) -> YnekoResult<String> {
        let request = request.build().map_err(|error| {
            metadata_error(format!(
                "failed to build Bangumi {context} request: {error}"
            ))
        })?;
        let cache_key = request_cache_key(&request);
        let http = self.http.clone();
        let limiter = match kind {
            RequestKind::Api => self.api_limiter.clone(),
            RequestKind::Browser => self.browser_limiter.clone(),
        };
        let ttl = match kind {
            RequestKind::Api => Duration::from_secs(API_CACHE_TTL_SECONDS),
            RequestKind::Browser => Duration::from_secs(BROWSER_CACHE_TTL_SECONDS),
        };
        let context = context.to_owned();

        self.request_cache
            .load_or_fetch(
                cache_key,
                ttl,
                Duration::from_secs(FAILURE_BACKOFF_SECONDS),
                move || async move { send_request_text(http, request, context, limiter).await },
            )
            .await
    }
}

#[derive(Debug, Clone, Copy)]
enum RequestKind {
    Api,
    Browser,
}

async fn send_request_text(
    http: Client,
    request: reqwest::Request,
    context: String,
    limiter: Arc<Semaphore>,
) -> YnekoResult<String> {
    let _permit = limiter.acquire_owned().await.map_err(|error| {
        metadata_error(format!("Bangumi {context} request limiter closed: {error}"))
    })?;
    let response = http
        .execute(request)
        .await
        .map_err(|error| metadata_error(format!("Bangumi {context} request failed: {error}")))?;
    let status = response.status();
    let body = response.text().await.map_err(|error| {
        metadata_error(format!(
            "failed to read Bangumi {context} response: {error}"
        ))
    })?;

    if !status.is_success() {
        return Err(status_metadata_error(status, &body, &context));
    }

    Ok(body)
}

fn request_cache_key(request: &reqwest::Request) -> String {
    let mut key = format!("{} {}", request.method(), request.url().as_str());
    if let Some(body) = request.body() {
        key.push('\n');
        if let Some(bytes) = body.as_bytes() {
            key.push_str(&String::from_utf8_lossy(bytes));
        } else {
            key.push_str("<streaming-body>");
        }
    }
    key
}

fn normalize_search_sort(sort: &str) -> &'static str {
    match sort.trim().to_ascii_lowercase().as_str() {
        "heat" => "heat",
        "rank" => "rank",
        "score" => "score",
        _ => "match",
    }
}

fn browse_sort_value(sort: BangumiBrowseSort) -> &'static str {
    match sort {
        BangumiBrowseSort::Date => "date",
        BangumiBrowseSort::Rank => "rank",
    }
}

fn next_page_offset(total: u32, limit: u32, offset: u32, fetched: usize) -> Option<u32> {
    let fetched = u32::try_from(fetched).ok()?;
    if fetched == 0 || limit == 0 {
        return None;
    }

    let next = offset.saturating_add(fetched);
    if total > 0 {
        (next < total).then_some(next)
    } else if fetched >= limit {
        Some(offset.saturating_add(limit))
    } else {
        None
    }
}

fn status_metadata_error(status: StatusCode, body: &str, context: &str) -> YnekoError {
    let body = concise_body(body);
    let message = if body.is_empty() {
        format!("Bangumi {context} request failed with HTTP {status}")
    } else {
        format!("Bangumi {context} request failed with HTTP {status}: {body}")
    };
    metadata_error(message)
}

fn concise_body(body: &str) -> String {
    let normalized = body.split_whitespace().collect::<Vec<_>>().join(" ");
    let clipped = normalized.chars().take(240).collect::<String>();
    if normalized.chars().count() > 240 {
        format!("{clipped}...")
    } else {
        clipped
    }
}

fn metadata_error(error: impl std::fmt::Display) -> YnekoError {
    YnekoError::MetadataUnavailable(error.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_client_uses_bangumi_api() {
        assert_eq!(BangumiClient::default().base_url(), "https://api.bgm.tv");
    }

    #[test]
    fn builds_bangumi_tag_browser_url() {
        let url =
            browser::anime_tag_browser_url("奇幻", "collect", 2).expect("tag url should build");
        assert_eq!(
            url.as_str(),
            "https://bgm.tv/anime/tag/%E5%A5%87%E5%B9%BB?sort=collects&page=2"
        );
    }

    #[test]
    fn maps_subject_to_summary() {
        let subject = serde_json::from_value::<dto::Subject>(serde_json::json!({
            "id": 400602,
            "type": 2,
            "name": "Sousou no Frieren",
            "name_cn": "葬送的芙莉莲",
            "summary": "旅途之后的故事",
            "date": "2023-09-29",
            "images": { "large": "//lain.bgm.tv/pic/cover/l/test.jpg" },
            "rating": { "score": 8.8 },
            "rank": 18,
            "tags": [{ "name": "漫画改" }, { "name": "奇幻" }],
            "eps": 28
        }))
        .expect("subject json should parse");

        let mapped = subject.into_subject();

        assert_eq!(mapped.id, 400602);
        assert_eq!(mapped.name, "Sousou no Frieren");
        assert_eq!(mapped.name_cn.as_deref(), Some("葬送的芙莉莲"));
        assert_eq!(
            mapped.cover_url.as_deref(),
            Some("https://lain.bgm.tv/pic/cover/l/test.jpg")
        );
        assert_eq!(mapped.rating_score, Some(8.8));
        assert_eq!(mapped.rating_rank, Some(18));
        assert_eq!(mapped.total_episodes, 28);
        assert_eq!(mapped.tags, ["漫画改", "奇幻"]);
    }

    #[test]
    fn maps_legacy_calendar_day() {
        let day = serde_json::from_value::<dto::CalendarDay>(serde_json::json!({
            "weekday": { "id": 1, "cn": "星期一", "en": "Mon" },
            "items": [
                { "id": 1, "type": 2, "name": "Anime", "name_cn": "动画", "eps_count": 12 },
                { "id": 2, "type": 1, "name": "Book" }
            ]
        }))
        .expect("calendar json should parse");

        let mapped = day.into_day();

        assert_eq!(mapped.weekday_id, 1);
        assert_eq!(mapped.weekday_cn, "星期一");
        assert_eq!(mapped.items.len(), 1);
        assert_eq!(mapped.items[0].id, 1);
        assert_eq!(mapped.items[0].total_episodes, 12);
    }

    #[test]
    fn parses_bangumi_browser_ranking_items() {
        let html = r#"
        <ul id="browserItemList">
          <li id="item_559670" class="item">
            <a class="l" href="/subject/559670"><img class="cover" src="//lain.bgm.tv/pic/cover/l/a.jpg"></a>
            <div class="inner">
              <h3><a href="/subject/559670" class="l">上伊那牡丹，酒醉身姿似百合花般</a><small class="grey">Kamiina Botan</small></h3>
              <p class="info">TV / 2025年7月 / 漫画改</p>
              <p class="rateInfo"><span class="rank">Rank 823</span><small class="fade">7.3</small></p>
            </div>
          </li>
        </ul>
        <a href="?page=2">下一页</a>
        "#;

        let items = browser::parse_browser_trends(html, 24).expect("ranking should parse");

        assert_eq!(items.len(), 1);
        assert_eq!(items[0].id, 559670);
        assert_eq!(
            items[0].name_cn.as_deref(),
            Some("上伊那牡丹，酒醉身姿似百合花般")
        );
        assert_eq!(items[0].air_date.as_deref(), Some("2025年7月"));
        assert_eq!(items[0].rating_rank, Some(823));
        assert!(browser::browser_page_has_next(html));
    }
}
