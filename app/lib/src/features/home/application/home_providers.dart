import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/bridge/yneko_backend.dart';
import '../../../shared/domain/index.dart';

const homeRecommendationLimit = 24;
const homeRankingPageSize = 24;
const homeRankingMaxPage = 20;
const homeScheduleMinYear = 2015;
const homeWeekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

const rankingSortOptions = [
  RankingSortOption('排名', AnimeRankingSort.rank),
  RankingSortOption('热度', AnimeRankingSort.heat),
  RankingSortOption('收藏', AnimeRankingSort.collect),
  RankingSortOption('日期', AnimeRankingSort.date),
  RankingSortOption('名称', AnimeRankingSort.name),
];

const rankingRegionOptions = [
  RankingFilterOption('全部', ''),
  RankingFilterOption('日本', '日本'),
  RankingFilterOption('国产', '中国'),
  RankingFilterOption('欧美', '欧美'),
];

const rankingTypeOptions = [
  RankingFilterOption('全部', ''),
  RankingFilterOption('科幻', '科幻'),
  RankingFilterOption('喜剧', '喜剧'),
  RankingFilterOption('同人', '同人'),
  RankingFilterOption('百合', '百合'),
  RankingFilterOption('校园', '校园'),
  RankingFilterOption('惊悚', '惊悚'),
  RankingFilterOption('后宫', '后宫'),
  RankingFilterOption('机战', '机战'),
  RankingFilterOption('悬疑', '悬疑'),
  RankingFilterOption('恋爱', '恋爱'),
  RankingFilterOption('奇幻', '奇幻'),
  RankingFilterOption('推理', '推理'),
  RankingFilterOption('运动', '运动'),
  RankingFilterOption('耽美', '耽美'),
  RankingFilterOption('音乐', '音乐'),
  RankingFilterOption('战斗', '战斗'),
  RankingFilterOption('冒险', '冒险'),
  RankingFilterOption('亲子', '亲子'),
  RankingFilterOption('穿越', '穿越'),
  RankingFilterOption('玄幻', '玄幻'),
  RankingFilterOption('乙女', '乙女'),
  RankingFilterOption('恐怖', '恐怖'),
  RankingFilterOption('历史', '历史'),
  RankingFilterOption('日常', '日常'),
  RankingFilterOption('剧情', '剧情'),
  RankingFilterOption('武侠', '武侠'),
  RankingFilterOption('美食', '美食'),
  RankingFilterOption('职场', '职场'),
];

const rankingSourceOptions = [
  RankingFilterOption('全部', ''),
  RankingFilterOption('原创', '原创'),
  RankingFilterOption('漫画改', '漫画改'),
  RankingFilterOption('游戏改', '游戏改'),
  RankingFilterOption('小说改', '小说改'),
  RankingFilterOption('动画改', '动画改'),
  RankingFilterOption('影视改', '影视改'),
  RankingFilterOption('轻小说改', '轻小说改'),
];

const rankingCategoryOptions = [
  RankingFilterOption('全部', ''),
  RankingFilterOption('TV', 'TV'),
  RankingFilterOption('WEB', 'WEB'),
  RankingFilterOption('OVA', 'OVA'),
  RankingFilterOption('剧场版', '剧场版'),
  RankingFilterOption('动态漫画', '动态漫画'),
  RankingFilterOption('其他', '其他'),
];

const rankingSeasonOptions = [
  RankingSeasonOption('季度', null),
  RankingSeasonOption('1月', AnimeSeason.winter),
  RankingSeasonOption('4月', AnimeSeason.spring),
  RankingSeasonOption('7月', AnimeSeason.summer),
  RankingSeasonOption('10月', AnimeSeason.autumn),
];

const scheduleSeasonOptions = [
  ScheduleSeasonOption('全年', null),
  ScheduleSeasonOption('1月', 1),
  ScheduleSeasonOption('4月', 4),
  ScheduleSeasonOption('7月', 7),
  ScheduleSeasonOption('10月', 10),
];

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

@immutable
class RankingSortOption {
  const RankingSortOption(this.label, this.value);

  final String label;
  final AnimeRankingSort value;
}

@immutable
class RankingFilterOption {
  const RankingFilterOption(this.label, this.value);

