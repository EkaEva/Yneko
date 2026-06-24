import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:yneko/src/features/sources/index.dart';
import 'package:yneko/src/infrastructure/player/player_adapter.dart';
import 'package:yneko/src/infrastructure/bridge/yneko_backend.dart';
import 'package:yneko/src/shared/domain/index.dart';
import 'package:yneko/src/shared/theme/index.dart';

class FakeYnekoBackend implements YnekoBackend {
  FakeYnekoBackend({
    List<SourcePackageSummary>? sourcePackages,
    List<PlaybackContract>? playbackContracts,
    List<List<AnimeSubject>>? searchPages,
    List<List<AnimeSubject>>? tagSearchPages,
    List<List<AnimeSubject>>? rankingPages,
    List<AnimeSubject>? browseSubjectsResult,
    List<BangumiCalendarDay>? calendarDays,
    AppearanceSettings? appearanceSettings,
    List<String>? initialSearchHistory,
    Duration sourceSearchDelay = Duration.zero,
    this.searchErrorPage,
    this.tagSearchErrorPage,
    this.rankingErrorPage,
    this.browseError,
  }) : _sourcePackages = List.of(sourcePackages ?? _defaultPackages),
       _ruleGroups = [
         RuleGroupSummary(
           id: defaultRuleGroupId,
           name: '默认规则组',
           enabled: true,
           ruleIds: (sourcePackages ?? _defaultPackages)
               .map((package) => package.id)
               .toList(),
         ),
       ],
       _playbackContracts = List.of(playbackContracts ?? _defaultPlayback),
       _searchPages = searchPages,
       _tagSearchPages = tagSearchPages,
       _rankingPages = rankingPages,
       _browseSubjectsResult = browseSubjectsResult,
       _calendarDays = calendarDays,
       _appearanceSettings = appearanceSettings ?? AppearanceSettings.defaults,
       _searchHistory = List.of(initialSearchHistory ?? const []),
       _sourceSearchDelay = sourceSearchDelay;

  static const subject = AnimeSubject(
    id: 400602,
    name: 'Sousou no Frieren',
    nameCn: '葬送的芙莉莲',
    coverUrl: 'https://example.test/frieren.jpg',
    summary: '旅途之后的故事。',
    airDate: '2023-09-29',
    ratingScore: 8.8,
    ratingRank: 18,
    tags: ['漫画改', '奇幻'],
    totalEpisodes: 28,
  );

  static const secondSubject = AnimeSubject(
    id: 515759,
    name: 'Mono',
    nameCn: 'mono女孩',
    summary: '相机与日常。',
    airDate: '2025-04-13',
    ratingScore: 7.4,
    tags: ['漫画改', '日常'],
    totalEpisodes: 12,
  );

  static final List<PlaybackContract> _defaultPlayback = [
    PlaybackContract(
      id: 'demo-template',
      subjectId: subject.id,
      episodeId: subject.id * 100 + 1,
      sourcePackageId: 'demo',
      title: 'Demo 线路',
      url: 'https://example.test/video.m3u8',
    ),
    PlaybackContract(
      id: 'mono-template',
      subjectId: secondSubject.id,
      episodeId: secondSubject.id * 100 + 1,
      sourcePackageId: 'demo',
      title: 'Demo 线路',
      url: 'https://example.test/mono.m3u8',
    ),
  ];

  static const List<SourcePackageSummary> _defaultPackages = [
    SourcePackageSummary(
      id: 'demo',
      name: 'Demo',
      version: '1.0.0',
      enabled: true,
      format: 'yaml',
      diagnostics: ['包含搜索规则。', '包含剧集规则。'],
      importedAtMs: 1,
      updatedAtMs: 2,
    ),
  ];

