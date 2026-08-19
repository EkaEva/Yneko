use std::collections::HashMap;

use reqwest::Url;
use scraper::{ElementRef, Html, Selector};
use yneko_core::{
    AnimeRankingApplied, AnimeRankingRequest, AnimeRankingSort, AnimeSeason, SubjectSummary,
    YnekoResult,
};

use crate::{
    dto::{non_empty, normalize_image_url},
    metadata_error,
};

pub(super) const RANKING_MAX_LIMIT: u8 = 50;
pub(super) const RANKING_MAX_PAGE: u32 = 20;
const RANKING_MAX_BROWSER_PAGES: u32 = 8;
const BANGUMI_ANIME_BROWSER_URL: &str = "https://bgm.tv/anime/browser";
const BANGUMI_ANIME_TAG_URL: &str = "https://bgm.tv/anime/tag";

pub(super) fn normalize_anime_ranking_request(
    mut request: AnimeRankingRequest,
) -> AnimeRankingRequest {
    request.filters = normalize_anime_ranking_filters(request.filters);
    request.filter_group = normalized_optional(request.filter_group);
    request.filter = normalized_optional(request.filter);
    request.keyword = request.keyword.trim().to_owned();
    request.page = request.page.clamp(1, RANKING_MAX_PAGE);
    request.limit = request.limit.clamp(1, RANKING_MAX_LIMIT);

    if let (Some(group), Some(filter)) = (request.filter_group.clone(), request.filter.clone()) {
        let normalized_filter = normalize_anime_ranking_filter_value(&group, &filter);
        request.filters.entry(group).or_insert(normalized_filter);
    }

    if let Some((group, filter)) = primary_anime_ranking_filter(&request.filters) {
        request.filter_group = Some(group.to_owned());
        request.filter = Some(filter.to_owned());
    } else {
        request.filter_group = None;
        request.filter = None;
    }

    request
}

fn normalize_anime_ranking_filters(filters: HashMap<String, String>) -> HashMap<String, String> {
    filters
        .into_iter()
        .filter_map(|(group, value)| {
            let group = group.trim().to_owned();
            let value = normalize_anime_ranking_filter_value(&group, &value);
            (!group.is_empty() && !value.is_empty() && value != "all").then_some((group, value))
        })
        .collect()
}

fn normalize_anime_ranking_filter_value(group: &str, value: &str) -> String {
    let value = value.trim();
    if group == "category" {
        match value.to_ascii_lowercase().as_str() {
            "tv" => return String::from("tv"),
            "web" => return String::from("web"),
            "ova" => return String::from("ova"),
            "movie" => return String::from("movie"),
            "anime_comic" => return String::from("anime_comic"),
            "misc" => return String::from("misc"),
            _ => {}
        }
        match value {
            "剧场版" => return String::from("movie"),
            "动态漫画" => return String::from("anime_comic"),
            "其他" => return String::from("misc"),
            _ => {}
        }
    }
    value.to_owned()
}

fn normalized_optional(value: Option<String>) -> Option<String> {
    value
        .map(|value| value.trim().to_owned())
        .filter(|value| !value.is_empty() && value != "all")
}

pub(super) fn anime_ranking_applied(request: &AnimeRankingRequest) -> AnimeRankingApplied {
    AnimeRankingApplied {
        sort: ranking_sort_query_value(request.sort).to_owned(),
        filters: request.filters.clone(),
        filter_group: request.filter_group.clone(),
        filter: request.filter.clone(),
        year: request.year,
        season: request
            .season
            .map(|season| anime_season_query_value(season).to_owned()),
        keyword: (!request.keyword.is_empty()).then(|| request.keyword.clone()),
        page: request.page,
        limit: request.limit,
    }
}

pub(super) fn ranking_sort_browser_value(sort: AnimeRankingSort) -> &'static str {
    match sort {
        AnimeRankingSort::Rank => "rank",
        AnimeRankingSort::Heat => "trends",
        AnimeRankingSort::Collect => "collects",
        AnimeRankingSort::Date => "date",
        AnimeRankingSort::Name => "title",
    }
}

pub(super) fn tag_sort_browser_value(sort: &str) -> &'static str {
    match sort.trim().to_ascii_lowercase().as_str() {
        "rank" => "rank",
        "date" => "date",
        "title" | "name" => "title",
        "collect" | "collects" => "collects",
        _ => "collects",
    }
}

fn ranking_sort_query_value(sort: AnimeRankingSort) -> &'static str {
    match sort {
        AnimeRankingSort::Rank => "rank",
        AnimeRankingSort::Heat => "heat",
        AnimeRankingSort::Collect => "collect",
        AnimeRankingSort::Date => "date",
        AnimeRankingSort::Name => "name",
    }
}

