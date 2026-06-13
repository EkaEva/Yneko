import '../../domain/models.dart';

abstract interface class YnekoBackend {
  Future<List<AnimeSubject>> searchSubjects(String query, int page);

  Future<List<PlaybackContract>> resolvePlayback({
    required int subjectId,
    required int episodeId,
  });
}

class FrbYnekoBackend implements YnekoBackend {
  const FrbYnekoBackend();

  @override
  Future<List<AnimeSubject>> searchSubjects(String query, int page) async {
    throw UnimplementedError('Generated flutter_rust_bridge binding is not wired yet.');
  }

  @override
  Future<List<PlaybackContract>> resolvePlayback({
    required int subjectId,
    required int episodeId,
  }) async {
    throw UnimplementedError('Generated flutter_rust_bridge binding is not wired yet.');
  }
}

