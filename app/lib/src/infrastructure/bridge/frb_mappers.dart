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
    progress: detail.progress == null
        ? null
        : playbackProgressFromFrb(detail.progress!),
  );
}

frb.SubjectSummary subjectToFrb(AnimeSubject subject) {
  return frb.SubjectSummary(
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

frb.Episode episodeToFrb(AnimeEpisode episode) {
  return frb.Episode(
    id: episode.id,
    subjectId: episode.subjectId,
    sort: episode.sort,
    title: episode.title,
    titleCn: episode.titleCn,
    airDate: episode.airDate,
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

PlaybackProgress playbackProgressFromFrb(frb.PlaybackProgress progress) {
  return PlaybackProgress(
    subjectId: progress.subjectId,
    episodeId: progress.episodeId,
    positionMs: progress.positionMs,
    durationMs: progress.durationMs,
    updatedAtMs: progress.updatedAtMs,
  );
}

FavoriteItem favoriteItemFromFrb(frb.FavoriteItem favorite) {
  return FavoriteItem(
    subject: subjectFromFrb(favorite.subject),
    status: collectionStatusFromFrb(favorite.status),
    updatedAtMs: favorite.updatedAtMs,
  );
}

WatchHistoryItem watchHistoryItemFromFrb(frb.WatchHistoryItem item) {
  return WatchHistoryItem(
    subject: subjectFromFrb(item.subject),
    episode: episodeFromFrb(item.episode),
    progress: playbackProgressFromFrb(item.progress),
  );
}

CollectionStatus collectionStatusFromFrb(frb.CollectionStatus status) {
  return switch (status) {
    frb.CollectionStatus.wish => CollectionStatus.wish,
    frb.CollectionStatus.watching => CollectionStatus.watching,
    frb.CollectionStatus.watched => CollectionStatus.watched,
    frb.CollectionStatus.paused => CollectionStatus.paused,
    frb.CollectionStatus.dropped => CollectionStatus.dropped,
  };
}

frb.CollectionStatus collectionStatusToFrb(CollectionStatus status) {
  return switch (status) {
    CollectionStatus.wish => frb.CollectionStatus.wish,
    CollectionStatus.watching => frb.CollectionStatus.watching,
    CollectionStatus.watched => frb.CollectionStatus.watched,
    CollectionStatus.paused => frb.CollectionStatus.paused,
    CollectionStatus.dropped => frb.CollectionStatus.dropped,
  };
}

PlayStreamContract playStreamFromFrb(frb.PlayStream stream) {
  return PlayStreamContract(
    id: stream.id,
    ruleId: stream.ruleId,
    kind: stream.kind,
    url: stream.url,
    refererUrl: stream.refererUrl,
    userAgent: stream.userAgent,
    headers: {for (final header in stream.headers) header.name: header.value},
  );
}

SourcePackageSummary sourcePackageSummaryFromFrb(
  frb.SourcePackageSummary package,
) {
  return SourcePackageSummary(
    id: package.id,
    name: package.name,
    version: package.version,
    enabled: package.enabled,
    format: package.format,
    sourceUrl: package.sourceUrl,
    diagnostics: package.diagnostics,
    importedAtMs: package.importedAtMs,
    updatedAtMs: package.updatedAtMs,
  );
}

SourceImportResult sourceImportResultFromFrb(frb.SourceImportResult result) {
  return SourceImportResult(
    package: sourcePackageSummaryFromFrb(result.package),
    diagnostics: result.diagnostics,
  );
}

SourcePackageText sourcePackageTextFromFrb(frb.SourcePackageText text) {
  return SourcePackageText(
    id: text.id,
    name: text.name,
    format: text.format,
    body: text.body,
  );
}

RuleGroupSummary ruleGroupFromFrb(frb.RuleGroupSummary group) {
  return RuleGroupSummary(
    id: group.id,
    name: group.name,
    enabled: group.enabled,
    ruleIds: group.ruleIds,
    disabledRuleIds: group.disabledRuleIds,
  );
}

frb.RuleGroupSummary ruleGroupToFrb(RuleGroupSummary group) {
  return frb.RuleGroupSummary(
    id: group.id,
    name: group.name,
    enabled: group.enabled,
    ruleIds: group.ruleIds,
    disabledRuleIds: group.disabledRuleIds,
  );
}

RuleRepositorySubscription repositorySubscriptionFromFrb(
  frb.RuleRepositorySubscription subscription,
) {
  return RuleRepositorySubscription(
    id: subscription.id,
    name: subscription.name,
    url: subscription.url,
    enabled: subscription.enabled,
    updatedAtMs: subscription.updatedAtMs,
  );
}

frb.RuleRepositorySubscription repositorySubscriptionToFrb(
  RuleRepositorySubscription subscription,
) {
  return frb.RuleRepositorySubscription(
    id: subscription.id,
    name: subscription.name,
    url: subscription.url,
    enabled: subscription.enabled,
    updatedAtMs: subscription.updatedAtMs,
  );
}

RuleRepositoryIndexEntry repositoryIndexEntryFromFrb(
  frb.RuleRepositoryIndexEntry entry,
) {
  return RuleRepositoryIndexEntry(
    name: entry.name,
    version: entry.version,
    lastUpdateMs: entry.lastUpdateMs,
    antiCrawlerEnabled: entry.antiCrawlerEnabled,
    rawUrl: entry.rawUrl,
  );
}

frb.RuleRepositoryIndexEntry repositoryIndexEntryToFrb(
  RuleRepositoryIndexEntry entry,
) {
  return frb.RuleRepositoryIndexEntry(
    name: entry.name,
    version: entry.version,
    lastUpdateMs: entry.lastUpdateMs,
    antiCrawlerEnabled: entry.antiCrawlerEnabled,
    rawUrl: entry.rawUrl,
  );
}

SourceCandidate sourceCandidateFromFrb(frb.SourceCandidate candidate) {
  return SourceCandidate(
    ruleId: candidate.ruleId,
    ruleName: candidate.ruleName,
    sourceItemKey: candidate.sourceItemKey,
    title: candidate.title,
    detailUrl: candidate.detailUrl,
    searchUrl: candidate.searchUrl,
    confidence: candidate.confidence,
    score: candidate.score,
    matchedKeyword: candidate.matchedKeyword,
  );
}

frb.SourceCandidate sourceCandidateToFrb(SourceCandidate candidate) {
  return frb.SourceCandidate(
    ruleId: candidate.ruleId,
    ruleName: candidate.ruleName,
    sourceItemKey: candidate.sourceItemKey,
    title: candidate.title,
    detailUrl: candidate.detailUrl,
    searchUrl: candidate.searchUrl,
    confidence: candidate.confidence,
    score: candidate.score,
    matchedKeyword: candidate.matchedKeyword,
  );
}

RuleSourceSearchResult searchResultFromFrb(frb.RuleSourceSearchResult result) {
  return RuleSourceSearchResult(
    ruleId: result.ruleId,
    ruleName: result.ruleName,
    status: result.status,
    elapsedMs: result.elapsedMs,
    candidates: result.candidates.map(sourceCandidateFromFrb).toList(),
    rawCandidates: result.rawCandidates.map(sourceCandidateFromFrb).toList(),
    selectedKeyword: result.selectedKeyword,
    selectedTitle: result.selectedTitle,
    selectedScore: result.selectedScore,
    keywordTraces: result.keywordTraces,
    error: result.error,
  );
}

EpisodeSourceBinding episodeBindingFromFrb(frb.EpisodeSourceBinding binding) {
  return EpisodeSourceBinding(
    subjectId: binding.subjectId,
    episodeId: binding.episodeId,
    episodeOrder: binding.episodeOrder,
    ruleId: binding.ruleId,
    sourceEpisodeKey: binding.sourceEpisodeKey,
    title: binding.title,
    playUrl: binding.playUrl,
    fallbackPlayUrls: binding.fallbackPlayUrls,
    refererUrl: binding.refererUrl,
    confidence: binding.confidence,
  );
}

RuleResolveAttempt resolveAttemptFromFrb(frb.RuleResolveAttempt attempt) {
  return RuleResolveAttempt(
    ruleId: attempt.ruleId,
    status: attempt.status,
    message: attempt.message,
  );
}

EpisodeBindingResolveResult bindingResolveResultFromFrb(
  frb.EpisodeBindingResolveResult result,
) {
  return EpisodeBindingResolveResult(
    bindings: result.bindings.map(episodeBindingFromFrb).toList(),
    selectedCandidate: result.selectedCandidate == null
        ? null
        : sourceCandidateFromFrb(result.selectedCandidate!),
    selectedBinding: result.selectedBinding == null
        ? null
        : episodeBindingFromFrb(result.selectedBinding!),
    attempts: result.attempts.map(resolveAttemptFromFrb).toList(),
  );
}

EpisodeStreamResolveResult streamResolveResultFromFrb(
  frb.EpisodeStreamResolveResult result,
) {
  return EpisodeStreamResolveResult(
    streams: result.streams.map(playStreamFromFrb).toList(),
    attempts: result.attempts.map(resolveAttemptFromFrb).toList(),
  );
}