  final String label;
  final String value;
}

@immutable
class RankingSeasonOption {
  const RankingSeasonOption(this.label, this.value);

  final String label;
  final AnimeSeason? value;
}

@immutable
class ScheduleSeasonOption {
  const ScheduleSeasonOption(this.label, this.seasonStartMonth);

  final String label;
  final int? seasonStartMonth;
}

@immutable
class HomeRankingFilters {
  const HomeRankingFilters({
    this.sort = AnimeRankingSort.heat,
    this.filters = const {},
    this.filterGroup,
    this.filter,
    this.year,
    this.season,
  });

  final AnimeRankingSort sort;
  final Map<String, String> filters;
  final String? filterGroup;
  final String? filter;
  final int? year;
  final AnimeSeason? season;

  HomeRankingFilters copyWith({
    AnimeRankingSort? sort,
    Map<String, String>? filters,
    Object? filterGroup = _unchanged,
    Object? filter = _unchanged,
    Object? year = _unchanged,
    Object? season = _unchanged,
  }) {
    return HomeRankingFilters(
      sort: sort ?? this.sort,
      filters: filters ?? this.filters,
      filterGroup: identical(filterGroup, _unchanged)
          ? this.filterGroup
          : filterGroup as String?,
      filter: identical(filter, _unchanged) ? this.filter : filter as String?,
      year: identical(year, _unchanged) ? this.year : year as int?,
      season: identical(season, _unchanged)
          ? this.season
          : season as AnimeSeason?,
    );
  }

  String valueFor(String group) => filters[group] ?? '';
}

@immutable
class ScheduleArchive {
  const ScheduleArchive({required this.year, this.seasonStartMonth});

  final int year;
  final int? seasonStartMonth;

  ScheduleArchive copyWith({int? year, Object? seasonStartMonth = _unchanged}) {
    return ScheduleArchive(
      year: year ?? this.year,
      seasonStartMonth: identical(seasonStartMonth, _unchanged)
          ? this.seasonStartMonth
          : seasonStartMonth as int?,
    );
  }
}

@immutable
class HomeRankingState {
  const HomeRankingState({
    this.subjects = const [],
    this.applied,
    this.page = 1,
    this.hasNext = false,
    this.loadingMore = false,
    this.appendError = '',
  });

  final List<AnimeSubject> subjects;
  final AnimeRankingApplied? applied;
  final int page;
  final bool hasNext;
  final bool loadingMore;
  final String appendError;

  HomeRankingState copyWith({
    List<AnimeSubject>? subjects,
    Object? applied = _unchanged,
    int? page,
    bool? hasNext,
    bool? loadingMore,
    String? appendError,
  }) {
    return HomeRankingState(
      subjects: subjects ?? this.subjects,
      applied: identical(applied, _unchanged)
          ? this.applied
          : applied as AnimeRankingApplied?,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      loadingMore: loadingMore ?? this.loadingMore,
      appendError: appendError ?? this.appendError,
    );
  }
}

@immutable
class HomeScheduleState {
  const HomeScheduleState({
    required this.archive,
    required this.showingCurrentSchedule,
    required this.days,
  });

  final ScheduleArchive archive;
  final bool showingCurrentSchedule;
  final List<ScheduleDay> days;
}

@immutable
class ScheduleDay {
  const ScheduleDay({
    required this.weekday,
    required this.label,
    this.items = const [],
  });

  final int weekday;
  final String label;
  final List<AnimeSubject> items;
}

class HomeRankingFiltersController extends Notifier<HomeRankingFilters> {
  @override
  HomeRankingFilters build() => const HomeRankingFilters();

  void setSort(AnimeRankingSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setFilter(String group, String value) {
    final next = {...state.filters};
    if (value.trim().isEmpty) {
      next.remove(group);
    } else {
      next[group] = value.trim();
    }
    final primary = _primaryRankingFilter(next);
    state = state.copyWith(
      filters: next,
      filterGroup: primary?.group,
      filter: primary?.value,
    );
  }

  void setYear(int? year) {
    state = state.copyWith(year: year);
  }

  void setSeason(AnimeSeason? season) {
    state = state.copyWith(
      season: season,
      year: season == null ? state.year : state.year ?? DateTime.now().year,
    );
  }
}

final homeRankingFiltersProvider =
    NotifierProvider<HomeRankingFiltersController, HomeRankingFilters>(
      HomeRankingFiltersController.new,
    );

class RankingMoreOpenController extends Notifier<bool> {
  @override
  bool build() => false;