  final List<SourcePackageSummary> _sourcePackages;
  final List<RuleGroupSummary> _ruleGroups;
  final List<RuleRepositorySubscription> _subscriptions = [
    defaultRuleRepositorySubscription,
  ];
  final List<PlaybackContract> _playbackContracts;
  final List<List<AnimeSubject>>? _searchPages;
  final List<List<AnimeSubject>>? _tagSearchPages;
  final List<List<AnimeSubject>>? _rankingPages;
  final List<AnimeSubject>? _browseSubjectsResult;
  final List<BangumiCalendarDay>? _calendarDays;
  final List<FavoriteItem> _favorites = [];
  final List<WatchHistoryItem> _history = [];
  List<String> _searchHistory;
  AppearanceSettings _appearanceSettings;
  final Duration _sourceSearchDelay;
  final int? searchErrorPage;
  final int? tagSearchErrorPage;
  final int? rankingErrorPage;
  final String? browseError;
  final List<({String query, int page})> searchRequests = [];
  final List<({String tag, int page})> tagSearchRequests = [];
  final List<AnimeRankingRequest> rankingRequests = [];
  final List<BangumiBrowseRequest> browseRequests = [];
  final List<List<String>> savedSearchHistory = [];

  @override
  Future<AppearanceSettings> getAppearanceSettings() async {
    return _appearanceSettings;
  }

  @override
  Future<AppearanceSettings> saveAppearanceSettings(
    AppearanceSettings settings,
  ) async {
    final normalized = AppearanceSettings(
      themeMode: settings.themeMode == ThemeMode.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      colorScheme: YnekoColorScheme.fromValue(settings.colorScheme.name),
    );
    _appearanceSettings = normalized;
    return normalized;
  }

  @override
  Future<List<AnimeSubject>> searchSubjects(String query, int page) async {
    searchRequests.add((query: query, page: page));
    if (searchErrorPage == page) {
      throw StateError('search page $page failed');
    }
    final pages = _searchPages;
    if (pages == null) return const [subject, secondSubject];
    return pages[(page - 1).clamp(0, pages.length - 1)];
  }

  @override
  Future<List<AnimeSubject>> searchTagSubjects(String tag, int page) async {
    tagSearchRequests.add((tag: tag, page: page));
    if (tagSearchErrorPage == page) {
      throw StateError('tag search page $page failed');
    }
    final pages = _tagSearchPages;
    if (pages == null) return const [subject, secondSubject];
    return pages[(page - 1).clamp(0, pages.length - 1)];
  }

  @override
  Future<SubjectDetail> getSubjectDetail(int subjectId) async {
    final detailSubject = subjectId == secondSubject.id
        ? secondSubject
        : subject;
    return SubjectDetail(
      subject: detailSubject,
      isFavorite: false,
      episodes: [
        AnimeEpisode(
          id: detailSubject.id * 100 + 1,
          subjectId: detailSubject.id,
          sort: 1,
          title: '旅途的终点',
          titleCn: '冒险的结束',
          airDate: '2023-09-29',
        ),
      ],
      progress: _history
          .where((item) => item.subject.id == detailSubject.id)
          .firstOrNull
          ?.progress,
    );
  }

  @override
  Future<List<BangumiCalendarDay>> getCalendar() async {
    return _calendarDays ??
        const [
          BangumiCalendarDay(
            weekdayId: 1,
            weekdayCn: '星期一',
            weekdayEn: 'Mon',
            items: [secondSubject],
          ),
          BangumiCalendarDay(
            weekdayId: 6,
            weekdayCn: '星期六',
            weekdayEn: 'Sat',
            items: [subject],
          ),
        ];
  }

  @override
  Future<AnimeRankingResponse> getAnimeRanking(
    AnimeRankingRequest request,
  ) async {
    rankingRequests.add(request);
    if (rankingErrorPage == request.page) {
      throw StateError('ranking page ${request.page} failed');
    }
    final pages = _rankingPages;
    final items = pages == null
        ? (request.sort == AnimeRankingSort.rank
              ? const [subject, secondSubject]
              : const [secondSubject, subject])
        : pages[(request.page - 1).clamp(0, pages.length - 1)];
    return AnimeRankingResponse(
      items: items,
      page: request.page,
      hasNext: pages != null && request.page < pages.length,
      applied: AnimeRankingApplied(
        sort: request.sort.name,
        filters: request.filters,
        filterGroup: request.filterGroup,
        filter: request.filter,
        year: request.year,
        season: request.season?.name,
        page: request.page,
        limit: request.limit,
      ),
    );
  }

