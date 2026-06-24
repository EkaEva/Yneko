import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shell/index.dart';
import '../application/home_providers.dart';
import '../../../shared/assets/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.tabIndex = 0});

  final int tabIndex;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _rankingLoadAheadExtent = 520.0;

  final _scrollController = ScrollController();
  var _backTopVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeLoadMoreRanking(),
    );
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadMoreRanking(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final controller = ref.read(shellRouteProvider.notifier);
    ref.listen(homeRankingProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeLoadMoreRanking(),
      );
    });

    return ColoredBox(
      color: tokens.page,
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            key: ValueKey('home-tab-panel-${widget.tabIndex}'),
            padding: YnekoThemeTokens.pagePadding,
            children: [
              switch (widget.tabIndex) {
                1 => _ScheduleWorkbench(
                  onOpen: (subjectId) =>
                      controller.openWatch(subjectId: subjectId),
                ),
                2 => _RankingWorkbench(
                  onOpen: (subjectId) =>
                      controller.openWatch(subjectId: subjectId),
                ),
                _ => _RecommendWorkbench(
                  onOpen: (subjectId) =>
                      controller.openWatch(subjectId: subjectId),
                ),
              },
            ],
          ),
          _BackTopButton(visible: _backTopVisible, onTap: _scrollToTop),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final visible =
        _scrollController.hasClients && _scrollController.offset > 240;
    if (visible != _backTopVisible) {
      setState(() => _backTopVisible = visible);
    }
    _maybeLoadMoreRanking();
  }

  void _maybeLoadMoreRanking() {
    if (!mounted || widget.tabIndex != 2 || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.extentAfter > _rankingLoadAheadExtent) return;
    ref.read(homeRankingProvider.notifier).loadMore();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: _homeMotion(context, const Duration(milliseconds: 320)),
      curve: Curves.easeOutCubic,
    );
  }
}

class _RecommendWorkbench extends StatelessWidget {
  const _RecommendWorkbench({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final recommendations = ref.watch(homeRecommendationsProvider);
        return recommendations.when(
          data: (subjects) => _AnimeGrid(
            key: const ValueKey('home-anime-grid'),
            items: subjectsToUiCards(subjects),
            onOpen: onOpen,
          ),
          loading: () => const _HomeShimmerGrid(
            key: ValueKey('home-shimmer-grid'),
            itemCount: 18,
          ),
          error: (error, stackTrace) => _ErrorPanel(
            title: 'Bangumi 推荐加载失败',
            description: error.toString(),
            onRetry: () => ref.invalidate(homeRecommendationsProvider),
          ),
        );
      },
    );
  }
}

class _ScheduleWorkbench extends ConsumerStatefulWidget {
  const _ScheduleWorkbench({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  ConsumerState<_ScheduleWorkbench> createState() => _ScheduleWorkbenchState();
}

class _ScheduleWorkbenchState extends ConsumerState<_ScheduleWorkbench> {
  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(scheduleDayProvider);
    final filtersOpen = ref.watch(scheduleFiltersOpenProvider);
    final archive = ref.watch(scheduleArchiveProvider);
    final schedule = ref.watch(homeScheduleProvider);
    final years = rankingYears();

    return Column(
      key: const ValueKey('home-schedule-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterWall(
          label: '时间表筛选',
          rows: [
            _FilterRowData(
              label: '日期',
              items: homeWeekdayLabels,
              activeIndex: selectedDay - 1,
              onPick: (index) =>
                  ref.read(scheduleDayProvider.notifier).setDay(index + 1),
            ),
            _FilterRowData(
              label: '年份',
              items: years.map((year) => '$year').toList(growable: false),
              activeIndex: _safeActiveIndex(years.indexOf(archive.year)),
              onPick: (index) => ref
                  .read(scheduleArchiveProvider.notifier)
                  .setYear(years[index]),
            ),
            _FilterRowData(
              label: '季度',
              items: scheduleSeasonOptions
                  .map((season) => season.label)
                  .toList(growable: false),
              activeIndex: _safeActiveIndex(
                scheduleSeasonOptions.indexWhere(
                  (season) =>
                      season.seasonStartMonth == archive.seasonStartMonth,
                ),
              ),
              onPick: (index) => ref
                  .read(scheduleArchiveProvider.notifier)
                  .setSeasonStartMonth(
                    scheduleSeasonOptions[index].seasonStartMonth,
                  ),
            ),
          ],
          trailing: _OutlineActionButton(
            icon: filtersOpen
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            label: '新番时光机',
            onTap: ref.read(scheduleFiltersOpenProvider.notifier).toggle,
          ),
          expanded: filtersOpen,
          rowKeyPrefix: 'schedule-filter-row',
        ),
        const SizedBox(height: 22),
        _SummaryLine(text: scheduleArchiveTitle(archive)),
        const SizedBox(height: 22),
        schedule.when(
          data: (state) {
            final subjects = subjectsForScheduleDay(
              days: state.days,
              weekday: selectedDay,
            );
            if (subjects.isEmpty) {
              return _EmptyPanel(
                title: '这一天暂时没有放送条目',
                description:
                    '当前基于 ${state.showingCurrentSchedule ? 'Bangumi 每日放送' : 'Bangumi 浏览条目'} 显示 ${scheduleArchiveTitle(state.archive)}。',
              );
            }
            return _AnimeGrid(
              items: subjectsToUiCards(subjects),
              onOpen: widget.onOpen,
            );
          },
          loading: () => const _HomeShimmerGrid(
            key: ValueKey('home-schedule-shimmer-grid'),
            itemCount: 12,
          ),
          error: (error, stackTrace) => _ErrorPanel(
            title: 'Bangumi 时间表加载失败',
            description: error.toString(),
            onRetry: () {
              ref.invalidate(homeScheduleProvider);
              ref.invalidate(homeCalendarProvider);
            },
          ),
        ),
      ],
    );
  }
}