fn anime_season_query_value(season: AnimeSeason) -> &'static str {
    match season {
        AnimeSeason::Winter => "winter",
        AnimeSeason::Spring => "spring",
        AnimeSeason::Summer => "summer",
        AnimeSeason::Autumn => "autumn",
    }
}

fn anime_season_month_range(season: AnimeSeason) -> (u8, u8) {
    match season {
        AnimeSeason::Winter => (1, 3),
        AnimeSeason::Spring => (4, 6),
        AnimeSeason::Summer => (7, 9),
        AnimeSeason::Autumn => (10, 12),
    }
}

pub(super) fn requires_filtered_browser_pagination(request: &AnimeRankingRequest) -> bool {
    request.year.is_some()
        && (request.season.is_some() || !request.filters.is_empty() || !request.keyword.is_empty())
}

pub(super) fn max_filtered_browser_scan_page() -> u32 {
    RANKING_MAX_PAGE.saturating_mul(RANKING_MAX_BROWSER_PAGES)
}

pub(super) fn anime_browser_url(request: &AnimeRankingRequest, page: u32) -> YnekoResult<Url> {
    let filter_path = anime_browser_filter_path(request);
    let path = if !filter_path.is_empty() {
        filter_path
    } else if let Some(year) = request.year {
        format!("airtime/{year}")
    } else if let Some(filter) = request.filter.as_deref() {
        url_path_segment(filter)
    } else {
        String::new()
    };
    let base = if path.is_empty() {
        String::from(BANGUMI_ANIME_BROWSER_URL)
    } else {
        format!("{BANGUMI_ANIME_BROWSER_URL}/{path}")
    };
    let mut url = Url::parse(&base)
        .map_err(|error| metadata_error(format!("invalid Bangumi browser url: {error}")))?;

    {
        let mut pairs = url.query_pairs_mut();
        pairs.append_pair("sort", ranking_sort_browser_value(request.sort));
        if page > 1 {
            pairs.append_pair("page", &page.to_string());
        }
    }

    Ok(url)
}

pub(super) fn anime_tag_browser_url(tag: &str, sort: &str, page: u32) -> YnekoResult<Url> {
    let tag = url_path_segment(tag.trim());
    let base = format!("{BANGUMI_ANIME_TAG_URL}/{tag}");
    let mut url = Url::parse(&base)
        .map_err(|error| metadata_error(format!("invalid Bangumi tag browser url: {error}")))?;

    {
        let mut pairs = url.query_pairs_mut();
        pairs.append_pair("sort", tag_sort_browser_value(sort));
        if page > 1 {
            pairs.append_pair("page", &page.to_string());
        }
    }

    Ok(url)
}

fn anime_browser_filter_path(request: &AnimeRankingRequest) -> String {
    anime_browser_filter_values(request)
        .into_iter()
        .map(|value| url_path_segment(&value))
        .collect::<Vec<_>>()
        .join("/")
}

fn anime_browser_filter_values(request: &AnimeRankingRequest) -> Vec<String> {
    let priority = ["category", "type", "source", "region"];
    let mut values = priority
        .iter()
        .filter_map(|group| request.filters.get(*group).cloned())
        .collect::<Vec<_>>();
    let mut extra = request
        .filters
        .iter()
        .filter(|(group, _)| !priority.contains(&group.as_str()))
        .collect::<Vec<_>>();
    extra.sort_by_key(|(group, _)| *group);
    values.extend(extra.into_iter().map(|(_, value)| value.clone()));
    values
}

fn primary_anime_ranking_filter(filters: &HashMap<String, String>) -> Option<(&str, &str)> {
    ["category", "type", "source", "region"]
        .iter()
        .find_map(|group| filters.get(*group).map(|value| (*group, value.as_str())))
        .or_else(|| {
            filters
                .iter()
                .min_by(|(left, _), (right, _)| left.cmp(right))
                .map(|(group, value)| (group.as_str(), value.as_str()))
        })
}

fn url_path_segment(value: &str) -> String {
    value
        .chars()
        .flat_map(|ch| match ch {
            'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '_' | '.' | '~' => vec![ch],
            _ => {
                let mut bytes = [0; 4];
                ch.encode_utf8(&mut bytes)
                    .as_bytes()
                    .iter()
                    .flat_map(|byte| format!("%{byte:02X}").chars().collect::<Vec<_>>())
                    .collect::<Vec<_>>()
            }
        })
        .collect()
}