  @override
  Future<List<AnimeSubject>> browseSubjects(
    BangumiBrowseRequest request,
  ) async {
    browseRequests.add(request);
    final error = browseError;
    if (error != null) throw StateError(error);
    return _browseSubjectsResult ?? const [subject, secondSubject];
  }

  @override
  Future<List<PlaybackContract>> resolvePlayback({
    required int subjectId,
    required int episodeId,
  }) async {
    return _playbackContracts
        .where(
          (item) => item.subjectId == subjectId && item.episodeId == episodeId,
        )
        .toList(growable: false);
  }

  @override
  Future<SourceImportResult> importSourceText(String text) async {
    final id = RegExp(r'id:\s*([^\s]+)').firstMatch(text)?.group(1) ?? 'demo';
    final package = SourcePackageSummary(
      id: id,
      name: RegExp(r'name:\s*(.+)').firstMatch(text)?.group(1) ?? 'Demo',
      version:
          RegExp(r'version:\s*([^\s]+)').firstMatch(text)?.group(1) ?? '1.0.0',
      enabled: true,
      format: text.trimLeft().startsWith('{') ? 'json' : 'yaml',
      diagnostics: const ['包含 episode URL 模板。'],
      importedAtMs: 1,
      updatedAtMs: 2,
    );
    _sourcePackages.removeWhere((item) => item.id == package.id);
    _sourcePackages.insert(0, package);
    _ruleGroups[0] = _ruleGroups[0].copyWith(
      ruleIds: {..._ruleGroups[0].ruleIds, package.id}.toList(),
    );
    return SourceImportResult(
      package: package,
      diagnostics: package.diagnostics,
    );
  }

  @override
  Future<SourceImportResult> importSourceUrl(String url) {
    return importSourceText('id: url-demo\nname: URL Demo\nversion: 1.0.0');
  }

  @override
  Future<List<SourcePackageSummary>> listSourcePackages() async {
    return List.unmodifiable(_sourcePackages);
  }

  @override
  Future<void> setSourcePackageEnabled({
    required String id,
    required bool enabled,
  }) async {
    final index = _sourcePackages.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final item = _sourcePackages[index];
    _sourcePackages[index] = SourcePackageSummary(
      id: item.id,
      name: item.name,
      version: item.version,
      enabled: enabled,
      format: item.format,
      sourceUrl: item.sourceUrl,
      diagnostics: item.diagnostics,
      importedAtMs: item.importedAtMs,
      updatedAtMs: item.updatedAtMs + 1,
    );
  }

  @override
  Future<void> deleteSourcePackage(String id) async {
    _sourcePackages.removeWhere((item) => item.id == id);
  }

  @override
  Future<SourcePackageText?> getSourcePackageText(String id) async {
    final package = _sourcePackages.where((item) => item.id == id).firstOrNull;
    if (package == null) return null;
    return SourcePackageText(
      id: package.id,
      name: package.name,
      format: package.format,
      body:
          'id: ${package.id}\nname: ${package.name}\nversion: ${package.version}\n',
    );
  }

  @override
  Future<List<RuleGroupSummary>> listRuleGroups() async {
    return List.unmodifiable(_ruleGroups);
  }

  @override
  Future<RuleGroupSummary> saveRuleGroup(RuleGroupSummary group) async {
    final index = _ruleGroups.indexWhere((item) => item.id == group.id);
    if (index >= 0) {
      _ruleGroups[index] = group;
    } else {
      _ruleGroups.add(group);
    }
    return group;
  }

