import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/infrastructure/bridge/frb_mappers.dart';
import 'package:yneko/src/infrastructure/bridge/generated/api.dart' as frb;
import 'package:yneko/src/shared/domain/index.dart';

void main() {
  test('maps subject, detail, and episodes from generated bridge models', () {
    final detail = subjectDetailFromFrb(
      const frb.SubjectDetail(
        subject: frb.SubjectSummary(
          id: 400602,
          name: 'Sousou no Frieren',
          nameCn: '葬送的芙莉莲',
          aliases: ['Frieren'],
          coverUrl: 'https://example.test/frieren.jpg',
          summary: '旅途之后的故事。',
          airDate: '2023-09-29',
          ratingScore: 8.8,
          ratingRank: 18,
          tags: ['漫画改', '奇幻'],
          totalEpisodes: 28,
        ),
        episodes: [
          frb.Episode(
            id: 1,
            subjectId: 400602,
            sort: 1,
            title: 'The Journey Ends',
            titleCn: '冒险的结束',
            airDate: '2023-09-29',
          ),
        ],
        isFavorite: true,
        progress: frb.PlaybackProgress(
          subjectId: 400602,
          episodeId: 1,
          positionMs: 42,
          durationMs: 1440,
          updatedAtMs: 2,
        ),
      ),
    );

    expect(detail.subject.id, 400602);
    expect(detail.subject.displayTitle, '葬送的芙莉莲');
    expect(detail.subject.tags, ['漫画改', '奇幻']);
    expect(detail.episodes.single.displayTitle, '冒险的结束');
    expect(detail.isFavorite, isTrue);
    expect(detail.progress?.positionMs, 42);
  });

  test('preserves nullable subject fields from generated bridge models', () {
    final subject = subjectFromFrb(
      const frb.SubjectSummary(
        id: 1,
        name: 'Name only',
        nameCn: null,
        aliases: [],
        coverUrl: null,
        summary: null,
        airDate: null,
        ratingScore: null,
        ratingRank: null,
        tags: [],
        totalEpisodes: 0,
      ),
    );

    expect(subject.displayTitle, 'Name only');
    expect(subject.coverUrl, isNull);
    expect(subject.summary, isNull);
    expect(subject.ratingScore, isNull);
  });

  test('maps ranking response and request filters', () {
    final request = rankingRequestToFrb(
      const AnimeRankingRequest(
        sort: AnimeRankingSort.rank,
        filters: {'地区': '日本'},
        filterGroup: '地区',
        filter: '日本',
        year: 2026,
        season: AnimeSeason.spring,
        keyword: 'mono',
        page: 2,
        limit: 12,
      ),
    );

    expect(request.sort, frb.AnimeRankingSort.rank);
    expect(request.filters, {'地区': '日本'});
    expect(request.season, frb.AnimeSeason.spring);
    expect(request.page, 2);
    expect(request.limit, 12);

    final response = rankingResponseFromFrb(
      const frb.AnimeRankingResponse(
        items: [],
        page: 2,
        hasNext: true,
        applied: frb.AnimeRankingApplied(
          sort: 'rank',
          filters: {'地区': '日本'},
          filterGroup: '地区',
          filter: '日本',
          year: 2026,
          season: 'spring',
          keyword: 'mono',
          page: 2,
          limit: 12,
        ),
      ),
    );

    expect(response.hasNext, isTrue);
    expect(response.applied.sort, 'rank');
    expect(response.applied.filters, {'地区': '日本'});
    expect(response.applied.season, 'spring');
  });

  test('maps calendar, browse request, and playback headers', () {
    final day = calendarDayFromFrb(
      const frb.BangumiCalendarDay(
        weekdayId: 7,
        weekdayCn: '星期日',
        weekdayEn: 'Sun',
        items: [],
      ),
    );
    expect(day.weekdayId, 7);
    expect(day.items, isEmpty);

    final browse = browseRequestToFrb(
      const BangumiBrowseRequest(
        sort: BangumiBrowseSort.date,
        year: 2025,
        month: 4,
        limit: 24,
        offset: 48,
      ),
    );
    expect(browse.sort, frb.BangumiBrowseSort.date);
    expect(browse.offset, 48);

    final playback = playbackFromFrb(
      const frb.PlaybackCandidate(
        id: 'p1',
        subjectId: 1,
        episodeId: 2,
        sourcePackageId: 'local',
        title: 'Episode',
        url: 'https://example.test/video.m3u8',
        headers: [
          frb.PlaybackHeader(name: 'Referer', value: 'https://example.test'),
        ],
      ),
    );
    expect(playback.headers, {'Referer': 'https://example.test'});
  });

  test('maps favorites, progress, history, and collection status', () {
    final subject = const frb.SubjectSummary(
      id: 400602,
      name: 'Sousou no Frieren',
      nameCn: '葬送的芙莉莲',
      aliases: [],
      coverUrl: null,
      summary: null,
      airDate: null,
      ratingScore: null,
      ratingRank: null,
      tags: [],
      totalEpisodes: 28,
    );
    final episode = const frb.Episode(
      id: 40060201,
      subjectId: 400602,
      sort: 1,
      title: 'The Journey Ends',
      titleCn: '冒险的结束',
      airDate: null,
    );
    final progress = const frb.PlaybackProgress(
      subjectId: 400602,
      episodeId: 40060201,
      positionMs: 1234,
      durationMs: 1440000,
      updatedAtMs: 9,
    );

    final favorite = favoriteItemFromFrb(
      frb.FavoriteItem(
        subject: subject,
        status: frb.CollectionStatus.watched,
        updatedAtMs: 9,
      ),
    );
    expect(favorite.subject.displayTitle, '葬送的芙莉莲');
    expect(favorite.status, CollectionStatus.watched);

    final history = watchHistoryItemFromFrb(
      frb.WatchHistoryItem(
        subject: subject,
        episode: episode,
        progress: progress,
      ),
    );
    expect(history.episode.displayTitle, '冒险的结束');
    expect(history.progress.durationMs, 1440000);
    expect(
      collectionStatusToFrb(CollectionStatus.paused),
      frb.CollectionStatus.paused,
    );
  });
}
