import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/bridge/yneko_backend.dart';
import '../../../infrastructure/player/player_adapter.dart';
import '../../../shared/domain/index.dart';

final watchPlayerAdapterFactoryProvider =
    Provider<PlayerAdapter Function(WatchPlaybackKey)>((ref) {
      return (_) => MediaKitPlayerAdapter();
    });

final watchSubjectDetailProvider = FutureProvider.family<SubjectDetail, int>((
  ref,
  subjectId,
) async {
  return ref.watch(ynekoBackendProvider).getSubjectDetail(subjectId);
});

String watchSubjectTitle(AnimeSubject subject) => subject.displayTitle;

String watchSubjectScoreLabel(AnimeSubject subject) {
  if (subject.ratingScore != null) {
    return '评分 ${subject.ratingScore!.toStringAsFixed(1)}';
  }
  if (subject.ratingRank != null) {
    return 'Rank ${subject.ratingRank}';
  }
  return '评分 --';
}

String watchSubjectAirDateLabel(AnimeSubject subject) {
  final value = subject.airDate?.trim();
  return value == null || value.isEmpty ? '开播未知' : value;
}

String watchSubjectEpisodeCountLabel(
  AnimeSubject subject,
  List<AnimeEpisode> episodes,
) {
  final total = subject.totalEpisodes > 0
      ? subject.totalEpisodes
      : episodes.length;
  return total > 0 ? '$total 话' : '集数未知';
}

String watchSubjectTagLabel(AnimeSubject subject) {
  return subject.tags.isEmpty ? 'Bangumi' : subject.tags.take(2).join(' · ');
}

Color watchSubjectCoverColor(int subjectId) {
  final hue = (subjectId.abs() * 37) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.38, 0.42).toColor();
}

Color watchSubjectAccentColor(int subjectId) {
  final hue = ((subjectId.abs() * 37) + 42) % 360;
  return HSLColor.fromAHSL(1, hue.toDouble(), 0.44, 0.56).toColor();
}

final watchPlayerControllerProvider = NotifierProvider.autoDispose
    .family<WatchPlayerController, WatchPlaybackState, WatchPlaybackKey>(
      WatchPlayerController.new,
    );

class WatchPlaybackKey {
  const WatchPlaybackKey({required this.subjectId, required this.episodeId});

  final int subjectId;
  final int episodeId;

  @override
  bool operator ==(Object other) {
    return other is WatchPlaybackKey &&
        other.subjectId == subjectId &&
        other.episodeId == episodeId;
  }

  @override
  int get hashCode => Object.hash(subjectId, episodeId);
}

class WatchPlaybackState {
  const WatchPlaybackState({
    required this.player,
    this.sourceResults = const [],
    this.selectedCandidate,
    this.bindings = const [],
    this.bindingAttempts = const [],
    this.streamAttempts = const [],
    this.playerSnapshot = const PlayerSnapshot(),
    this.searching = false,
    this.binding = false,
    this.opening = false,
    this.error,
  });

  final PlayerAdapter player;
  final List<RuleSourceSearchResult> sourceResults;
  final SourceCandidate? selectedCandidate;
  final List<EpisodeSourceBinding> bindings;
  final List<RuleResolveAttempt> bindingAttempts;
  final List<RuleResolveAttempt> streamAttempts;
  final PlayerSnapshot playerSnapshot;
  final bool searching;
  final bool binding;
  final bool opening;
  final String? error;

  List<SourceCandidate> get candidates {
    return sourceResults.expand((result) => result.candidates).toList();
  }

  WatchPlaybackState copyWith({
    List<RuleSourceSearchResult>? sourceResults,
    SourceCandidate? selectedCandidate,
    List<EpisodeSourceBinding>? bindings,
    List<RuleResolveAttempt>? bindingAttempts,
    List<RuleResolveAttempt>? streamAttempts,
    PlayerSnapshot? playerSnapshot,
    bool? searching,
    bool? binding,
    bool? opening,
    String? error,
    bool clearSelectedCandidate = false,
  }) {
    return WatchPlaybackState(
      player: player,
      sourceResults: sourceResults ?? this.sourceResults,
      selectedCandidate: clearSelectedCandidate
          ? null
          : selectedCandidate ?? this.selectedCandidate,
      bindings: bindings ?? this.bindings,
      bindingAttempts: bindingAttempts ?? this.bindingAttempts,
      streamAttempts: streamAttempts ?? this.streamAttempts,
      playerSnapshot: playerSnapshot ?? this.playerSnapshot,
      searching: searching ?? this.searching,
      binding: binding ?? this.binding,
      opening: opening ?? this.opening,
      error: error,
    );
  }
}