  @override
  Future<void> deleteRuleGroup(String id) async {
    _ruleGroups.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<RuleRepositorySubscription>>
  listRuleRepositorySubscriptions() async {
    return List.unmodifiable(_subscriptions);
  }

  @override
  Future<RuleRepositorySubscription> saveRuleRepositorySubscription(
    RuleRepositorySubscription subscription,
  ) async {
    final saved = RuleRepositorySubscription(
      id: subscription.id,
      name: subscription.name,
      url: subscription.url,
      enabled: subscription.enabled,
      updatedAtMs: 3,
    );
    _subscriptions.removeWhere((item) => item.id == saved.id);
    _subscriptions.add(saved);
    return saved;
  }

  @override
  Future<void> deleteRuleRepositorySubscription(String id) async {
    _subscriptions.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<RuleRepositoryIndexEntry>> loadRuleRepositoryIndex(
    RuleRepositorySubscription subscription,
  ) async {
    return const [
      RuleRepositoryIndexEntry(
        name: 'demo',
        version: '1',
        antiCrawlerEnabled: false,
        rawUrl: 'https://example.test/demo.json',
      ),
    ];
  }

  @override
  Future<SourceImportResult> importRepositoryRule({
    required String groupId,
    required RuleRepositoryIndexEntry entry,
  }) {
    return importSourceText(
      'id: ${entry.name}\nname: ${entry.name}\nversion: 1',
    );
  }

  @override
  Future<List<RuleSourceSearchResult>> searchRuleSources({
    required int subjectId,
    required List<String> ruleIds,
  }) async {
    if (_sourceSearchDelay > Duration.zero) {
      await Future<void>.delayed(_sourceSearchDelay);
    }
    final rules = ruleIds.isEmpty ? ['demo'] : ruleIds;
    return [
      for (final ruleId in rules)
        RuleSourceSearchResult(
          ruleId: ruleId,
          ruleName: 'Demo',
          status: 'match',
          elapsedMs: 8,
          candidates: [
            SourceCandidate(
              ruleId: ruleId,
              ruleName: 'Demo',
              sourceItemKey: '$subjectId-demo',
              title: subjectId == secondSubject.id
                  ? secondSubject.displayTitle
                  : subject.displayTitle,
              detailUrl: 'https://example.test/detail/$subjectId',
              confidence: 'exact',
              score: 1,
              matchedKeyword: subject.displayTitle,
            ),
          ],
        ),
    ];
  }

  @override
  Future<EpisodeBindingResolveResult> resolveEpisodeBindings({
    required int subjectId,
    required int episodeId,
    required SourceCandidate candidate,
    required List<SourceCandidate> fallbackCandidates,
  }) async {
    final binding = EpisodeSourceBinding(
      subjectId: subjectId,
      episodeId: episodeId,
      episodeOrder: 1,
      ruleId: candidate.ruleId,
      sourceEpisodeKey: 'e1',
      title: candidate.title,
      playUrl: 'https://example.test/play/$episodeId',
      confidence: 'exact',
    );
    return EpisodeBindingResolveResult(
      bindings: [binding],
      selectedCandidate: candidate,
      selectedBinding: binding,
      attempts: [
        RuleResolveAttempt(
          ruleId: candidate.ruleId,
          status: 'success',
          message: '解析到 1 个剧集绑定',
        ),
      ],
    );
  }

  @override
  Future<EpisodeStreamResolveResult> resolveEpisodeStreams({
    required String ruleId,
    required String playUrl,
    required List<String> fallbackPlayUrls,
    String? refererUrl,
  }) async {
    return EpisodeStreamResolveResult(
      streams: [
        PlayStreamContract(
          id: '$ruleId-stream',
          ruleId: ruleId,
          kind: 'hls',
          url: 'https://example.test/video.m3u8',
          refererUrl: refererUrl,
        ),
      ],
      attempts: [
        RuleResolveAttempt(
          ruleId: ruleId,
          status: 'success',
          message: '解析到 1 条播放流',
        ),
      ],
    );
  }

  @override
  Future<List<FavoriteItem>> listFavorites({CollectionStatus? status}) async {
    return _favorites
        .where((item) => status == null || item.status == status)
        .toList(growable: false);
  }

  @override
  Future<FavoriteItem> saveFavorite({
    required AnimeSubject subject,
    required CollectionStatus status,
  }) async {
    final item = FavoriteItem(subject: subject, status: status, updatedAtMs: 1);
    _favorites.removeWhere((favorite) => favorite.subject.id == subject.id);
    _favorites.insert(0, item);
    return item;
  }

  @override
  Future<void> deleteFavorite(int subjectId) async {
    _favorites.removeWhere((item) => item.subject.id == subjectId);
  }

  @override
  Future<PlaybackProgress> savePlaybackProgress({
    required AnimeSubject subject,
    required AnimeEpisode episode,
    required int positionMs,
    int? durationMs,
  }) async {
    final progress = PlaybackProgress(
      subjectId: subject.id,
      episodeId: episode.id,
      positionMs: positionMs,
      durationMs: durationMs,
      updatedAtMs: positionMs,
    );
    _history.removeWhere(
      (item) => item.subject.id == subject.id && item.episode.id == episode.id,
    );
    _history.insert(
      0,
      WatchHistoryItem(subject: subject, episode: episode, progress: progress),
    );
    return progress;
  }

  @override
  Future<PlaybackProgress?> getPlaybackProgress({
    required int subjectId,
    required int episodeId,
  }) async {
    return _history
        .where(
          (item) =>
              item.subject.id == subjectId && item.episode.id == episodeId,
        )
        .firstOrNull
        ?.progress;
  }

  @override
  Future<List<WatchHistoryItem>> listWatchHistory({int? limit}) async {
    return _history.take(limit ?? _history.length).toList(growable: false);
  }

  @override
  Future<void> deleteWatchHistoryItem({
    required int subjectId,
    required int episodeId,
  }) async {
    _history.removeWhere(
      (item) => item.subject.id == subjectId && item.episode.id == episodeId,
    );
  }

  @override
  Future<void> clearWatchHistory() async {
    _history.clear();
  }

  @override
  Future<List<String>> listSearchHistory() async {
    return List.unmodifiable(_searchHistory);
  }

  @override
  Future<List<String>> saveSearchHistory(List<String> history) async {
    _searchHistory = [
      for (final item in history)
        if (item.trim().isNotEmpty) item.trim(),
    ].take(12).toList(growable: false);
    savedSearchHistory.add(List.of(_searchHistory));
    return List.unmodifiable(_searchHistory);
  }
}

class FakePlayerAdapter implements PlayerAdapter {
  final StreamController<PlayerSnapshot> _controller =
      StreamController<PlayerSnapshot>.broadcast();
  PlayerSnapshot _snapshot = const PlayerSnapshot();
  PlaybackContract? opened;

  @override
  Player? get player => null;

  @override
  PlayerSnapshot get currentSnapshot => _snapshot;

  @override
  Stream<PlayerSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> open(PlaybackContract contract) async {
    opened = contract;
    _emit(
      _snapshot.copyWith(playing: true, duration: const Duration(minutes: 24)),
    );
  }

  @override
  Future<void> pause() async => _emit(_snapshot.copyWith(playing: false));

  @override
  Future<void> play() async => _emit(_snapshot.copyWith(playing: true));

  @override
  Future<void> seek(Duration position) async {
    _emit(_snapshot.copyWith(position: position));
  }

  @override
  Future<void> setMuted(bool muted) async {
    _emit(_snapshot.copyWith(muted: muted));
  }

  @override
  Future<void> setRate(double rate) async {
    _emit(_snapshot.copyWith(rate: rate));
  }

  @override
  Future<void> setVolume(double volume) async {
    _emit(_snapshot.copyWith(volume: volume));
  }

  @override
  Future<void> dispose() => _controller.close();

  void _emit(PlayerSnapshot snapshot) {
    _snapshot = snapshot;
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
  }
}
