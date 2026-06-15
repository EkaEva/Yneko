import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'generated/api.dart' as frb;
import 'generated/frb_generated.dart';
import 'frb_mappers.dart';
import '../../shared/domain/index.dart';

final ynekoBackendProvider = Provider<YnekoBackend>((ref) {
  return const FrbYnekoBackend();
});

abstract interface class YnekoBackend {
  Future<List<AnimeSubject>> searchSubjects(String query, int page);

  Future<SubjectDetail> getSubjectDetail(int subjectId);

  Future<List<BangumiCalendarDay>> getCalendar();

  Future<AnimeRankingResponse> getAnimeRanking(AnimeRankingRequest request);

  Future<List<AnimeSubject>> browseSubjects(BangumiBrowseRequest request);

  Future<List<PlaybackContract>> resolvePlayback({
    required int subjectId,
    required int episodeId,
  });

  Future<SourceImportResult> importSourceText(String text);

  Future<SourceImportResult> importSourceUrl(String url);

  Future<List<SourcePackageSummary>> listSourcePackages();

  Future<void> setSourcePackageEnabled({
    required String id,
    required bool enabled,
  });

  Future<void> deleteSourcePackage(String id);

  Future<SourcePackageText?> getSourcePackageText(String id);

  Future<List<RuleGroupSummary>> listRuleGroups();

  Future<RuleGroupSummary> saveRuleGroup(RuleGroupSummary group);

  Future<void> deleteRuleGroup(String id);

  Future<List<RuleRepositorySubscription>> listRuleRepositorySubscriptions();

  Future<RuleRepositorySubscription> saveRuleRepositorySubscription(
    RuleRepositorySubscription subscription,
  );

  Future<void> deleteRuleRepositorySubscription(String id);

  Future<List<RuleRepositoryIndexEntry>> loadRuleRepositoryIndex(
    RuleRepositorySubscription subscription,
  );

  Future<SourceImportResult> importRepositoryRule({
    required String groupId,
    required RuleRepositoryIndexEntry entry,
  });

  Future<List<RuleSourceSearchResult>> searchRuleSources({
    required int subjectId,
    required List<String> ruleIds,
  });

  Future<EpisodeBindingResolveResult> resolveEpisodeBindings({
    required int subjectId,
    required int episodeId,
    required SourceCandidate candidate,
    required List<SourceCandidate> fallbackCandidates,
  });

  Future<EpisodeStreamResolveResult> resolveEpisodeStreams({
    required String ruleId,
    required String playUrl,
    required List<String> fallbackPlayUrls,
    String? refererUrl,
  });

  Future<List<FavoriteItem>> listFavorites({CollectionStatus? status});

  Future<FavoriteItem> saveFavorite({
    required AnimeSubject subject,
    required CollectionStatus status,
  });

  Future<void> deleteFavorite(int subjectId);

  Future<PlaybackProgress> savePlaybackProgress({
    required AnimeSubject subject,
    required AnimeEpisode episode,
    required int positionMs,
    int? durationMs,
  });

  Future<PlaybackProgress?> getPlaybackProgress({
    required int subjectId,
    required int episodeId,
  });

  Future<List<WatchHistoryItem>> listWatchHistory({int? limit});

  Future<void> deleteWatchHistoryItem({
    required int subjectId,
    required int episodeId,
  });

  Future<void> clearWatchHistory();
}

class FrbYnekoBackend implements YnekoBackend {
  const FrbYnekoBackend();

