class AnimeSubject {
  const AnimeSubject({
    required this.id,
    required this.name,
    this.nameCn,
    this.aliases = const [],
    this.coverUrl,
    this.summary,
    this.airDate,
    this.ratingScore,
    this.ratingRank,
    this.tags = const [],
    this.totalEpisodes = 0,
  });

  final int id;
  final String name;
  final String? nameCn;
  final List<String> aliases;
  final String? coverUrl;
  final String? summary;
  final String? airDate;
  final double? ratingScore;
  final int? ratingRank;
  final List<String> tags;
  final int totalEpisodes;

  String get displayTitle {
    final title = nameCn?.trim();
    if (title != null && title.isNotEmpty) return title;
    return name;
  }
}

class AnimeEpisode {
  const AnimeEpisode({
    required this.id,
    required this.subjectId,
    required this.sort,
    required this.title,
    this.titleCn,
    this.airDate,
  });

  final int id;
  final int subjectId;
  final int sort;
  final String title;
  final String? titleCn;
  final String? airDate;

  String get displayTitle {
    final title = titleCn?.trim();
    if (title != null && title.isNotEmpty) return title;
    return this.title;
  }
}

class SubjectDetail {
  const SubjectDetail({
    required this.subject,
    required this.episodes,
    required this.isFavorite,
  });

  final AnimeSubject subject;
  final List<AnimeEpisode> episodes;
  final bool isFavorite;
}

enum AnimeRankingSort { rank, heat, collect, date, name }

enum AnimeSeason { winter, spring, summer, autumn }

class AnimeRankingRequest {
  const AnimeRankingRequest({
    this.sort = AnimeRankingSort.heat,
    this.filters = const {},
    this.filterGroup,
    this.filter,
    this.year,
    this.season,
    this.keyword = '',
    this.page = 1,
    this.limit = 24,
  });

  final AnimeRankingSort sort;
  final Map<String, String> filters;
  final String? filterGroup;
  final String? filter;
  final int? year;
  final AnimeSeason? season;
  final String keyword;
  final int page;
  final int limit;
}

class AnimeRankingApplied {
  const AnimeRankingApplied({
    required this.sort,
    required this.filters,
    this.filterGroup,
    this.filter,
    this.year,
    this.season,
    this.keyword,
    required this.page,
    required this.limit,
  });

  final String sort;
  final Map<String, String> filters;
  final String? filterGroup;
  final String? filter;
  final int? year;
  final String? season;
  final String? keyword;
  final int page;
  final int limit;
}

class AnimeRankingResponse {
  const AnimeRankingResponse({
    required this.items,
    required this.page,
    required this.hasNext,
    required this.applied,
  });

  final List<AnimeSubject> items;
  final int page;
  final bool hasNext;
  final AnimeRankingApplied applied;
}

class BangumiCalendarDay {
  const BangumiCalendarDay({
    required this.weekdayId,
    required this.weekdayCn,
    required this.weekdayEn,
    required this.items,
  });

  final int weekdayId;
  final String weekdayCn;
  final String weekdayEn;
  final List<AnimeSubject> items;
}

enum BangumiBrowseSort { rank, date }

class BangumiBrowseRequest {
  const BangumiBrowseRequest({
    this.sort = BangumiBrowseSort.rank,
    this.year,
    this.month,
    this.limit,
    this.offset,
  });

  final BangumiBrowseSort sort;
  final int? year;
  final int? month;
  final int? limit;
  final int? offset;
}

class PlaybackContract {
  const PlaybackContract({
    required this.id,
    required this.subjectId,
    required this.episodeId,
    required this.sourcePackageId,
    required this.title,
    required this.url,
    this.headers = const {},
  });

  final String id;
  final int subjectId;
  final int episodeId;
  final String sourcePackageId;
  final String title;
  final String url;
  final Map<String, String> headers;
}

class PlayStreamContract {
  const PlayStreamContract({
    required this.id,
    required this.ruleId,
    required this.kind,
    required this.url,
    this.refererUrl,
    this.userAgent,
    this.headers = const {},
  });

  final String id;
  final String ruleId;
  final String kind;
  final String url;
  final String? refererUrl;
  final String? userAgent;
  final Map<String, String> headers;

  PlaybackContract asPlaybackContract({
    required int subjectId,
    required int episodeId,
    required String title,
  }) {
    return PlaybackContract(
      id: id,
      subjectId: subjectId,
      episodeId: episodeId,
      sourcePackageId: ruleId,
      title: title,
      url: url,
      headers: {
        ...headers,
        if (refererUrl != null && refererUrl!.trim().isNotEmpty)
          'Referer': refererUrl!,
        if (userAgent != null && userAgent!.trim().isNotEmpty)
          'User-Agent': userAgent!,
      },
    );
  }
}