  void setOpen(bool open) {
    state = open;
  }

  void toggle() {
    state = !state;
  }
}

final rankingMoreOpenProvider =
    NotifierProvider<RankingMoreOpenController, bool>(
      RankingMoreOpenController.new,
    );

class HomeRankingController extends AsyncNotifier<HomeRankingState> {
  var _requestId = 0;

  @override
  Future<HomeRankingState> build() async {
    final filters = ref.watch(homeRankingFiltersProvider);
    final requestId = ++_requestId;
    final response = await _load(filters, page: 1);
    if (requestId != _requestId) return const HomeRankingState();
    return _stateFromResponse(response, appendTo: const []);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        state.isLoading ||
        current.loadingMore ||
        !current.hasNext ||
        current.page >= homeRankingMaxPage) {
      return;
    }

    final requestId = ++_requestId;
    final loadingState = current.copyWith(loadingMore: true, appendError: '');
    state = AsyncData(loadingState);

    try {
      final response = await _load(
        ref.read(homeRankingFiltersProvider),
        page: current.page + 1,
      );
      if (requestId != _requestId) return;
      state = AsyncData(
        _stateFromResponse(response, appendTo: current.subjects),
      );
    } catch (error) {
      if (requestId != _requestId) return;
      state = AsyncData(
        loadingState.copyWith(
          loadingMore: false,
          appendError: error.toString(),
        ),
      );
    }
  }

  Future<AnimeRankingResponse> _load(
    HomeRankingFilters filters, {
    required int page,
  }) {
    return ref
        .read(ynekoBackendProvider)
        .getAnimeRanking(rankingRequestFromFilters(filters, page: page));
  }

  HomeRankingState _stateFromResponse(
    AnimeRankingResponse response, {
    required List<AnimeSubject> appendTo,
  }) {
    final subjects = appendTo.isEmpty
        ? response.items
        : uniqueSubjects([...appendTo, ...response.items]);
    return HomeRankingState(
      subjects: subjects,
      applied: response.applied,
      page: response.page,
      hasNext: response.hasNext && response.page < homeRankingMaxPage,
    );
  }
}

final homeRankingProvider =
    AsyncNotifierProvider<HomeRankingController, HomeRankingState>(
      HomeRankingController.new,
    );

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

class ScheduleFiltersOpenController extends Notifier<bool> {
  @override
  bool build() => false;

  void setOpen(bool open) {
    state = open;
  }

  void toggle() {
    state = !state;
  }
}

final scheduleFiltersOpenProvider =
    NotifierProvider<ScheduleFiltersOpenController, bool>(
      ScheduleFiltersOpenController.new,
    );

class ScheduleArchiveController extends Notifier<ScheduleArchive> {
  @override
  ScheduleArchive build() {
    final now = DateTime.now();
    return ScheduleArchive(
      year: now.year,
      seasonStartMonth: currentQuarterStartMonth(now),
    );
  }

  void setArchive(ScheduleArchive archive) {
    state = ScheduleArchive(
      year: archive.year.clamp(homeScheduleMinYear, DateTime.now().year),
      seasonStartMonth: _normalizeSeasonStartMonth(archive.seasonStartMonth),
    );
  }

  void setYear(int year) {
    setArchive(state.copyWith(year: year));
  }

  void setSeasonStartMonth(int? seasonStartMonth) {
    setArchive(state.copyWith(seasonStartMonth: seasonStartMonth));
  }
}

final scheduleArchiveProvider =
    NotifierProvider<ScheduleArchiveController, ScheduleArchive>(
      ScheduleArchiveController.new,
    );

final homeScheduleProvider = FutureProvider<HomeScheduleState>((ref) async {
  final archive = ref.watch(scheduleArchiveProvider);
  final current = isCurrentQuarterArchive(archive);
  final subjects = current
      ? null
      : await fetchScheduleArchiveSubjects(
          archive: archive,
          backend: ref.watch(ynekoBackendProvider),
        );
  final days = current
      ? calendarDaysToScheduleDays(await ref.watch(homeCalendarProvider.future))
      : buildScheduleDays(subjects!);
  return HomeScheduleState(
    archive: archive,
    showingCurrentSchedule: current,
    days: days,
  );
});