pub(super) fn parse_browser_trends(html: &str, limit: usize) -> YnekoResult<Vec<SubjectSummary>> {
    let document = Html::parse_document(html);
    let item_selector = parse_selector("ul#browserItemList > li.item")?;
    let mut results = Vec::new();

    for item in document.select(&item_selector).take(limit) {
        if let Some(subject) = parse_browser_trend_item(item) {
            results.push(subject);
        }
    }

    Ok(results)
}

pub(super) fn browser_page_has_next(html: &str) -> bool {
    let document = Html::parse_document(html);
    let Ok(selector) = Selector::parse("a[href*=\"page=\"]") else {
        return false;
    };

    document.select(&selector).any(|link| {
        let text = element_text(link);
        let rel = link.value().attr("rel").unwrap_or_default();
        let class = link.value().attr("class").unwrap_or_default();

        text.contains("下一页")
            || text.contains("››")
            || text.contains("»")
            || text.contains(">>")
            || text.eq_ignore_ascii_case("next")
            || rel == "next"
            || class.contains("next")
    })
}

fn parse_browser_trend_item(item: ElementRef<'_>) -> Option<SubjectSummary> {
    let subject_id = item
        .value()
        .id()
        .and_then(|value| value.strip_prefix("item_"))
        .and_then(|value| value.parse::<i64>().ok())
        .or_else(|| {
            first_attr(item, "a[href^=\"/subject/\"]", "href")
                .and_then(|href| subject_id_from_href(&href))
        })?;

    let title_link = first_element(item, ".inner h3 a[href^=\"/subject/\"]")
        .or_else(|| first_element(item, "h3 a[href^=\"/subject/\"]"))
        .or_else(|| first_element(item, "a[href^=\"/subject/\"]"))?;
    let title = element_text(title_link);
    if title.is_empty() {
        return None;
    }

    let original_title = first_element(item, ".inner h3 small.grey")
        .map(element_text)
        .and_then(non_empty);
    let cover_url = first_attr(item, "img.cover", "src")
        .or_else(|| first_attr(item, "img", "src"))
        .and_then(|url| normalize_image_url(&url));
    let info = first_element(item, ".inner p.info")
        .map(element_text)
        .unwrap_or_default();
    let platform = browser_platform(&info);

    Some(SubjectSummary {
        id: subject_id,
        name: original_title.unwrap_or_else(|| title.clone()),
        name_cn: Some(title),
        aliases: Vec::new(),
        cover_url,
        summary: None,
        air_date: browser_air_date(&info),
        rating_score: rating_score_from_item(item),
        rating_rank: rating_rank_from_item(item),
        tags: platform.into_iter().collect(),
        total_episodes: browser_episode_count(&info),
    })
}

fn parse_selector(selector: &str) -> YnekoResult<Selector> {
    Selector::parse(selector)
        .map_err(|error| metadata_error(format!("invalid selector `{selector}`: {error}")))
}

fn first_element<'a>(root: ElementRef<'a>, selector: &str) -> Option<ElementRef<'a>> {
    let selector = Selector::parse(selector).ok()?;
    root.select(&selector).next()
}

fn first_attr(root: ElementRef<'_>, selector: &str, attr: &str) -> Option<String> {
    first_element(root, selector)?
        .value()
        .attr(attr)
        .map(str::to_owned)
        .and_then(non_empty)
}

fn element_text(element: ElementRef<'_>) -> String {
    element
        .text()
        .flat_map(str::split_whitespace)
        .collect::<Vec<_>>()
        .join(" ")
}

fn subject_id_from_href(href: &str) -> Option<i64> {
    let path = href.split('?').next().unwrap_or(href);
    let id = path
        .strip_prefix("/subject/")
        .or_else(|| path.strip_prefix("https://bgm.tv/subject/"))
        .or_else(|| path.strip_prefix("https://bangumi.tv/subject/"))
        .or_else(|| path.strip_prefix("//bgm.tv/subject/"))
        .or_else(|| path.strip_prefix("//bangumi.tv/subject/"))?;
    id.chars()
        .all(|ch| ch.is_ascii_digit())
        .then(|| id.parse().ok())
        .flatten()
}

fn rating_score_from_item(item: ElementRef<'_>) -> Option<f32> {
    let text = first_element(item, ".collectInfo .fade")
        .or_else(|| first_element(item, ".rateInfo .fade"))
        .map(element_text)
        .or_else(|| first_element(item, ".collectInfo").map(element_text))?;

    text.split_whitespace()
        .find(|part| {
            part.chars().any(|ch| ch == '.')
                && part.chars().all(|ch| ch.is_ascii_digit() || ch == '.')
        })
        .and_then(|part| part.parse().ok())
}

