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
}