AnimeRankingRequest rankingRequestFromFilters(
  HomeRankingFilters filters, {
  int page = 1,
  int limit = homeRankingPageSize,
}) {
  final primary = _primaryRankingFilter(filters.filters);
  return AnimeRankingRequest(
    sort: filters.sort,
    filters: filters.filters,
    filterGroup: primary?.group,
    filter: primary == null
        ? null
        : _normalizeRankingBrowserFilter(primary.group, primary.value),
    year: filters.year,
    season: filters.season,
    page: page,
    limit: limit,
  );
}

String rankingResponseSummary(
  AnimeRankingApplied? applied,
  HomeRankingFilters fallback,
) {
  if (applied == null) return rankingFilterSummary(fallback);
  return rankingFilterSummary(
    HomeRankingFilters(
      sort: _sortFromApplied(applied.sort) ?? fallback.sort,
      filters: fallback.filters,
      filterGroup: fallback.filterGroup,
      filter: fallback.filter,
      year: applied.year ?? fallback.year,
      season: _seasonFromApplied(applied.season) ?? fallback.season,
    ),
  );
}

String rankingFilterSummary(HomeRankingFilters filters) {
  final values = _orderedRankingFilterValues(filters.filters);
  final filterLabel = values.isEmpty ? '全部动画' : values.join(' · ');
  final year = filters.year;
  final season = _seasonLabel(filters.season);
  final suffix = year == null
      ? ''
      : ' · $year${season == null ? '' : ' $season'}';
  return '${_sortLabel(filters.sort)} · $filterLabel$suffix';
}

List<int> rankingYears([DateTime? now]) {
  final currentYear = (now ?? DateTime.now()).year;
  return [
    for (var year = currentYear; year >= homeScheduleMinYear; year--) year,
  ];
}

List<AnimeSubject> subjectsForScheduleDay({
  required List<ScheduleDay> days,
  required int weekday,
}) {
  final normalizedWeekday = weekday.clamp(1, 7);
  return days
      .where((day) => day.weekday == normalizedWeekday)
      .expand((day) => day.items)
      .toList();
}

List<ScheduleDay> calendarDaysToScheduleDays(List<BangumiCalendarDay> days) {
  final result = _emptyScheduleDays();
  for (final day in days) {
    if (day.weekdayId < 1 || day.weekdayId > 7) continue;
    result[day.weekdayId - 1] = ScheduleDay(
      weekday: day.weekdayId,
      label: day.weekdayCn.isEmpty
          ? homeWeekdayLabels[day.weekdayId - 1]
          : day.weekdayCn,
      items: [...day.items]..sort(_compareByAirDate),
    );
  }
  return result;
}

List<ScheduleDay> buildScheduleDays(List<AnimeSubject> subjects) {
  final buckets = [for (var index = 0; index < 7; index++) <AnimeSubject>[]];
  for (final subject in subjects) {
    buckets[_weekdayFromAirDate(subject.airDate) - 1].add(subject);
  }
  return [
    for (var index = 0; index < 7; index++)
      ScheduleDay(
        weekday: index + 1,
        label: homeWeekdayLabels[index],
        items: buckets[index]..sort(_compareByAirDate),
      ),
  ];
}

Future<List<AnimeSubject>> fetchScheduleArchiveSubjects({
  required ScheduleArchive archive,
  required YnekoBackend backend,
}) async {
  final chunks = await Future.wait(
    browseRequestsFromScheduleArchive(
      archive,
    ).map((request) => backend.browseSubjects(request)),
  );
  return uniqueSubjects(chunks.expand((chunk) => chunk).toList());
}