fn rating_rank_from_item(item: ElementRef<'_>) -> Option<u32> {
    let text = first_element(item, ".rank")
        .or_else(|| first_element(item, ".rankBadge"))
        .or_else(|| first_element(item, ".collectInfo"))
        .map(element_text)?;
    let rank_text = text.split("Rank").nth(1)?.trim();
    let digits = rank_text
        .chars()
        .skip_while(|ch| !ch.is_ascii_digit())
        .take_while(|ch| ch.is_ascii_digit())
        .collect::<String>();

    digits.parse().ok()
}

fn browser_air_date(info: &str) -> Option<String> {
    info.split('/')
        .map(str::trim)
        .find(|part| air_date_year_month(Some(part)).is_some())
        .map(str::to_owned)
}

fn browser_episode_count(info: &str) -> u32 {
    let Some(first) = info.split('/').next().map(str::trim) else {
        return 0;
    };
    if first.ends_with('话') || first.ends_with('集') {
        first_u32(first).unwrap_or(0)
    } else {
        0
    }
}

fn browser_platform(info: &str) -> Option<String> {
    let first = info.split('/').next()?.trim();
    if first.ends_with('话') || first.ends_with('集') {
        Some(String::from("TV"))
    } else {
        non_empty(first.to_owned())
    }
}

pub(super) fn filter_ranking_items(items: &mut Vec<SubjectSummary>, request: &AnimeRankingRequest) {
    if let Some(year) = request.year {
        items.retain(|item| {
            air_date_year_month(item.air_date.as_deref()).is_some_and(|(item_year, month)| {
                item_year == year
                    && request.season.is_none_or(|season| {
                        let (start, end) = anime_season_month_range(season);
                        (start..=end).contains(&month)
                    })
            })
        });
    }

    if !request.keyword.is_empty() {
        let keyword = request.keyword.to_lowercase();
        items.retain(|item| {
            item.name.to_lowercase().contains(&keyword)
                || item
                    .name_cn
                    .as_deref()
                    .unwrap_or_default()
                    .to_lowercase()
                    .contains(&keyword)
        });
    }
}

pub(super) fn air_date_year_month(value: Option<&str>) -> Option<(u16, u8)> {
    let value = value?.trim();
    let year = leading_year(value)?;
    let month = if value.contains('年') {
        chinese_air_date_month(value)?
    } else {
        numeric_air_date_month(value)?
    };

    (1..=12).contains(&month).then_some((year, month))
}

fn leading_year(value: &str) -> Option<u16> {
    let year = value
        .chars()
        .skip_while(|ch| !ch.is_ascii_digit())
        .take(4)
        .collect::<String>();

    if year.len() == 4 {
        year.parse().ok()
    } else {
        None
    }
}

fn chinese_air_date_month(value: &str) -> Option<u8> {
    let after_year = value.split_once('年')?.1.trim();

    if let Some(month) = season_word_month(after_year) {
        return Some(month);
    }

    if after_year.contains('季') || after_year.contains('Ｑ') || after_year.contains('Q') {
        let quarter = first_u8(after_year)?;
        return quarter_start_month(quarter);
    }

    if after_year.contains('月') {
        return first_u8(after_year);
    }

    None
}

fn numeric_air_date_month(value: &str) -> Option<u8> {
    let mut numbers = value
        .split(|ch: char| !ch.is_ascii_digit())
        .filter(|part| !part.is_empty());
    let _year = numbers.next()?;
    numbers.next()?.parse().ok()
}

fn first_u8(value: &str) -> Option<u8> {
    value
        .split(|ch: char| !ch.is_ascii_digit())
        .find(|part| !part.is_empty())?
        .parse()
        .ok()
}

fn first_u32(value: &str) -> Option<u32> {
    value
        .split(|ch: char| !ch.is_ascii_digit())
        .find(|part| !part.is_empty())?
        .parse()
        .ok()
}

fn season_word_month(value: &str) -> Option<u8> {
    if value.contains('春') {
        Some(4)
    } else if value.contains('夏') {
        Some(7)
    } else if value.contains('秋') {
        Some(10)
    } else if value.contains('冬') {
        Some(1)
    } else {
        None
    }
}

fn quarter_start_month(quarter: u8) -> Option<u8> {
    match quarter {
        1 => Some(1),
        2 => Some(4),
        3 => Some(7),
        4 => Some(10),
        _ => None,
    }
}