class _RankingWorkbench extends ConsumerWidget {
  const _RankingWorkbench({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(homeRankingProvider);
    final filters = ref.watch(homeRankingFiltersProvider);
    final moreOpen = ref.watch(rankingMoreOpenProvider);
    final years = rankingYears();
    final rankingController = ref.read(homeRankingFiltersProvider.notifier);

    return Column(
      key: const ValueKey('home-ranking-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterWall(
          label: '榜单筛选',
          rows: [
            _FilterRowData(
              label: '排序',
              items: rankingSortOptions
                  .map((item) => item.label)
                  .toList(growable: false),
              activeIndex: _safeActiveIndex(
                rankingSortOptions.indexWhere(
                  (item) => item.value == filters.sort,
                ),
              ),
              onPick: (index) =>
                  rankingController.setSort(rankingSortOptions[index].value),
            ),
            _rankingFilterRow(
              label: '地区',
              group: 'region',
              filters: filters,
              options: rankingRegionOptions,
              controller: rankingController,
            ),
            _rankingFilterRow(
              label: '类型',
              group: 'type',
              filters: filters,
              options: rankingTypeOptions,
              controller: rankingController,
            ),
            _rankingFilterRow(
              label: '来源',
              group: 'source',
              filters: filters,
              options: rankingSourceOptions,
              controller: rankingController,
            ),
            _rankingFilterRow(
              label: '分类',
              group: 'category',
              filters: filters,
              options: rankingCategoryOptions,
              controller: rankingController,
            ),
            _FilterRowData(
              label: '年份',
              items: ['年份', ...years.map((year) => '$year')],
              activeIndex: filters.year == null
                  ? 0
                  : _safeActiveIndex(years.indexOf(filters.year!) + 1),
              onPick: (index) => rankingController.setYear(
                index == 0 ? null : years[index - 1],
              ),
            ),
            _FilterRowData(
              label: '季度',
              items: rankingSeasonOptions
                  .map((season) => season.label)
                  .toList(growable: false),
              activeIndex: _safeActiveIndex(
                rankingSeasonOptions.indexWhere(
                  (season) => season.value == filters.season,
                ),
              ),
              onPick: (index) => rankingController.setSeason(
                rankingSeasonOptions[index].value,
              ),
            ),
          ],
          trailing: _OutlineActionButton(
            icon: moreOpen
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            label: '更多筛选',
            onTap: ref.read(rankingMoreOpenProvider.notifier).toggle,
          ),
          expanded: moreOpen,
          alwaysVisibleRows: 3,
          rowKeyPrefix: 'ranking-filter-row',
        ),
        const SizedBox(height: 22),
        _SummaryLine(
          text: rankingResponseSummary(ranking.asData?.value.applied, filters),
        ),
        const SizedBox(height: 22),
        ranking.when(
          data: (state) => _RankingResults(
            state: state,
            onOpen: onOpen,
            onLoadMore: ref.read(homeRankingProvider.notifier).loadMore,
          ),
          loading: () => const _HomeShimmerGrid(
            key: ValueKey('home-ranking-shimmer-grid'),
            itemCount: 18,
          ),
          error: (error, stackTrace) => _ErrorPanel(
            title: 'Bangumi 榜单加载失败',
            description: error.toString(),
            onRetry: () => ref.invalidate(homeRankingProvider),
          ),
        ),
      ],
    );
  }
}