List<BangumiBrowseRequest> browseRequestsFromScheduleArchive(
  ScheduleArchive archive,
) {
  const baseLimit = 50;
  if (archive.seasonStartMonth == null) {
    return [
      BangumiBrowseRequest(
        sort: BangumiBrowseSort.date,
        year: archive.year,
        limit: baseLimit,
        offset: 0,
      ),
    ];
  }
  return [
    for (
      var month = archive.seasonStartMonth!;
      month < archive.seasonStartMonth! + 3;
      month++
    )
      BangumiBrowseRequest(
        sort: BangumiBrowseSort.date,
        year: archive.year,
        month: month,
        limit: baseLimit,
        offset: 0,
      ),
  ];
}

bool isCurrentQuarterArchive(ScheduleArchive archive, [DateTime? now]) {
  final current = now ?? DateTime.now();
  return archive.year == current.year &&
      archive.seasonStartMonth == currentQuarterStartMonth(current);
}

int currentQuarterStartMonth([DateTime? now]) {
  final month = (now ?? DateTime.now()).month;
  if (month < 4) return 1;
  if (month < 7) return 4;
  if (month < 10) return 7;
  return 10;
}

String scheduleArchiveTitle(ScheduleArchive archive) {
  final season = archive.seasonStartMonth;
  return season == null ? '${archive.year}年新番' : '${archive.year}年$season月新番';
}

List<AnimeSubject> uniqueSubjects(List<AnimeSubject> subjects) {
  final seen = <int>{};
  return [
    for (final subject in subjects)
      if (seen.add(subject.id)) subject,
  ];
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

const _unchanged = Object();

({String group, String value})? _primaryRankingFilter(
  Map<String, String> values,
) {
  for (final group in const ['category', 'type', 'source', 'region']) {
    final value = values[group]?.trim();
    if (value != null && value.isNotEmpty) return (group: group, value: value);
  }
  return null;
}

String _normalizeRankingBrowserFilter(String group, String value) {
  if (group != 'category') return value;
  return switch (value) {
    'TV' || 'tv' => 'tv',
    'WEB' || 'web' => 'web',
    'OVA' || 'ova' => 'ova',
    '剧场版' => 'movie',
    '动态漫画' => 'anime_comic',
    '其他' => 'misc',
    _ => value,
  };
}

List<String> _orderedRankingFilterValues(Map<String, String> values) {
  final ordered = <String>[];
  for (final group in const ['region', 'type', 'source', 'category']) {
    final value = values[group]?.trim();
    if (value != null && value.isNotEmpty) ordered.add(value);
  }
  for (final entry in values.entries) {
    if (!const ['region', 'type', 'source', 'category'].contains(entry.key) &&
        entry.value.trim().isNotEmpty) {
      ordered.add(entry.value.trim());
    }
  }
  return ordered;
}

AnimeRankingSort? _sortFromApplied(String value) {
  for (final sort in AnimeRankingSort.values) {
    if (sort.name == value) return sort;
  }
  return null;
}

AnimeSeason? _seasonFromApplied(String? value) {
  if (value == null) return null;
  for (final season in AnimeSeason.values) {
    if (season.name == value) return season;
  }
  return null;
}

String _sortLabel(AnimeRankingSort sort) {
  return switch (sort) {
    AnimeRankingSort.rank => '排名',
    AnimeRankingSort.heat => '热度',
    AnimeRankingSort.collect => '收藏',
    AnimeRankingSort.date => '日期',
    AnimeRankingSort.name => '名称',
  };
}

String? _seasonLabel(AnimeSeason? season) {
  return switch (season) {
    AnimeSeason.winter => '1月',
    AnimeSeason.spring => '4月',
    AnimeSeason.summer => '7月',
    AnimeSeason.autumn => '10月',
    null => null,
  };
}

List<ScheduleDay> _emptyScheduleDays() {
  return [
    for (var index = 0; index < 7; index++)
      ScheduleDay(weekday: index + 1, label: homeWeekdayLabels[index]),
  ];
}

int _weekdayFromAirDate(String? airDate) {
  if (airDate == null || airDate.isEmpty) return 1;
  final date = DateTime.tryParse(airDate);
  return date?.weekday ?? 1;
}

int _compareByAirDate(AnimeSubject left, AnimeSubject right) {
  return (left.airDate ?? '').compareTo(right.airDate ?? '');
}

int? _normalizeSeasonStartMonth(int? month) {
  if (month == null) return null;
  return const [1, 4, 7, 10].contains(month) ? month : null;
}
