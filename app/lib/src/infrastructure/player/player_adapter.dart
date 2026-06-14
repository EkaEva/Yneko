import 'dart:async';

import 'package:media_kit/media_kit.dart';

import '../../shared/domain/index.dart';

class PlayerSnapshot {
  const PlayerSnapshot({
    this.playing = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100,
    this.muted = false,
    this.rate = 1,
    this.error,
  });

  final bool playing;
  final bool buffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool muted;
  final double rate;
  final String? error;

  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0, 1).toDouble();
  }

  PlayerSnapshot copyWith({
    bool? playing,
    bool? buffering,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? muted,
    double? rate,
    String? error,
  }) {
    return PlayerSnapshot(
      playing: playing ?? this.playing,
      buffering: buffering ?? this.buffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
      rate: rate ?? this.rate,
      error: error,
    );
  }
}

abstract interface class PlayerAdapter {
  Player? get player;
  Stream<PlayerSnapshot> get snapshots;
  PlayerSnapshot get currentSnapshot;

  Future<void> open(PlaybackContract contract);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setMuted(bool muted);
  Future<void> setRate(double rate);
  Future<void> dispose();
}

class MediaKitPlayerAdapter implements PlayerAdapter {
  MediaKitPlayerAdapter({Player? player}) : _player = player ?? Player() {
    _subscriptions = [
      _player.stream.playing.listen(
        (value) => _emit(_snapshot.copyWith(playing: value)),
      ),
      _player.stream.buffering.listen(
        (value) => _emit(_snapshot.copyWith(buffering: value)),
      ),
      _player.stream.position.listen(
        (value) => _emit(_snapshot.copyWith(position: value)),
      ),
      _player.stream.duration.listen(
        (value) => _emit(_snapshot.copyWith(duration: value)),
      ),
      _player.stream.volume.listen(
        (value) => _emit(_snapshot.copyWith(volume: value)),
      ),
      _player.stream.rate.listen(
        (value) => _emit(_snapshot.copyWith(rate: value)),
      ),
      _player.stream.error.listen(
        (value) => _emit(_snapshot.copyWith(error: value)),
      ),
    ];
    _controller.add(_snapshot);
  }

  final Player _player;
  final StreamController<PlayerSnapshot> _controller =
      StreamController<PlayerSnapshot>.broadcast();
  late final List<StreamSubscription<Object?>> _subscriptions;
  PlayerSnapshot _snapshot = const PlayerSnapshot();

  @override
  Player get player => _player;

  @override
  Stream<PlayerSnapshot> get snapshots => _controller.stream;

  @override
  PlayerSnapshot get currentSnapshot => _snapshot;

  @override
  Future<void> open(PlaybackContract contract) async {
    _emit(_snapshot.copyWith(buffering: true, error: null));
    await _player.open(Media(contract.url, httpHeaders: contract.headers));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 100));

  @override
  Future<void> setMuted(bool muted) async {
    await _player.setVolume(
      muted ? 0 : (_snapshot.volume <= 0 ? 100 : _snapshot.volume),
    );
    _emit(_snapshot.copyWith(muted: muted));
  }

  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _controller.close();
    await _player.dispose();
  }

  void _emit(PlayerSnapshot snapshot) {
    _snapshot = snapshot;
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
  }
}
