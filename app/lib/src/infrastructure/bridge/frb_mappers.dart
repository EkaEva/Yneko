import 'generated/api.dart' as frb;
import '../../shared/domain/index.dart';

AnimeSubject subjectFromFrb(frb.SubjectSummary subject) {
  return AnimeSubject(
    id: subject.id,
    name: subject.name,
    nameCn: subject.nameCn,
    aliases: subject.aliases,
    coverUrl: subject.coverUrl,
    summary: subject.summary,
    airDate: subject.airDate,
    ratingScore: subject.ratingScore,
    ratingRank: subject.ratingRank,
    tags: subject.tags,
    totalEpisodes: subject.totalEpisodes,
  );
}

AnimeEpisode episodeFromFrb(frb.Episode episode) {
  return AnimeEpisode(
    id: episode.id,
    subjectId: episode.subjectId,
    sort: episode.sort,
    title: episode.title,
    titleCn: episode.titleCn,
    airDate: episode.airDate,
  );
}

SubjectDetail subjectDetailFromFrb(frb.SubjectDetail detail) {
  return SubjectDetail(
    subject: subjectFromFrb(detail.subject),
    episodes: detail.episodes.map(episodeFromFrb).toList(growable: false),
    isFavorite: detail.isFavorite,
  );
}

BangumiCalendarDay calendarDayFromFrb(frb.BangumiCalendarDay day) {
  return BangumiCalendarDay(
    weekdayId: day.weekdayId,
    weekdayCn: day.weekdayCn,
    weekdayEn: day.weekdayEn,
    items: day.items.map(subjectFromFrb).toList(growable: false),
  );
}

AnimeRankingResponse rankingResponseFromFrb(frb.AnimeRankingResponse response) {
  return AnimeRankingResponse(
    items: response.items.map(subjectFromFrb).toList(growable: false),
    page: response.page,
    hasNext: response.hasNext,
    applied: AnimeRankingApplied(
      sort: response.applied.sort,
      filters: response.applied.filters,
      filterGroup: response.applied.filterGroup,
      filter: response.applied.filter,
      year: response.applied.year,
      season: response.applied.season,
      keyword: response.applied.keyword,
      page: response.applied.page,
      limit: response.applied.limit,
    ),
  );
}

frb.AnimeRankingRequest rankingRequestToFrb(AnimeRankingRequest request) {
  return frb.AnimeRankingRequest(
    sort: rankingSortToFrb(request.sort),
    filters: request.filters,
    filterGroup: request.filterGroup,
    filter: request.filter,
    year: request.year,
    season: request.season == null ? null : seasonToFrb(request.season!),
    keyword: request.keyword,
    page: request.page,
    limit: request.limit,
  );
}

frb.AnimeRankingSort rankingSortToFrb(AnimeRankingSort sort) {
  return switch (sort) {
    AnimeRankingSort.rank => frb.AnimeRankingSort.rank,
    AnimeRankingSort.heat => frb.AnimeRankingSort.heat,
    AnimeRankingSort.collect => frb.AnimeRankingSort.collect,
    AnimeRankingSort.date => frb.AnimeRankingSort.date,
    AnimeRankingSort.name => frb.AnimeRankingSort.name,
  };
}

frb.AnimeSeason seasonToFrb(AnimeSeason season) {
  return switch (season) {
    AnimeSeason.winter => frb.AnimeSeason.winter,
    AnimeSeason.spring => frb.AnimeSeason.spring,
    AnimeSeason.summer => frb.AnimeSeason.summer,
    AnimeSeason.autumn => frb.AnimeSeason.autumn,
  };
}

frb.BangumiBrowseRequest browseRequestToFrb(BangumiBrowseRequest request) {
  return frb.BangumiBrowseRequest(
    sort: switch (request.sort) {
      BangumiBrowseSort.rank => frb.BangumiBrowseSort.rank,
      BangumiBrowseSort.date => frb.BangumiBrowseSort.date,
    },
    year: request.year,
    month: request.month,
    limit: request.limit,
    offset: request.offset,
  );
}

PlaybackContract playbackFromFrb(frb.PlaybackCandidate candidate) {
  return PlaybackContract(
    id: candidate.id,
    subjectId: candidate.subjectId,
    episodeId: candidate.episodeId,
    sourcePackageId: candidate.sourcePackageId,
    title: candidate.title,
    url: candidate.url,
    headers: {
      for (final header in candidate.headers) header.name: header.value,
    },
  );
}
