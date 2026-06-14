use std::collections::{BTreeMap, HashSet};
use std::time::Instant;

use regex::Regex;
use scraper::{ElementRef, Html, Selector};
use serde::{Deserialize, Serialize};
use url::Url;
use yneko_core::{
    Episode, EpisodeSourceBinding, PlayStream, PlaybackCandidate, PlaybackHeader,
    RuleRepositoryIndexEntry, RuleResolveAttempt, RuleSourceSearchResult, SourceCandidate,
    SourcePackage, SourceRepository, SubjectSummary, YnekoError, YnekoResult,
};

const FORBIDDEN_FIELDS: &[&str] = &[
    "script",
    "scripts",
    "credential",
    "credentials",
    "drm_bypass",
    "login_bypass",
    "paywall_bypass",
    "anti_scraping_bypass",
];

const ALLOWED_TEMPLATE_FIELDS: &[&str] = &[
    "subjectId",
    "episodeId",
    "episodeOrder",
    "title",
    "episodeTitle",
    "keyword",
    "sourceItemKey",
    "sourceTitle",
    "detailUrl",
    "playUrl",
];

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceRepositoryManifest {
    pub id: String,
    pub name: String,
    pub packages: Vec<SourcePackageManifest>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourcePackageManifest {
    pub id: String,
    pub name: String,
    pub version: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeclarativeSourcePackage {
    pub id: String,
    pub name: String,
    pub version: String,
    #[serde(default, alias = "base_url", alias = "baseURL")]
    pub base_url: Option<String>,
    #[serde(default)]
    pub request: RequestRules,
    #[serde(default)]
    pub search: Option<SearchRules>,
    #[serde(default)]
    pub episodes: Option<EpisodeRules>,
    #[serde(default, alias = "play")]
    pub play: PlayRules,
    #[serde(default)]
    pub playback: PlaybackRules,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RequestRules {
    #[serde(default, alias = "user_agent")]
    pub user_agent: Option<String>,
    #[serde(default, alias = "timeout_ms")]
    pub timeout_ms: Option<u64>,
    #[serde(default, alias = "rate_limit_per_minute")]
    pub rate_limit_per_minute: Option<u32>,
    #[serde(default)]
    pub headers: BTreeMap<String, String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchRules {
    #[serde(default)]
    pub path: String,
    #[serde(default)]
    pub query: BTreeMap<String, String>,
    #[serde(default, alias = "item_selector", alias = "searchList")]
    pub item_selector: String,
    #[serde(default)]
    pub fields: SearchFieldRules,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchFieldRules {
    #[serde(default, alias = "searchName")]
    pub title: String,
    #[serde(default, alias = "searchResult")]
    pub url: String,
    #[serde(default, alias = "source_item_key")]
    pub source_item_key: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EpisodeRules {
    #[serde(default, alias = "item_selector", alias = "chapterResult")]
    pub item_selector: String,
    #[serde(default)]
    pub fields: EpisodeFieldRules,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EpisodeFieldRules {
    #[serde(default)]
    pub title: String,
    #[serde(default)]
    pub url: String,
    #[serde(default, alias = "source_episode_key")]
    pub source_episode_key: String,
    #[serde(default)]
    pub order: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PlayRules {
    #[serde(default, alias = "iframe_selector")]
    pub iframe_selector: Option<String>,
    #[serde(default, alias = "stream_patterns")]
    pub stream_patterns: Vec<StreamPattern>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StreamPattern {
    #[serde(alias = "type")]
    pub kind: String,
    pub regex: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PlaybackRules {
    #[serde(default)]
    pub static_candidates: Vec<StaticPlaybackCandidate>,
    #[serde(default)]
    pub url_template: Option<UrlTemplatePlayback>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StaticPlaybackCandidate {
    pub id: Option<String>,
    pub title: Option<String>,
    pub url: String,
    #[serde(default)]
    pub headers: BTreeMap<String, String>,
    #[serde(default)]
    pub subject_id: Option<i64>,
    #[serde(default)]
    pub episode_id: Option<i64>,
    #[serde(default)]
    pub episode_order: Option<i32>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UrlTemplatePlayback {
    pub id: Option<String>,
    pub title: Option<String>,
    pub url: String,
    #[serde(default)]
    pub headers: BTreeMap<String, String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlaybackResolveContext {
    pub subject_id: i64,
    pub episode_id: i64,
    pub episode_order: i32,
    pub title: String,
    pub episode_title: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RulePackageRecord {
    pub id: String,
    pub name: String,
    pub raw_text: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct RuleSearchContext {
    pub subject: SubjectSummary,
    pub related_titles: Vec<String>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct RuleEpisodeContext {
    pub subject: SubjectSummary,
    pub episodes: Vec<Episode>,
    pub episode_order: i32,
    pub candidate: SourceCandidate,
    pub fallback_candidates: Vec<SourceCandidate>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuleStreamContext {
    pub rule_id: String,
    pub play_url: String,
    pub fallback_play_urls: Vec<String>,
    pub referer_url: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuleHttpRequest {
    pub url: String,
    pub headers: Vec<PlaybackHeader>,
    pub timeout_ms: Option<u64>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuleSearchRequest {
    pub rule: DeclarativeSourcePackage,
    pub request: RuleHttpRequest,
    pub keyword: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuleEpisodeRequest {
    pub rule: DeclarativeSourcePackage,
    pub request: RuleHttpRequest,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuleStreamRequest {
    pub rule: DeclarativeSourcePackage,
    pub request: RuleHttpRequest,
}

pub fn detect_rule_format(text: &str) -> String {
    if text.trim_start().starts_with('{') {
        "json".to_string()
    } else {
        "yaml".to_string()
    }
}

pub fn validate_source_text(text: &str) -> YnekoResult<()> {
    parse_source_package(text).map(|_| ())
}

pub fn parse_source_package(text: &str) -> YnekoResult<DeclarativeSourcePackage> {
    reject_forbidden_fields(text)?;
    let package = if text.trim_start().starts_with('{') {
        serde_json::from_str::<DeclarativeSourcePackage>(text)
            .map_err(|error| YnekoError::SourceRejected(format!("invalid JSON: {error}")))?
    } else {
        yaml_serde::from_str::<DeclarativeSourcePackage>(text)
            .map_err(|error| YnekoError::SourceRejected(format!("invalid YAML: {error}")))?
    };
    validate_package_shape(&package)?;
    Ok(package)
}

pub fn package_diagnostics(package: &DeclarativeSourcePackage) -> Vec<String> {
    let mut diagnostics = Vec::new();
    if package.search.is_some() {
        diagnostics.push("包含搜索规则。".to_string());
    }
    if package.episodes.is_some() {
        diagnostics.push("包含剧集规则。".to_string());
    }
    if !package.play.stream_patterns.is_empty() {
        diagnostics.push(format!(
            "包含 {} 个播放流匹配规则。",
            package.play.stream_patterns.len()
        ));
    }
    if !package.playback.static_candidates.is_empty() {
        diagnostics.push(format!(
            "包含 {} 个静态播放候选。",
            package.playback.static_candidates.len()
        ));
    }
    if package.playback.url_template.is_some() {
        diagnostics.push("包含 episode URL 模板。".to_string());
    }
    if diagnostics.is_empty() {
        diagnostics.push("未声明可用搜索或播放规则。".to_string());
    }
    diagnostics
}

pub fn plan_search_request(
    package: DeclarativeSourcePackage,
    context: &RuleSearchContext,
) -> YnekoResult<RuleSearchRequest> {
    let search = package
        .search
        .as_ref()
        .ok_or_else(|| YnekoError::SourceRejected("missing search rules".to_string()))?;
    let keyword = search_keywords(context)
        .into_iter()
        .next()
        .ok_or_else(|| YnekoError::InvalidInput("missing subject title".to_string()))?;
    let url = render_search_url(&package, search, &keyword)?;
    Ok(RuleSearchRequest {
        request: request_for_url(&package, &url, None)?,
        rule: package,
        keyword,
    })
}

pub fn parse_search_response(
    package: &DeclarativeSourcePackage,
    keyword: &str,
    html: &str,
    elapsed_ms: i64,
) -> RuleSourceSearchResult {
    let started = Instant::now();
    let result = parse_search_response_inner(package, keyword, html, elapsed_ms);
    match result {
        Ok(mut result) => {
            result.elapsed_ms = elapsed_ms.max(started.elapsed().as_millis() as i64);
            result
        }
        Err(error) => error_search_result(package, elapsed_ms, error.to_string()),
    }
}

pub fn plan_episode_request(
    package: DeclarativeSourcePackage,
    candidate: &SourceCandidate,
) -> YnekoResult<RuleEpisodeRequest> {
    let _ = package
        .episodes
        .as_ref()
        .ok_or_else(|| YnekoError::SourceRejected("missing episode rules".to_string()))?;
    Ok(RuleEpisodeRequest {
        request: request_for_url(&package, &candidate.detail_url, Some(&candidate.detail_url))?,
        rule: package,
    })
}

pub fn parse_episode_response(
    package: &DeclarativeSourcePackage,
    context: &RuleEpisodeContext,
    html: &str,
) -> YnekoResult<Vec<EpisodeSourceBinding>> {
    let rules = package
        .episodes
        .as_ref()
        .ok_or_else(|| YnekoError::SourceRejected("missing episode rules".to_string()))?;
    let selector = parse_selector(&rules.item_selector)?;
    let document = Html::parse_document(html);
    let mut bindings = Vec::new();
    for element in document.select(&selector) {
        let title = extract_field(&element, &rules.fields.title, &context.candidate.detail_url)
            .unwrap_or_default();
        let play_url = extract_field(&element, &rules.fields.url, &context.candidate.detail_url)
            .unwrap_or_default();
        if play_url.is_empty() {
            continue;
        }
        let source_episode_key = extract_field(
            &element,
            &rules.fields.source_episode_key,
            &context.candidate.detail_url,
        )
        .unwrap_or_else(|| play_url.clone());
        let order_text =
            extract_field(&element, &rules.fields.order, &context.candidate.detail_url)
                .unwrap_or_else(|| title.clone());
        let order = parse_episode_order(&order_text).unwrap_or(bindings.len() as i32 + 1);
        let episode = context
            .episodes
            .iter()
            .find(|episode| episode.sort == order)
            .or_else(|| context.episodes.get(bindings.len()));
        let Some(episode) = episode else {
            continue;
        };
        bindings.push(EpisodeSourceBinding {
            subject_id: context.subject.id,
            episode_id: episode.id,
            episode_order: episode.sort,
            rule_id: package.id.clone(),
            source_episode_key,
            title: if title.is_empty() {
                episode
                    .title_cn
                    .clone()
                    .unwrap_or_else(|| episode.title.clone())
            } else {
                title
            },
            play_url,
            fallback_play_urls: Vec::new(),
            referer_url: Some(context.candidate.detail_url.clone()),
            confidence: if episode.sort == context.episode_order {
                "exact".to_string()
            } else {
                "possible".to_string()
            },
        });
    }
    Ok(bindings)
}

pub fn plan_stream_request(
    package: DeclarativeSourcePackage,
    context: &RuleStreamContext,
) -> YnekoResult<RuleStreamRequest> {
    Ok(RuleStreamRequest {
        request: request_for_url(&package, &context.play_url, context.referer_url.as_deref())?,
        rule: package,
    })
}

pub fn parse_stream_response(
    package: &DeclarativeSourcePackage,
    context: &RuleStreamContext,
    html: &str,
) -> YnekoResult<Vec<PlayStream>> {
    let mut streams = Vec::new();
    for (index, pattern) in package.play.stream_patterns.iter().enumerate() {
        let regex = Regex::new(&pattern.regex).map_err(|error| {
            YnekoError::SourceRejected(format!("invalid stream regex: {error}"))
        })?;
        for capture in regex.captures_iter(html) {
            let raw = capture
                .get(1)
                .or_else(|| capture.get(0))
                .map(|match_| match_.as_str())
                .unwrap_or_default();
            if raw.is_empty() {
                continue;
            }
            streams.push(PlayStream {
                id: format!("{}:stream:{index}:{}", package.id, streams.len()),
                rule_id: package.id.clone(),
                kind: normalize_stream_kind(&pattern.kind),
                url: absolute_url(raw, &context.play_url).unwrap_or_else(|| raw.to_string()),
                referer_url: context.referer_url.clone(),
                user_agent: package.request.user_agent.clone(),
                headers: headers_for_package(package, context.referer_url.as_deref())?,
            });
        }
    }
    Ok(streams)
}

pub fn resolve_playback_candidates(
    package: &DeclarativeSourcePackage,
    context: &PlaybackResolveContext,
) -> YnekoResult<Vec<PlaybackCandidate>> {
    validate_package_shape(package)?;
    let mut candidates = Vec::new();

    for (index, candidate) in package.playback.static_candidates.iter().enumerate() {
        if !static_candidate_matches(candidate, context) {
            continue;
        }
        let id = candidate
            .id
            .clone()
            .unwrap_or_else(|| format!("{}:static:{index}", package.id));
        candidates.push(PlaybackCandidate {
            id,
            subject_id: context.subject_id,
            episode_id: context.episode_id,
            source_package_id: package.id.clone(),
            title: candidate
                .title
                .clone()
                .unwrap_or_else(|| context.episode_title.clone()),
            url: render_playback_template(&candidate.url, context)?,
            headers: render_headers(&candidate.headers, context)?,
        });
    }

    if let Some(template) = &package.playback.url_template {
        candidates.push(PlaybackCandidate {
            id: template
                .id
                .clone()
                .unwrap_or_else(|| format!("{}:template", package.id)),
            subject_id: context.subject_id,
            episode_id: context.episode_id,
            source_package_id: package.id.clone(),
            title: template
                .title
                .as_deref()
                .map(|value| render_playback_template(value, context))
                .transpose()?
                .unwrap_or_else(|| context.episode_title.clone()),
            url: render_playback_template(&template.url, context)?,
            headers: render_headers(&template.headers, context)?,
        });
    }

    Ok(candidates)
}

pub fn repository_index_url(url: &str) -> String {
    let trimmed = url.trim();
    if trimmed.starts_with("https://raw.githubusercontent.com/") && trimmed.ends_with("index.json")
    {
        return trimmed.to_string();
    }
    if let Some((owner, repo)) = github_owner_repo(trimmed) {
        return format!("https://raw.githubusercontent.com/{owner}/{repo}/main/index.json");
    }
    trimmed.to_string()
}

pub fn repository_rule_raw_url(repository_url: &str, rule_name: &str) -> YnekoResult<String> {
    let safe_name = rule_name.trim().replace('/', "");
    if safe_name.is_empty() {
        return Err(YnekoError::InvalidInput(
            "rule name must not be empty".to_string(),
        ));
    }
    let trimmed = repository_url.trim();
    if let Some((owner, repo)) = github_owner_repo(trimmed) {
        return Ok(format!(
            "https://raw.githubusercontent.com/{owner}/{repo}/main/{safe_name}.json"
        ));
    }
    let base = trimmed.trim_end_matches("index.json");
    Url::parse(base)
        .and_then(|url| url.join(&format!("{safe_name}.json")))
        .map(|url| url.to_string())
        .map_err(|error| YnekoError::InvalidInput(error.to_string()))
}

pub fn parse_repository_index(
    repository_url: &str,
    body: &str,
) -> YnekoResult<Vec<RuleRepositoryIndexEntry>> {
    let parsed: serde_json::Value = serde_json::from_str(body)
        .map_err(|error| YnekoError::SourceRejected(error.to_string()))?;
    let items = parsed.as_array().ok_or_else(|| {
        YnekoError::SourceRejected("repository index must be an array".to_string())
    })?;
    let mut entries = Vec::new();
    for item in items {
        let Some(name) = item.get("name").and_then(|value| value.as_str()) else {
            continue;
        };
        if name.trim().is_empty() {
            continue;
        }
        entries.push(RuleRepositoryIndexEntry {
            name: name.to_string(),
            version: item
                .get("version")
                .and_then(|value| value.as_str())
                .unwrap_or("unknown")
                .to_string(),
            last_update_ms: item.get("lastUpdate").and_then(|value| value.as_i64()),
            anti_crawler_enabled: item
                .get("antiCrawlerEnabled")
                .and_then(|value| value.as_bool())
                .unwrap_or(false),
            raw_url: item
                .get("rawUrl")
                .or_else(|| item.get("download_url"))
                .and_then(|value| value.as_str())
                .map(ToString::to_string)
                .unwrap_or(repository_rule_raw_url(repository_url, name)?),
        });
    }
    Ok(entries)
}

pub fn repository_from_manifest(url: &str, manifest: SourceRepositoryManifest) -> SourceRepository {
    SourceRepository {
        id: manifest.id,
        name: manifest.name,
        url: url.to_string(),
        package_count: manifest.packages.len(),
    }
}

pub fn package_from_manifest(
    repository_id: Option<String>,
    manifest: SourcePackageManifest,
) -> SourcePackage {
    SourcePackage {
        id: manifest.id,
        repository_id,
        name: manifest.name,
        version: manifest.version,
        enabled: true,
    }
}

pub fn success_attempt(rule_id: &str, message: impl Into<String>) -> RuleResolveAttempt {
    RuleResolveAttempt {
        rule_id: rule_id.to_string(),
        status: "success".to_string(),
        message: message.into(),
    }
}

pub fn failure_attempt(rule_id: &str, message: impl Into<String>) -> RuleResolveAttempt {
    RuleResolveAttempt {
        rule_id: rule_id.to_string(),
        status: "error".to_string(),
        message: sanitize_diagnostic(&message.into()),
    }
}

pub fn sanitize_diagnostic(value: &str) -> String {
    static URL_RE: std::sync::OnceLock<Regex> = std::sync::OnceLock::new();
    let regex = URL_RE.get_or_init(|| Regex::new(r"https?://[^\s]+").expect("url regex"));
    regex.replace_all(value, "[url]").to_string()
}

fn parse_search_response_inner(
    package: &DeclarativeSourcePackage,
    keyword: &str,
    html: &str,
    elapsed_ms: i64,
) -> YnekoResult<RuleSourceSearchResult> {
    let search = package
        .search
        .as_ref()
        .ok_or_else(|| YnekoError::SourceRejected("missing search rules".to_string()))?;
    let selector = parse_selector(&search.item_selector)?;
    let document = Html::parse_document(html);
    let mut raw_candidates = Vec::new();
    for element in document.select(&selector) {
        let title =
            extract_field(&element, &search.fields.title, base_url(package)).unwrap_or_default();
        let detail_url =
            extract_field(&element, &search.fields.url, base_url(package)).unwrap_or_default();
        if title.is_empty() || detail_url.is_empty() {
            continue;
        }
        let source_item_key =
            extract_field(&element, &search.fields.source_item_key, base_url(package))
                .unwrap_or_else(|| detail_url.clone());
        let score = title_score(&title, keyword);
        raw_candidates.push(SourceCandidate {
            rule_id: package.id.clone(),
            rule_name: package.name.clone(),
            source_item_key,
            title,
            detail_url,
            search_url: None,
            confidence: if score >= 0.82 {
                "exact".to_string()
            } else {
                "possible".to_string()
            },
            score: Some(score),
            matched_keyword: Some(keyword.to_string()),
        });
    }
    let mut candidates = raw_candidates.clone();
    candidates.sort_by(|left, right| {
        right
            .score
            .partial_cmp(&left.score)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    candidates.retain(|candidate| candidate.score.unwrap_or_default() >= 0.35);
    Ok(RuleSourceSearchResult {
        rule_id: package.id.clone(),
        rule_name: package.name.clone(),
        status: if candidates.is_empty() {
            "miss"
        } else {
            "match"
        }
        .to_string(),
        elapsed_ms,
        selected_keyword: Some(keyword.to_string()),
        selected_title: candidates.first().map(|candidate| candidate.title.clone()),
        selected_score: candidates.first().and_then(|candidate| candidate.score),
        keyword_traces: vec![format!("{} => {} candidates", keyword, candidates.len())],
        candidates,
        raw_candidates,
        error: None,
    })
}

fn error_search_result(
    package: &DeclarativeSourcePackage,
    elapsed_ms: i64,
    error: String,
) -> RuleSourceSearchResult {
    RuleSourceSearchResult {
        rule_id: package.id.clone(),
        rule_name: package.name.clone(),
        status: "error".to_string(),
        elapsed_ms,
        candidates: Vec::new(),
        raw_candidates: Vec::new(),
        selected_keyword: None,
        selected_title: None,
        selected_score: None,
        keyword_traces: Vec::new(),
        error: Some(sanitize_diagnostic(&error)),
    }
}

fn reject_forbidden_fields(text: &str) -> YnekoResult<()> {
    let lowered = text.to_ascii_lowercase();
    for field in FORBIDDEN_FIELDS {
        if lowered.contains(field) {
            return Err(YnekoError::SourceRejected(format!(
                "forbidden field `{field}` is not allowed"
            )));
        }
    }
    Ok(())
}

fn validate_package_shape(package: &DeclarativeSourcePackage) -> YnekoResult<()> {
    validate_identifier("id", &package.id)?;
    validate_required_text("name", &package.name)?;
    validate_required_text("version", &package.version)?;
    if let Some(base_url) = &package.base_url {
        validate_http_url(base_url)?;
    }
    if let Some(search) = &package.search {
        validate_required_text("search.item_selector", &search.item_selector)?;
        validate_required_text("search.fields.title", &search.fields.title)?;
        validate_required_text("search.fields.url", &search.fields.url)?;
    }
    if let Some(episodes) = &package.episodes {
        validate_required_text("episodes.item_selector", &episodes.item_selector)?;
        validate_required_text("episodes.fields.url", &episodes.fields.url)?;
    }
    for pattern in &package.play.stream_patterns {
        validate_required_text("play.stream_patterns.regex", &pattern.regex)?;
        Regex::new(&pattern.regex).map_err(|error| {
            YnekoError::SourceRejected(format!("invalid stream regex: {error}"))
        })?;
    }
    let mut ids = HashSet::new();
    for candidate in &package.playback.static_candidates {
        validate_url_like(&candidate.url)?;
        if let Some(id) = &candidate.id {
            validate_identifier("staticCandidates.id", id)?;
            if !ids.insert(id.clone()) {
                return Err(YnekoError::SourceRejected(format!(
                    "duplicate playback candidate id `{id}`"
                )));
            }
        }
        validate_templates(&candidate.url)?;
        for value in candidate.headers.values() {
            validate_templates(value)?;
        }
    }
    if let Some(template) = &package.playback.url_template {
        validate_url_like(&template.url)?;
        validate_templates(&template.url)?;
        if let Some(id) = &template.id {
            validate_identifier("urlTemplate.id", id)?;
        }
        if let Some(title) = &template.title {
            validate_templates(title)?;
        }
        for value in template.headers.values() {
            validate_templates(value)?;
        }
    }
    Ok(())
}

fn validate_identifier(field: &str, value: &str) -> YnekoResult<()> {
    validate_required_text(field, value)?;
    let valid = value
        .chars()
        .all(|item| item.is_ascii_alphanumeric() || item == '-' || item == '_' || item == '.');
    if !valid {
        return Err(YnekoError::SourceRejected(format!(
            "{field} may only contain ASCII letters, numbers, '.', '-' or '_'"
        )));
    }
    Ok(())
}

fn validate_required_text(field: &str, value: &str) -> YnekoResult<()> {
    if value.trim().is_empty() {
        return Err(YnekoError::SourceRejected(format!(
            "`{field}` must not be empty"
        )));
    }
    Ok(())
}

fn validate_http_url(value: &str) -> YnekoResult<()> {
    let parsed =
        Url::parse(value).map_err(|error| YnekoError::SourceRejected(error.to_string()))?;
    if parsed.scheme() != "http" && parsed.scheme() != "https" {
        return Err(YnekoError::SourceRejected(
            "URL must start with http:// or https://".to_string(),
        ));
    }
    Ok(())
}

fn validate_url_like(value: &str) -> YnekoResult<()> {
    let trimmed = value.trim();
    if !(trimmed.starts_with("http://")
        || trimmed.starts_with("https://")
        || trimmed.contains("{{"))
    {
        return Err(YnekoError::SourceRejected(
            "playback URL must be http(s) or contain a safe template".to_string(),
        ));
    }
    Ok(())
}

fn validate_templates(value: &str) -> YnekoResult<()> {
    let mut rest = value;
    while let Some(start) = rest.find("{{") {
        let after_start = &rest[start + 2..];
        let Some(end) = after_start.find("}}") else {
            return Err(YnekoError::SourceRejected(
                "template placeholder is missing closing `}}`".to_string(),
            ));
        };
        let field = after_start[..end].trim();
        if !ALLOWED_TEMPLATE_FIELDS.contains(&field) {
            return Err(YnekoError::SourceRejected(format!(
                "template field `{field}` is not allowed"
            )));
        }
        rest = &after_start[end + 2..];
    }
    Ok(())
}

fn request_for_url(
    package: &DeclarativeSourcePackage,
    url: &str,
    referer: Option<&str>,
) -> YnekoResult<RuleHttpRequest> {
    Ok(RuleHttpRequest {
        url: url.to_string(),
        headers: headers_for_package(package, referer)?,
        timeout_ms: package.request.timeout_ms,
    })
}

fn headers_for_package(
    package: &DeclarativeSourcePackage,
    referer: Option<&str>,
) -> YnekoResult<Vec<PlaybackHeader>> {
    let mut headers = Vec::new();
    if let Some(user_agent) = &package.request.user_agent {
        headers.push(PlaybackHeader {
            name: "User-Agent".to_string(),
            value: user_agent.clone(),
        });
    }
    if let Some(referer) = referer {
        headers.push(PlaybackHeader {
            name: "Referer".to_string(),
            value: referer.to_string(),
        });
    }
    for (name, value) in &package.request.headers {
        headers.push(PlaybackHeader {
            name: name.clone(),
            value: value.clone(),
        });
    }
    Ok(headers)
}

fn render_search_url(
    package: &DeclarativeSourcePackage,
    search: &SearchRules,
    keyword: &str,
) -> YnekoResult<String> {
    let base = base_url(package);
    validate_required_text("base_url", base)?;
    let mut url = Url::parse(base)
        .and_then(|base_url| base_url.join(&search.path))
        .map_err(|error| YnekoError::SourceRejected(error.to_string()))?;
    for (name, value) in &search.query {
        url.query_pairs_mut()
            .append_pair(name, &value.replace("{{keyword}}", keyword));
    }
    Ok(url.to_string())
}

fn search_keywords(context: &RuleSearchContext) -> Vec<String> {
    let mut keywords = Vec::new();
    if let Some(name_cn) = &context.subject.name_cn {
        keywords.push(name_cn.clone());
    }
    keywords.push(context.subject.name.clone());
    keywords.extend(context.subject.aliases.clone());
    keywords.extend(context.related_titles.clone());
    unique_non_empty(keywords)
}

fn parse_selector(selector: &str) -> YnekoResult<Selector> {
    let css = selector.strip_prefix("xpath:").unwrap_or(selector);
    Selector::parse(css).map_err(|error| {
        YnekoError::SourceRejected(format!("invalid selector `{selector}`: {error}"))
    })
}

fn extract_field(element: &ElementRef<'_>, field: &str, base: &str) -> Option<String> {
    let trimmed = field.trim();
    if trimmed.is_empty() {
        return None;
    }
    let mut current_elements = vec![*element];
    let mut current_value = String::new();
    for raw_step in trimmed.split('|') {
        let step = raw_step.trim();
        if step.is_empty() {
            continue;
        }
        if step == "text" {
            current_value = current_elements
                .first()
                .map(|item| item.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default();
            continue;
        }
        if let Some(attribute) = step.strip_prefix("attr:") {
            current_value = current_elements
                .first()
                .and_then(|item| item.value().attr(attribute.trim()))
                .unwrap_or_default()
                .to_string();
            continue;
        }
        if step == "url" {
            current_value = absolute_url(&current_value, base).unwrap_or(current_value);
            continue;
        }
        let selector = parse_selector(step).ok()?;
        current_elements = current_elements
            .first()
            .into_iter()
            .flat_map(|item| item.select(&selector))
            .collect();
    }
    if current_value.is_empty() && !current_elements.is_empty() {
        current_value = current_elements[0]
            .text()
            .collect::<Vec<_>>()
            .join("")
            .trim()
            .to_string();
    }
    if current_value.trim().is_empty() {
        None
    } else {
        Some(current_value)
    }
}

fn absolute_url(value: &str, base: &str) -> Option<String> {
    if value.starts_with("http://") || value.starts_with("https://") {
        return Some(value.to_string());
    }
    Url::parse(base)
        .and_then(|base_url| base_url.join(value))
        .map(|url| url.to_string())
        .ok()
}

fn title_score(title: &str, keyword: &str) -> f32 {
    let left = normalize_title(title);
    let right = normalize_title(keyword);
    if left.is_empty() || right.is_empty() {
        return 0.0;
    }
    if left == right {
        return 1.0;
    }
    if left.contains(&right) || right.contains(&left) {
        return 0.86;
    }
    let shared = right.chars().filter(|ch| left.contains(*ch)).count();
    shared as f32 / right.chars().count().max(1) as f32
}

fn normalize_title(value: &str) -> String {
    value
        .to_lowercase()
        .chars()
        .filter(|ch| ch.is_alphanumeric())
        .collect()
}

fn parse_episode_order(value: &str) -> Option<i32> {
    static ORDER_RE: std::sync::OnceLock<Regex> = std::sync::OnceLock::new();
    let regex = ORDER_RE.get_or_init(|| Regex::new(r"\d+").expect("episode order regex"));
    regex
        .find(value)
        .and_then(|match_| match_.as_str().parse::<i32>().ok())
}

fn base_url(package: &DeclarativeSourcePackage) -> &str {
    package.base_url.as_deref().unwrap_or("")
}

fn normalize_stream_kind(value: &str) -> String {
    match value {
        "direct" | "mp4" | "webm" => "direct".to_string(),
        _ => "hls".to_string(),
    }
}

fn github_owner_repo(url: &str) -> Option<(&str, &str)> {
    let rest = url.strip_prefix("https://github.com/")?;
    let mut parts = rest.trim_end_matches('/').split('/');
    let owner = parts.next()?;
    let repo = parts.next()?;
    if owner.is_empty() || repo.is_empty() {
        None
    } else {
        Some((owner, repo))
    }
}

fn static_candidate_matches(
    candidate: &StaticPlaybackCandidate,
    context: &PlaybackResolveContext,
) -> bool {
    candidate
        .subject_id
        .is_none_or(|value| value == context.subject_id)
        && candidate
            .episode_id
            .is_none_or(|value| value == context.episode_id)
        && candidate
            .episode_order
            .is_none_or(|value| value == context.episode_order)
}

fn render_headers(
    headers: &BTreeMap<String, String>,
    context: &PlaybackResolveContext,
) -> YnekoResult<Vec<PlaybackHeader>> {
    headers
        .iter()
        .map(|(name, value)| {
            Ok(PlaybackHeader {
                name: name.clone(),
                value: render_playback_template(value, context)?,
            })
        })
        .collect()
}

fn render_playback_template(value: &str, context: &PlaybackResolveContext) -> YnekoResult<String> {
    validate_templates(value)?;
    let mut rendered = value.to_string();
    for (field, replacement) in [
        ("subjectId", context.subject_id.to_string()),
        ("episodeId", context.episode_id.to_string()),
        ("episodeOrder", context.episode_order.to_string()),
        ("title", context.title.clone()),
        ("episodeTitle", context.episode_title.clone()),
    ] {
        rendered = rendered.replace(&format!("{{{{{field}}}}}"), &replacement);
        rendered = rendered.replace(&format!("{{{{ {field} }}}}"), &replacement);
    }
    Ok(rendered)
}

fn unique_non_empty(values: Vec<String>) -> Vec<String> {
    let mut unique = Vec::new();
    for value in values {
        let trimmed = value.trim().to_string();
        if !trimmed.is_empty() && !unique.contains(&trimmed) {
            unique.push(trimmed);
        }
    }
    unique
}

#[cfg(test)]
mod tests {
    use super::*;

    fn context() -> PlaybackResolveContext {
        PlaybackResolveContext {
            subject_id: 400602,
            episode_id: 40060201,
            episode_order: 1,
            title: "葬送的芙莉莲".to_string(),
            episode_title: "冒险的结束".to_string(),
        }
    }

    fn package_text() -> &'static str {
        r#"
id: demo
name: Demo
version: 1.0.0
base_url: "https://example.test"
search:
  path: "/search"
  query:
    q: "{{keyword}}"
  item_selector: ".result-item"
  fields:
    title: ".title | text"
    url: ".title | attr:href | url"
    source_item_key: ".title | attr:data-key"
episodes:
  item_selector: ".episode-list a"
  fields:
    title: "text"
    url: "attr:href | url"
    source_episode_key: "attr:href"
    order: "text"
play:
  stream_patterns:
    - type: "hls"
      regex: "https?://[^\\\"']+\\.m3u8[^\\\"']*"
"#
    }

    #[test]
    fn rejects_script_fields() {
        let result = validate_source_text("name: demo\nscript: alert(1)");
        assert!(matches!(result, Err(YnekoError::SourceRejected(_))));
    }

    #[test]
    fn parses_full_yaml_package() {
        let package = parse_source_package(package_text()).expect("package");
        assert_eq!(package.id, "demo");
        assert!(package.search.is_some());
        assert!(package.episodes.is_some());
        assert_eq!(package.play.stream_patterns.len(), 1);
    }

    #[test]
    fn plans_search_request() {
        let package = parse_source_package(package_text()).expect("package");
        let request = plan_search_request(
            package,
            &RuleSearchContext {
                subject: SubjectSummary {
                    id: 1,
                    name: "Frieren".to_string(),
                    name_cn: Some("葬送的芙莉莲".to_string()),
                    aliases: Vec::new(),
                    cover_url: None,
                    summary: None,
                    air_date: None,
                    rating_score: None,
                    rating_rank: None,
                    tags: Vec::new(),
                    total_episodes: 0,
                },
                related_titles: Vec::new(),
            },
        )
        .expect("request");
        assert!(request.request.url.contains("%E8%91%AC"));
    }

    #[test]
    fn parses_search_candidates() {
        let package = parse_source_package(package_text()).expect("package");
        let result = parse_search_response(
            &package,
            "葬送的芙莉莲",
            r#"<div class="result-item"><a class="title" data-key="frieren" href="/detail/frieren">葬送的芙莉莲</a></div>"#,
            5,
        );
        assert_eq!(result.status, "match");
        assert_eq!(result.candidates.len(), 1);
        assert_eq!(
            result.candidates[0].detail_url,
            "https://example.test/detail/frieren"
        );
    }

    #[test]
    fn parses_episode_bindings() {
        let package = parse_source_package(package_text()).expect("package");
        let subject = SubjectSummary {
            id: 1,
            name: "Frieren".to_string(),
            name_cn: Some("葬送的芙莉莲".to_string()),
            aliases: Vec::new(),
            cover_url: None,
            summary: None,
            air_date: None,
            rating_score: None,
            rating_rank: None,
            tags: Vec::new(),
            total_episodes: 1,
        };
        let episode = Episode {
            id: 10,
            subject_id: 1,
            sort: 1,
            title: "End".to_string(),
            title_cn: Some("冒险的结束".to_string()),
            air_date: None,
        };
        let bindings = parse_episode_response(
            &package,
            &RuleEpisodeContext {
                subject,
                episodes: vec![episode],
                episode_order: 1,
                candidate: SourceCandidate {
                    rule_id: "demo".to_string(),
                    rule_name: "Demo".to_string(),
                    source_item_key: "frieren".to_string(),
                    title: "葬送的芙莉莲".to_string(),
                    detail_url: "https://example.test/detail/frieren".to_string(),
                    search_url: None,
                    confidence: "exact".to_string(),
                    score: Some(1.0),
                    matched_keyword: Some("葬送的芙莉莲".to_string()),
                },
                fallback_candidates: Vec::new(),
            },
            r#"<div class="episode-list"><a href="/play/1">第1话 冒险的结束</a></div>"#,
        )
        .expect("bindings");
        assert_eq!(bindings.len(), 1);
        assert_eq!(bindings[0].play_url, "https://example.test/play/1");
    }

    #[test]
    fn extracts_streams() {
        let package = parse_source_package(package_text()).expect("package");
        let streams = parse_stream_response(
            &package,
            &RuleStreamContext {
                rule_id: "demo".to_string(),
                play_url: "https://example.test/play/1".to_string(),
                fallback_play_urls: Vec::new(),
                referer_url: None,
            },
            r#"var src="https://cdn.example.test/video.m3u8";"#,
        )
        .expect("streams");
        assert_eq!(streams.len(), 1);
    }

    #[test]
    fn resolves_template_candidate() {
        let package = parse_source_package(
            r#"
id: demo
name: Demo
version: 1.0.0
playback:
  urlTemplate:
    id: main
    title: "{{episodeTitle}}"
    url: "https://example.test/{{subjectId}}/{{episodeId}}.m3u8"
"#,
        )
        .expect("package");
        let candidates = resolve_playback_candidates(&package, &context()).expect("candidates");
        assert_eq!(candidates.len(), 1);
        assert_eq!(
            candidates[0].url,
            "https://example.test/400602/40060201.m3u8"
        );
    }

    #[test]
    fn parses_repository_index() {
        let entries = parse_repository_index(
            "https://github.com/owner/repo",
            r#"[{"name":"demo","version":"1","lastUpdate":1}]"#,
        )
        .expect("entries");
        assert_eq!(
            entries[0].raw_url,
            "https://raw.githubusercontent.com/owner/repo/main/demo.json"
        );
    }
}
