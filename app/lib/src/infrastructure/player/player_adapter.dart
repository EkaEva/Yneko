import 'package:media_kit/media_kit.dart';

import '../../domain/models.dart';

abstract interface class PlayerAdapter {
  Future<void> open(PlaybackContract contract);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

class MediaKitPlayerAdapter implements PlayerAdapter {
  MediaKitPlayerAdapter({Player? player}) : _player = player ?? Player();

  final Player _player;

  @override
  Future<void> open(PlaybackContract contract) {
    return _player.open(Media(contract.url, httpHeaders: contract.headers));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}