_FilterRowData _rankingFilterRow({
  required String label,
  required String group,
  required HomeRankingFilters filters,
  required List<RankingFilterOption> options,
  required HomeRankingFiltersController controller,
}) {
  return _FilterRowData(
    label: label,
    items: options.map((item) => item.label).toList(growable: false),
    activeIndex: _safeActiveIndex(
      options.indexWhere((item) => item.value == filters.valueFor(group)),
    ),
    onPick: (index) => controller.setFilter(group, options[index].value),
  );
}

class _RankingResults extends StatelessWidget {
  const _RankingResults({
    required this.state,
    required this.onOpen,
    required this.onLoadMore,
  });

  final HomeRankingState state;
  final ValueChanged<int> onOpen;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.subjects.isEmpty) {
      return const _EmptyPanel(
        title: '暂无榜单条目',
        description: 'Bangumi 返回空结果，调整筛选条件后再试。',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnimeGrid(items: subjectsToUiCards(state.subjects), onOpen: onOpen),
        if (state.appendError.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ErrorPanel(
            title: '继续加载失败',
            description: state.appendError,
            onRetry: onLoadMore,
          ),
        ],
        const SizedBox(height: 18),
        Center(
          child: state.loadingMore
              ? const _LoadStatus(text: '正在继续加载...')
              : state.hasNext
              ? const _LoadStatus(text: '继续向下滚动自动加载')
              : const _LoadStatus(text: '已经到底了'),
        ),
      ],
    );
  }
}

