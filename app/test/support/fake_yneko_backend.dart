import 'package:yneko/src/infrastructure/bridge/yneko_backend.dart';
import 'package:yneko/src/shared/domain/index.dart';

class FakeYnekoBackend implements YnekoBackend {
  const FakeYnekoBackend();

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

  @override
  Future<List<AnimeSubject>> searchSubjects(String query, int page) async {
    return const [subject, secondSubject];
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
    );
  }

  @override
  Future<List<BangumiCalendarDay>> getCalendar() async {
    return const [
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
    return AnimeRankingResponse(
      items: request.sort == AnimeRankingSort.rank
          ? const [subject, secondSubject]
          : const [secondSubject, subject],
      page: request.page,
      hasNext: false,
      applied: AnimeRankingApplied(
        sort: request.sort.name,
        filters: request.filters,
        page: request.page,
        limit: request.limit,
      ),
    );
  }

  @override
  Future<List<AnimeSubject>> browseSubjects(
    BangumiBrowseRequest request,
  ) async {
    return const [subject, secondSubject];
  }

  @override
  Future<List<PlaybackContract>> resolvePlayback({
    required int subjectId,
    required int episodeId,
  }) async {
    return const [];
  }
}
