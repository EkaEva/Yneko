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