class WatchPlayerController extends Notifier<WatchPlaybackState> {
  WatchPlayerController(this._key);

  late final YnekoBackend _backend;
  final WatchPlaybackKey _key;
  StreamSubscription<PlayerSnapshot>? _subscription;
  PlayerAdapter? _player;

  @override
  WatchPlaybackState build() {
    _backend = ref.watch(ynekoBackendProvider);
    final player = ref.watch(watchPlayerAdapterFactoryProvider)(_key);
    _player = player;
    _subscription = player.snapshots.listen(
      (snapshot) => state = state.copyWith(playerSnapshot: snapshot),
    );
    ref.onDispose(_disposePlayer);
    Future<void>.microtask(searchSources);
    return WatchPlaybackState(player: player);
  }

  Future<void> searchSources({List<String> ruleIds = const []}) async {
    state = state.copyWith(
      searching: true,
      error: null,
      sourceResults: const [],
      bindings: const [],
      bindingAttempts: const [],
      streamAttempts: const [],
      clearSelectedCandidate: true,
    );
    try {
      final results = await _backend.searchRuleSources(
        subjectId: _key.subjectId,
        ruleIds: ruleIds,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        searching: false,
        sourceResults: results,
        error: null,
      );
      if (state.candidates.isNotEmpty) {
        await openCandidate(state.candidates.first);
      }
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(searching: false, error: error.toString());
    }
  }

  Future<void> openCandidate(SourceCandidate candidate) async {
    state = state.copyWith(
      binding: true,
      opening: true,
      selectedCandidate: candidate,
      error: null,
    );
    try {
      final fallbackCandidates = state.candidates
          .where((item) => item.detailUrl != candidate.detailUrl)
          .toList();
      final bindingResult = await _backend.resolveEpisodeBindings(
        subjectId: _key.subjectId,
        episodeId: _key.episodeId,
        candidate: candidate,
        fallbackCandidates: fallbackCandidates,
      );
      final binding = bindingResult.selectedBinding;
      if (binding == null) {
        throw StateError('当前规则没有可匹配集数');
      }
      final streamResult = await _backend.resolveEpisodeStreams(
        ruleId: binding.ruleId,
        playUrl: binding.playUrl,
        fallbackPlayUrls: binding.fallbackPlayUrls,
        refererUrl: binding.refererUrl,
      );
      final stream = streamResult.streams.firstOrNull;
      if (stream == null) {
        throw StateError('没有解析到可播放地址');
      }
      await state.player.open(
        stream.asPlaybackContract(
          subjectId: _key.subjectId,
          episodeId: _key.episodeId,
          title: binding.title,
        ),
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        binding: false,
        opening: false,
        selectedCandidate: candidate,
        bindings: bindingResult.bindings,
        bindingAttempts: bindingResult.attempts,
        streamAttempts: streamResult.attempts,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        binding: false,
        opening: false,
        error: error.toString(),
      );
    }
  }

  Future<void> togglePlay() {
    return state.playerSnapshot.playing
        ? state.player.pause()
        : state.player.play();
  }

  Future<void> seekFraction(double value) {
    final duration = state.playerSnapshot.duration;
    if (duration.inMilliseconds <= 0) return Future.value();
    final target = (duration.inMilliseconds * value.clamp(0, 1)).round();
    return state.player.seek(Duration(milliseconds: target));
  }

  Future<void> setVolume(double value) => state.player.setVolume(value);

  Future<void> toggleMute() {
    return state.player.setMuted(!state.playerSnapshot.muted);
  }

  Future<void> setRate(double value) => state.player.setRate(value);

  Future<void> _disposePlayer() async {
    await _subscription?.cancel();
    await _player?.dispose();
  }
}
