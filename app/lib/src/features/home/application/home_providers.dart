import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/bridge/yneko_backend.dart';
import '../../../shared/domain/index.dart';

const homeRecommendationLimit = 24;

final homeRecommendationsProvider = FutureProvider<List<AnimeSubject>>((
  ref,
) async {
  final backend = ref.watch(ynekoBackendProvider);
  final response = await backend.getAnimeRanking(
    const AnimeRankingRequest(
      sort: AnimeRankingSort.heat,
      page: 1,
      limit: homeRecommendationLimit,
    ),
  );
  return response.items;
});

final homeCalendarProvider = FutureProvider<List<BangumiCalendarDay>>((
  ref,
) async {
  return ref.watch(ynekoBackendProvider).getCalendar();
});

class RankingSortController extends Notifier<AnimeRankingSort> {
  @override
  AnimeRankingSort build() => AnimeRankingSort.heat;

  void setSort(AnimeRankingSort sort) {
    state = sort;
  }
}

final rankingSortProvider =
    NotifierProvider<RankingSortController, AnimeRankingSort>(
      RankingSortController.new,
    );

final homeRankingProvider = FutureProvider<AnimeRankingResponse>((ref) async {
  final backend = ref.watch(ynekoBackendProvider);
  final sort = ref.watch(rankingSortProvider);
  return backend.getAnimeRanking(
    AnimeRankingRequest(sort: sort, page: 1, limit: homeRecommendationLimit),
  );
});

class ScheduleDayController extends Notifier<int> {
  @override
  int build() => DateTime.now().weekday;

  void setDay(int day) {
    state = day.clamp(1, 7);
  }
}

final scheduleDayProvider = NotifierProvider<ScheduleDayController, int>(
  ScheduleDayController.new,
);

List<AnimeSubject> subjectsForScheduleDay({
  required List<BangumiCalendarDay> days,
  required int weekday,
}) {
  final normalizedWeekday = weekday.clamp(1, 7);
  return days
      .where((day) => day.weekdayId == normalizedWeekday)
      .expand((day) => day.items)
      .toList();
}

UiAnimeCard subjectToUiCard(AnimeSubject subject) {
  final title = subject.displayTitle;
  final subtitleParts = [
    if (subject.airDate != null && subject.airDate!.isNotEmpty)
      subject.airDate!,
    if (subject.totalEpisodes > 0) '${subject.totalEpisodes} 话',
    if (subject.tags.isNotEmpty) subject.tags.take(2).join(' · '),
  ];
  final subtitle = subtitleParts.isEmpty
      ? 'Bangumi #${subject.id}'
      : subtitleParts.join(' · ');
  final score =
      subject.ratingScore?.toStringAsFixed(1) ??
      (subject.ratingRank == null ? '--' : '#${subject.ratingRank}');
  final colorSeed = subject.id.abs();
  final hue = (colorSeed * 37) % 360;
  final coverColor = HSLColor.fromAHSL(1, hue.toDouble(), 0.38, 0.42).toColor();
  final accent = HSLColor.fromAHSL(
    1,
    ((hue + 42) % 360).toDouble(),
    0.44,
    0.56,
  ).toColor();

  return UiAnimeCard(
    id: subject.id,
    title: title,
    subtitle: subtitle,
    score: score,
    coverColor: coverColor,
    accent: accent,
    coverUrl: subject.coverUrl,
    summary: subject.summary ?? '',
  );
}

List<UiAnimeCard> subjectsToUiCards(List<AnimeSubject> subjects) {
  return subjects.map(subjectToUiCard).toList(growable: false);
}