  static Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    return _initFuture ??= YnekoRustLib.init();
  }

  @override
  Future<List<AnimeSubject>> searchSubjects(String query, int page) async {
    await _ensureInitialized();
    final subjects = await frb.searchSubjects(query: query, page: page);
    return subjects.map(subjectFromFrb).toList(growable: false);
  }

  @override
  Future<SubjectDetail> getSubjectDetail(int subjectId) async {
    await _ensureInitialized();
    return subjectDetailFromFrb(
      await frb.getSubjectDetail(subjectId: subjectId),
    );
  }

  @override
  Future<List<BangumiCalendarDay>> getCalendar() async {
    await _ensureInitialized();
    final days = await frb.getCalendar();
    return days.map(calendarDayFromFrb).toList(growable: false);
  }

  @override
  Future<AnimeRankingResponse> getAnimeRanking(
    AnimeRankingRequest request,
  ) async {
    await _ensureInitialized();
    return rankingResponseFromFrb(
      await frb.getAnimeRanking(request: rankingRequestToFrb(request)),
    );
  }

  @override
  Future<List<AnimeSubject>> browseSubjects(
    BangumiBrowseRequest request,
  ) async {
    await _ensureInitialized();
    final subjects = await frb.browseSubjects(
      request: browseRequestToFrb(request),
    );
    return subjects.map(subjectFromFrb).toList(growable: false);
  }

  @override
  Future<List<PlaybackContract>> resolvePlayback({
    required int subjectId,
    required int episodeId,
  }) async {
    await _ensureInitialized();
    final candidates = await frb.resolvePlayback(
      subjectId: subjectId,
      episodeId: episodeId,
    );
    return candidates.map(playbackFromFrb).toList(growable: false);
  }

  @override
  Future<SourceImportResult> importSourceText(String text) async {
    await _ensureInitialized();
    return sourceImportResultFromFrb(await frb.importSourceText(text: text));
  }

  @override
  Future<SourceImportResult> importSourceUrl(String url) async {
    await _ensureInitialized();
    return sourceImportResultFromFrb(await frb.importSourceUrl(url: url));
  }

  @override
  Future<List<SourcePackageSummary>> listSourcePackages() async {
    await _ensureInitialized();
    final packages = await frb.listSourcePackages();
    return packages.map(sourcePackageSummaryFromFrb).toList(growable: false);
  }

  @override
  Future<void> setSourcePackageEnabled({
    required String id,
    required bool enabled,
  }) async {
    await _ensureInitialized();
    await frb.setSourcePackageEnabled(id: id, enabled: enabled);
  }

  @override
  Future<void> deleteSourcePackage(String id) async {
    await _ensureInitialized();
    await frb.deleteSourcePackage(id: id);
  }

  @override
  Future<SourcePackageText?> getSourcePackageText(String id) async {
    await _ensureInitialized();
    final text = await frb.getSourcePackageText(id: id);
    return text == null ? null : sourcePackageTextFromFrb(text);
  }

  @override
  Future<List<RuleGroupSummary>> listRuleGroups() async {
    await _ensureInitialized();
    final groups = await frb.listRuleGroups();
    return groups.map(ruleGroupFromFrb).toList(growable: false);
  }

  @override
  Future<RuleGroupSummary> saveRuleGroup(RuleGroupSummary group) async {
    await _ensureInitialized();
    return ruleGroupFromFrb(
      await frb.saveRuleGroup(group: ruleGroupToFrb(group)),
    );
  }

  @override
  Future<void> deleteRuleGroup(String id) async {
    await _ensureInitialized();
    await frb.deleteRuleGroup(id: id);
  }

  @override
  Future<List<RuleRepositorySubscription>>
  listRuleRepositorySubscriptions() async {
    await _ensureInitialized();
    final subscriptions = await frb.listRuleRepositorySubscriptions();
    return subscriptions
        .map(repositorySubscriptionFromFrb)
        .toList(growable: false);
  }

  @override
  Future<RuleRepositorySubscription> saveRuleRepositorySubscription(
    RuleRepositorySubscription subscription,
  ) async {
    await _ensureInitialized();
    return repositorySubscriptionFromFrb(
      await frb.saveRuleRepositorySubscription(
        subscription: repositorySubscriptionToFrb(subscription),
      ),
    );
  }

  @override
  Future<void> deleteRuleRepositorySubscription(String id) async {
    await _ensureInitialized();
    await frb.deleteRuleRepositorySubscription(id: id);
  }

  @override
  Future<List<RuleRepositoryIndexEntry>> loadRuleRepositoryIndex(
    RuleRepositorySubscription subscription,
  ) async {
    await _ensureInitialized();
    final entries = await frb.loadRuleRepositoryIndex(
      subscription: repositorySubscriptionToFrb(subscription),
    );
    return entries.map(repositoryIndexEntryFromFrb).toList(growable: false);
  }

  @override
  Future<SourceImportResult> importRepositoryRule({
    required String groupId,
    required RuleRepositoryIndexEntry entry,
  }) async {
    await _ensureInitialized();
    return sourceImportResultFromFrb(
      await frb.importRepositoryRule(
        groupId: groupId,
        entry: repositoryIndexEntryToFrb(entry),
      ),
    );
  }

  @override
  Future<List<RuleSourceSearchResult>> searchRuleSources({
    required int subjectId,
    required List<String> ruleIds,
  }) async {
    await _ensureInitialized();
    final results = await frb.searchRuleSources(
      subjectId: subjectId,
      ruleIds: ruleIds,
    );
    return results.map(searchResultFromFrb).toList(growable: false);
  }

  @override
  Future<EpisodeBindingResolveResult> resolveEpisodeBindings({
    required int subjectId,
    required int episodeId,
    required SourceCandidate candidate,
    required List<SourceCandidate> fallbackCandidates,
  }) async {
    await _ensureInitialized();
    return bindingResolveResultFromFrb(
      await frb.resolveEpisodeBindings(
        subjectId: subjectId,
        episodeId: episodeId,
        candidate: sourceCandidateToFrb(candidate),
        fallbackCandidates: fallbackCandidates
            .map(sourceCandidateToFrb)
            .toList(),
      ),
    );
  }

  @override
  Future<EpisodeStreamResolveResult> resolveEpisodeStreams({
    required String ruleId,
    required String playUrl,
    required List<String> fallbackPlayUrls,
    String? refererUrl,
  }) async {
    await _ensureInitialized();
    return streamResolveResultFromFrb(
      await frb.resolveEpisodeStreams(
        ruleId: ruleId,
        playUrl: playUrl,
        fallbackPlayUrls: fallbackPlayUrls,
        refererUrl: refererUrl,
      ),
    );
  }

  @override
  Future<List<FavoriteItem>> listFavorites({CollectionStatus? status}) async {
    await _ensureInitialized();
    final items = await frb.listFavorites(
      status: status == null ? null : collectionStatusToFrb(status),
    );
    return items.map(favoriteItemFromFrb).toList(growable: false);
  }

  @override
  Future<FavoriteItem> saveFavorite({
    required AnimeSubject subject,
    required CollectionStatus status,
  }) async {
    await _ensureInitialized();
    return favoriteItemFromFrb(
      await frb.saveFavorite(
        subject: subjectToFrb(subject),
        status: collectionStatusToFrb(status),
      ),
    );
  }

  @override
  Future<void> deleteFavorite(int subjectId) async {
    await _ensureInitialized();
    await frb.deleteFavorite(subjectId: subjectId);
  }

  @override
  Future<PlaybackProgress> savePlaybackProgress({
    required AnimeSubject subject,
    required AnimeEpisode episode,
    required int positionMs,
    int? durationMs,
  }) async {
    await _ensureInitialized();
    return playbackProgressFromFrb(
      await frb.savePlaybackProgress(
        subject: subjectToFrb(subject),
        episode: episodeToFrb(episode),
        positionMs: positionMs,
        durationMs: durationMs,
      ),
    );
  }

  @override
  Future<PlaybackProgress?> getPlaybackProgress({
    required int subjectId,
    required int episodeId,
  }) async {
    await _ensureInitialized();
    final progress = await frb.getPlaybackProgress(
      subjectId: subjectId,
      episodeId: episodeId,
    );
    return progress == null ? null : playbackProgressFromFrb(progress);
  }

  @override
  Future<List<WatchHistoryItem>> listWatchHistory({int? limit}) async {
    await _ensureInitialized();
    final items = await frb.listWatchHistory(limit: limit);
    return items.map(watchHistoryItemFromFrb).toList(growable: false);
  }

  @override
  Future<void> deleteWatchHistoryItem({
    required int subjectId,
    required int episodeId,
  }) async {
    await _ensureInitialized();
    await frb.deleteWatchHistoryItem(
      subjectId: subjectId,
      episodeId: episodeId,
    );
  }

  @override
  Future<void> clearWatchHistory() async {
    await _ensureInitialized();
    await frb.clearWatchHistory();
  }
}