class _LoadStatus extends StatelessWidget {
  const _LoadStatus({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return SizedBox(
      height: 38,
      child: Center(
        child: Text(
          text,
          style: type.meta.copyWith(
            color: tokens.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BackTopButton extends StatefulWidget {
  const _BackTopButton({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  State<_BackTopButton> createState() => _BackTopButtonState();
}

class _BackTopButtonState extends State<_BackTopButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _homeMotion(context, YnekoThemeTokens.fastMotion);
    final active = widget.visible && (_hovered || _pressed);
    final background = active
        ? tokens.primaryContainer
        : tokens.surface.withValues(alpha: 0.88);
    final border = active
        ? Color.lerp(tokens.primary, Colors.transparent, 0.58)!
        : tokens.outline.withValues(alpha: 0.45);
    final iconColor = active ? tokens.primary : tokens.primaryStrong;

    return Positioned(
      right: 28,
      bottom: 28,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: MouseRegion(
          cursor: widget.visible
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (widget.visible) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (_hovered || _pressed) {
              setState(() {
                _hovered = false;
                _pressed = false;
              });
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: widget.visible
                ? (_) => setState(() => _pressed = true)
                : null,
            onTapUp: widget.visible
                ? (_) => setState(() => _pressed = false)
                : null,
            onTapCancel: widget.visible
                ? () => setState(() => _pressed = false)
                : null,
            child: AnimatedOpacity(
              key: const ValueKey('home-back-top-opacity'),
              duration: motion,
              opacity: widget.visible ? 1 : 0,
              child: AnimatedScale(
                duration: motion,
                curve: YnekoThemeTokens.springCurve,
                scale: widget.visible ? (_pressed ? 0.94 : 1) : 0.92,
                child: AnimatedSlide(
                  duration: motion,
                  curve: YnekoThemeTokens.springCurve,
                  offset: widget.visible
                      ? (_hovered ? const Offset(0, -0.055) : Offset.zero)
                      : const Offset(0, 0.22),
                  child: AnimatedContainer(
                    key: const ValueKey('home-back-top-button'),
                    duration: motion,
                    curve: Curves.easeOut,
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: (active ? tokens.primary : Colors.black)
                              .withValues(alpha: active ? 0.18 : 0.07),
                          blurRadius: active ? 28 : 20,
                          offset: Offset(0, active ? 14 : 8),
                        ),
                      ],
                    ),
                    child: Transform.translate(
                      offset: Offset(0, active ? -2 : 0),
                      child: SvgPicture.asset(
                        YnekoAssets.backToTop,
                        width: 30,
                        height: 30,
                        colorFilter: ColorFilter.mode(
                          iconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _coverPrecacheTimeout = Duration(milliseconds: 1500);

class _AnimeGrid extends StatefulWidget {
  const _AnimeGrid({super.key, required this.items, required this.onOpen});

  final List<UiAnimeCard> items;
  final ValueChanged<int> onOpen;

  @override
  State<_AnimeGrid> createState() => _AnimeGridState();
}

class _AnimeGridState extends State<_AnimeGrid> {
  String? _coverSignature;
  var _coverGeneration = 0;
  var _coversReady = false;
  Timer? _coverFallbackTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureCoverPrecache();
  }

  @override
  void didUpdateWidget(covariant _AnimeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signatureFor(widget.items) != _signatureFor(oldWidget.items)) {
      _ensureCoverPrecache();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_coversReady) {
      return _HomeShimmerGrid(
        key: const ValueKey('home-cover-precache-shimmer-grid'),
        itemCount: widget.items.length,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisSpacing: 28,
            childAspectRatio: 0.585,
          ),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return AnimePosterCard(
              item: item,
              onTap: () => widget.onOpen(item.id),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _coverFallbackTimer?.cancel();
    super.dispose();
  }

  void _ensureCoverPrecache() {
    final signature = _signatureFor(widget.items);
    if (signature == _coverSignature) return;

    _coverFallbackTimer?.cancel();
    _coverSignature = signature;
    final generation = ++_coverGeneration;
    final urls = widget.items
        .map((item) => item.coverUrl)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (urls.isEmpty) {
      _coversReady = true;
      return;
    }

    _coverFallbackTimer = Timer(_coverPrecacheTimeout, () {
      _markCoversReady(generation);
    });

    _precacheAllCovers(urls).then((allLoaded) {
      if (!allLoaded) return;
      if (!mounted || generation != _coverGeneration) return;
      _coverFallbackTimer?.cancel();
      _markCoversReady(generation);
    });
  }

  Future<bool> _precacheAllCovers(List<String> urls) async {
    final results = await Future.wait<bool>(
      urls.map((url) async {
        try {
          await precacheImage(NetworkImage(url), context, onError: (_, _) {});
          return true;
        } catch (_) {
          return false;
        }
      }),
    );
    return results.every((loaded) => loaded);
  }

  void _markCoversReady(int generation) {
    if (!mounted || generation != _coverGeneration || _coversReady) return;
    setState(() => _coversReady = true);
  }

  String _signatureFor(List<UiAnimeCard> items) {
    return items.map((item) => '${item.id}:${item.coverUrl ?? ''}').join('|');
  }

  int _columnsForWidth(double width) {
    if (width >= 1180) return 6;
    if (width >= 760) return 4;
    if (width >= 560) return 3;
    return 2;
  }
}

class _HomeShimmerGrid extends StatefulWidget {
  const _HomeShimmerGrid({super.key, required this.itemCount});

  final int itemCount;

  @override
  State<_HomeShimmerGrid> createState() => _HomeShimmerGridState();
}

class _HomeShimmerGridState extends State<_HomeShimmerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth);
        return GridView.builder(
          key: const ValueKey('home-shimmer-grid-view'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisSpacing: 28,
            childAspectRatio: 0.585,
          ),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return _HomeShimmerCard(
                  progress: reduceMotion ? 0.58 : _controller.value,
                  phase: index * 0.045,
                );
              },
            );
          },
        );
      },
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 1180) return 6;
    if (width >= 760) return 4;
    if (width >= 560) return 3;
    return 2;
  }
}

class _HomeShimmerCard extends StatelessWidget {
  const _HomeShimmerCard({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home-shimmer-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: _ShimmerBlock(
            progress: progress,
            phase: phase,
            borderRadius: 8,
          ),
        ),
        const SizedBox(height: 10),
        FractionallySizedBox(
          widthFactor: 0.94,
          child: SizedBox(
            height: 22,
            child: _ShimmerBlock(
              progress: progress,
              phase: phase + 0.08,
              borderRadius: 6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.52,
          child: SizedBox(
            height: 20,
            child: _ShimmerBlock(
              progress: progress,
              phase: phase + 0.14,
              borderRadius: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.progress,
    required this.phase,
    required this.borderRadius,
  });

  final double progress;
  final double phase;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final sweep = ((progress + phase) % 1.0) * 2.4 - 0.72;
    final base = Color.lerp(tokens.surfaceHigh, tokens.surface, 0.30)!;
    final mid = Color.lerp(tokens.surfaceHigh, Colors.white, 0.44)!;
    final gloss = Color.lerp(tokens.primaryContainer, Colors.white, 0.72)!;
    return DecoratedBox(
      key: const ValueKey('home-shimmer-block'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [
            (sweep - 0.34).clamp(0.0, 1.0),
            (sweep - 0.08).clamp(0.0, 1.0),
            sweep.clamp(0.0, 1.0),
            (sweep + 0.16).clamp(0.0, 1.0),
            (sweep + 0.42).clamp(0.0, 1.0),
          ],
          colors: [base, mid, gloss, mid, base],
        ),
      ),
    );
  }
}

class _FilterWall extends StatelessWidget {
  const _FilterWall({
    required this.label,
    required this.rows,
    required this.trailing,
    this.expanded = true,
    this.alwaysVisibleRows = 1,
    this.rowKeyPrefix = 'filter-row',
  });

  final String label;
  final List<_FilterRowData> rows;
  final Widget trailing;
  final bool expanded;
  final int alwaysVisibleRows;
  final String rowKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _homeMotion(context, YnekoThemeTokens.mediumMotion);
    return Semantics(
      label: label,
      child: AnimatedContainer(
        key: ValueKey('$rowKeyPrefix-wall'),
        duration: motion,
        curve: YnekoThemeTokens.springCurve,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.04,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AnimatedFilterRow(
                    index: 0,
                    expanded: true,
                    keyPrefix: rowKeyPrefix,
                    child: _FilterRow(data: rows.first),
                  ),
                ),
                const SizedBox(width: 14),
                trailing,
              ],
            ),
            for (var index = 1; index < rows.length; index++)
              _AnimatedFilterRow(
                index: index,
                expanded: index < alwaysVisibleRows || expanded,
                keyPrefix: rowKeyPrefix,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _FilterRow(data: rows[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedFilterRow extends StatelessWidget {
  const _AnimatedFilterRow({
    required this.index,
    required this.expanded,
    required this.keyPrefix,
    required this.child,
  });

  final int index;
  final bool expanded;
  final String keyPrefix;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = _homeMotion(context, YnekoThemeTokens.mediumMotion);
    return TweenAnimationBuilder<double>(
      key: ValueKey('$keyPrefix-$index'),
      tween: Tween(end: expanded ? 1 : 0),
      duration: motion,
      curve: YnekoThemeTokens.springCurve,
      builder: (context, value, child) {
        return ClipRect(
          child: Align(
            heightFactor: value,
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -6 * (1 - value)),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.data});

  final _FilterRowData data;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          height: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              data.label,
              style: type.label.copyWith(color: tokens.muted, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              for (var index = 0; index < data.items.length; index++)
                _FilterOption(
                  label: data.items[index],
                  active: index == data.activeIndex,
                  onTap: () => data.onPick?.call(index),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterOption extends StatefulWidget {
  const _FilterOption({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_FilterOption> createState() => _FilterOptionState();
}

class _FilterOptionState extends State<_FilterOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _homeMotion(context, YnekoThemeTokens.fastMotion);
    final active = widget.active || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: motion,
        offset: _hovered ? const Offset(0, -0.025) : Offset.zero,
        child: GestureDetector(
          key: ValueKey('filter-option-${widget.label}'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: active ? tokens.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                widget.label,
                style: type.controlTitle.copyWith(
                  color: active ? tokens.primary : tokens.ink,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatefulWidget {
  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_OutlineActionButton> createState() => _OutlineActionButtonState();
}

class _OutlineActionButtonState extends State<_OutlineActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _homeMotion(context, YnekoThemeTokens.fastMotion);
    final active = _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: ValueKey('outline-action-${widget.label}'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: motion,
          offset: _hovered ? const Offset(0, -0.025) : Offset.zero,
          child: AnimatedContainer(
            duration: motion,
            height: 38,
            padding: const EdgeInsets.only(left: 14, right: 13),
            decoration: BoxDecoration(
              color: active ? tokens.primaryContainer : tokens.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? Color.lerp(tokens.primary, tokens.outline, 0.64)!
                    : tokens.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: type.label.copyWith(
                    color: active ? tokens.primary : tokens.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  widget.icon,
                  size: 16,
                  color: active ? tokens.primary : tokens.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Duration _homeMotion(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return SizedBox(
      height: 22,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: type.meta.copyWith(
            color: tokens.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterRowData {
  const _FilterRowData({
    required this.label,
    required this.items,
    this.activeIndex = 0,
    this.onPick,
  });

  final String label;
  final List<String> items;
  final int activeIndex;
  final ValueChanged<int>? onPick;
}

int _safeActiveIndex(int index) => index < 0 ? 0 : index;

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.title,
    required this.description,
    required this.onRetry,
  });

  final String title;
  final String description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return YnekoPanel(
      child: Column(
        children: [
          YnekoEmptyState(
            icon: Icons.cloud_off_rounded,
            title: title,
            description: description,
          ),
          const SizedBox(height: 12),
          YnekoActionButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: '重试',
            tone: YnekoActionButtonTone.primary,
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return YnekoPanel(
      child: YnekoEmptyState(
        icon: Icons.event_busy_rounded,
        title: title,
        description: description,
      ),
    );
  }
}