class SourcePackageSummary {
  const SourcePackageSummary({
    required this.id,
    required this.name,
    required this.version,
    required this.enabled,
    this.format = 'yaml',
    this.sourceUrl,
    this.diagnostics = const [],
    required this.importedAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String name;
  final String version;
  final bool enabled;
  final String format;
  final String? sourceUrl;
  final List<String> diagnostics;
  final int importedAtMs;
  final int updatedAtMs;

  String get sourceLabel {
    final value = sourceUrl?.trim();
    if (value == null || value.isEmpty) return '文本导入';
    return value;
  }
}

class SourcePackageText {
  const SourcePackageText({
    required this.id,
    required this.name,
    required this.format,
    required this.body,
  });

  final String id;
  final String name;
  final String format;
  final String body;
}

class SourceImportResult {
  const SourceImportResult({
    required this.package,
    this.diagnostics = const [],
  });

  final SourcePackageSummary package;
  final List<String> diagnostics;
}

class RuleGroupSummary {
  const RuleGroupSummary({
    required this.id,
    required this.name,
    required this.enabled,
    this.ruleIds = const [],
    this.disabledRuleIds = const [],
  });

  final String id;
  final String name;
  final bool enabled;
  final List<String> ruleIds;
  final List<String> disabledRuleIds;

  int enabledRuleCount(Iterable<SourcePackageSummary> packages) {
    final ids = ruleIds.toSet();
    return packages
        .where(
          (package) =>
              ids.contains(package.id) &&
              package.enabled &&
              !disabledRuleIds.contains(package.id),
        )
        .length;
  }

  RuleGroupSummary copyWith({
    String? id,
    String? name,
    bool? enabled,
    List<String>? ruleIds,
    List<String>? disabledRuleIds,
  }) {
    return RuleGroupSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      ruleIds: ruleIds ?? this.ruleIds,
      disabledRuleIds: disabledRuleIds ?? this.disabledRuleIds,
    );
  }
}

class RuleRepositorySubscription {
  const RuleRepositorySubscription({
    required this.id,
    required this.name,
    required this.url,
    required this.enabled,
    required this.updatedAtMs,
  });

  final String id;
  final String name;
  final String url;
  final bool enabled;
  final int updatedAtMs;
}

class RuleRepositoryIndexEntry {
  const RuleRepositoryIndexEntry({
    required this.name,
    required this.version,
    this.lastUpdateMs,
    required this.antiCrawlerEnabled,
    required this.rawUrl,
  });

  final String name;
  final String version;
  final int? lastUpdateMs;
  final bool antiCrawlerEnabled;
  final String rawUrl;
}

class SourceCandidate {
  const SourceCandidate({
    required this.ruleId,
    required this.ruleName,
    required this.sourceItemKey,
    required this.title,
    required this.detailUrl,
    this.searchUrl,
    required this.confidence,
    this.score,
    this.matchedKeyword,
  });

  final String ruleId;
  final String ruleName;
  final String sourceItemKey;
  final String title;
  final String detailUrl;
  final String? searchUrl;
  final String confidence;
  final double? score;
  final String? matchedKeyword;
}

class RuleSourceSearchResult {
  const RuleSourceSearchResult({
    required this.ruleId,
    required this.ruleName,
    required this.status,
    required this.elapsedMs,
    this.candidates = const [],
    this.rawCandidates = const [],
    this.selectedKeyword,
    this.selectedTitle,
    this.selectedScore,
    this.keywordTraces = const [],
    this.error,
  });

  final String ruleId;
  final String ruleName;
  final String status;
  final int elapsedMs;
  final List<SourceCandidate> candidates;
  final List<SourceCandidate> rawCandidates;
  final String? selectedKeyword;
  final String? selectedTitle;
  final double? selectedScore;
  final List<String> keywordTraces;
  final String? error;
}

class EpisodeSourceBinding {
  const EpisodeSourceBinding({
    required this.subjectId,
    required this.episodeId,
    required this.episodeOrder,
    required this.ruleId,
    required this.sourceEpisodeKey,
    required this.title,
    required this.playUrl,
    this.fallbackPlayUrls = const [],
    this.refererUrl,
    required this.confidence,
  });

  final int subjectId;
  final int episodeId;
  final int episodeOrder;
  final String ruleId;
  final String sourceEpisodeKey;
  final String title;
  final String playUrl;
  final List<String> fallbackPlayUrls;
  final String? refererUrl;
  final String confidence;
}

class RuleResolveAttempt {
  const RuleResolveAttempt({
    required this.ruleId,
    required this.status,
    required this.message,
  });

  final String ruleId;
  final String status;
  final String message;
}

class EpisodeBindingResolveResult {
  const EpisodeBindingResolveResult({
    this.bindings = const [],
    this.selectedCandidate,
    this.selectedBinding,
    this.attempts = const [],
  });

  final List<EpisodeSourceBinding> bindings;
  final SourceCandidate? selectedCandidate;
  final EpisodeSourceBinding? selectedBinding;
  final List<RuleResolveAttempt> attempts;
}

class EpisodeStreamResolveResult {
  const EpisodeStreamResolveResult({
    this.streams = const [],
    this.attempts = const [],
  });

  final List<PlayStreamContract> streams;
  final List<RuleResolveAttempt> attempts;
}
