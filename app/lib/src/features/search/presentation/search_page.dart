import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shell/index.dart';
import '../application/search_providers.dart';
import '../../../shared/assets/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  static const _loadAheadExtent = 520.0;

  final _scrollController = ScrollController();
  var _backTopVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final state = ref.watch(searchControllerProvider);

    ref.listen(searchControllerProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
    });

    return ColoredBox(
      color: tokens.page,
      child: Stack(
        children: [
          ListView(
            key: const ValueKey('search-result-page'),
            controller: _scrollController,
            padding: YnekoThemeTokens.pagePadding,
            children: [
              _SearchHead(state: state),
              const SizedBox(height: 14),
              _SearchSummary(state: state),
              const SizedBox(height: 24),
              if (!state.hasQuery)
                SizedBox(
                  key: const ValueKey('search-empty-page'),
                  height: 340,
                  child: YnekoEmptyState(
                    icon: Icons.search_rounded,
                    title: state.mode.emptyTitle,
                    description: '搜索历史会在顶部搜索框下方显示。',
                  ),
                )
              else
                _SearchResultBody(state: state),
            ],
          ),
          _SearchBackTopButton(visible: _backTopVisible, onTap: _scrollToTop),
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
    _maybeLoadMore();
  }

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter > _loadAheadExtent) return;
    ref.read(searchControllerProvider.notifier).loadMore();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: _searchMotion(context, const Duration(milliseconds: 320)),
      curve: Curves.easeOutCubic,
    );
  }
}

class _SearchHead extends StatelessWidget {
  const _SearchHead({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final keyword = state.query.trim();
    final heading = keyword.isEmpty
        ? state.mode.emptyTitle
        : state.mode.heading;
    return RichText(
      key: const ValueKey('search-heading'),
      text: TextSpan(
        style: type.pageTitle,
        children: [
          TextSpan(text: heading),
          if (keyword.isNotEmpty) ...[
            const TextSpan(text: ' '),
            TextSpan(
              text: keyword,
              style: type.pageTitle.copyWith(color: tokens.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchSummary extends StatelessWidget {
  const _SearchSummary({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final incomplete =
        state.hasNext || state.loadingMore || state.appendError != null;
    final text = state.hasQuery
        ? '${incomplete ? '已加载' : '共'} ${state.subjects.length} 个结果'
        : '等待搜索';
    return Text(
      key: const ValueKey('search-summary'),
      text,
      style: type.label.copyWith(
        color: tokens.muted,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SearchResultBody extends ConsumerWidget {
  const _SearchResultBody({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) {
      return YnekoLoadingState(title: state.mode.loadingTitle, minHeight: 520);
    }
    final error = state.error;
    if (error != null) {
      return YnekoPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YnekoEmptyState(
              icon: Icons.bolt_rounded,
              title: state.mode.errorTitle,
              description: error,
            ),
            const SizedBox(height: 12),
            YnekoActionButton(
              key: const ValueKey('search-retry-button'),
              onPressed: ref.read(searchControllerProvider.notifier).retry,
              icon: const Icon(Icons.refresh_rounded),
              label: '重试',
              tone: YnekoActionButtonTone.primary,
            ),
          ],
        ),
      );
    }
    if (state.subjects.isEmpty) {
      return const SizedBox(
        height: 420,
        child: YnekoEmptyState(
          icon: Icons.search_off_rounded,
          title: '没有匹配条目',
          description: '换一个关键词试试，或等待接入更多元数据源。',
        ),
      );
    }

    return Column(
      children: [
        _SearchGrid(subjects: state.subjects, highlight: state.query),
        const SizedBox(height: 18),
        _SearchLoadStatus(state: state),
      ],
    );
  }
}

class _SearchGrid extends ConsumerWidget {
  const _SearchGrid({required this.subjects, required this.highlight});

  final List<AnimeSubject> subjects;
  final String highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth);
        final cards = subjects.map(_subjectToUiCard).toList(growable: false);
        return GridView.builder(
          key: const ValueKey('search-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisSpacing: 28,
            childAspectRatio: 0.585,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final item = cards[index];
            return AnimePosterCard(
              key: ValueKey('search-result-card-${item.id}'),
              item: item,
              titleHighlight: highlight,
              onTap: () => ref
                  .read(shellRouteProvider.notifier)
                  .openWatch(subjectId: item.id),
            );
          },
        );
      },
    );
  }
}

class _SearchLoadStatus extends ConsumerWidget {
  const _SearchLoadStatus({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final appendError = state.appendError;
    if (appendError != null) {
      return YnekoPanel(
        child: Column(
          children: [
            YnekoEmptyState(
              icon: Icons.bolt_rounded,
              title: '继续加载失败',
              description: appendError,
            ),
            const SizedBox(height: 12),
            YnekoActionButton(
              key: const ValueKey('search-load-more-retry'),
              onPressed: ref.read(searchControllerProvider.notifier).loadMore,
              icon: const Icon(Icons.refresh_rounded),
              label: '重试',
              tone: YnekoActionButtonTone.primary,
            ),
          ],
        ),
      );
    }
    final text = state.loadingMore
        ? '正在继续加载...'
        : state.hasNext
        ? '继续向下滚动加载更多'
        : '已经到底了';
    return SizedBox(
      key: const ValueKey('search-load-status'),
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

class _SearchBackTopButton extends StatefulWidget {
  const _SearchBackTopButton({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  State<_SearchBackTopButton> createState() => _SearchBackTopButtonState();
}

class _SearchBackTopButtonState extends State<_SearchBackTopButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _searchMotion(context, YnekoThemeTokens.fastMotion);
    final active = widget.visible && (_hovered || _pressed);
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
            setState(() {
              _hovered = false;
              _pressed = false;
            });
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
              key: const ValueKey('search-back-top-opacity'),
              duration: motion,
              opacity: widget.visible ? 1 : 0,
              child: AnimatedScale(
                duration: motion,
                curve: YnekoThemeTokens.springCurve,
                scale: widget.visible ? (_pressed ? 0.94 : 1) : 0.92,
                child: AnimatedContainer(
                  key: const ValueKey('search-back-top-button'),
                  duration: motion,
                  curve: Curves.easeOut,
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? tokens.primaryContainer
                        : tokens.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active
                          ? tokens.primary.withValues(alpha: 0.42)
                          : tokens.outline.withValues(alpha: 0.45),
                    ),
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
                        active ? tokens.primary : tokens.primaryStrong,
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
    );
  }
}

int _columnsForWidth(double width) {
  if (width >= 1120) return 6;
  if (width >= 760) return 4;
  return 2;
}

UiAnimeCard _subjectToUiCard(AnimeSubject subject) {
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
  final hue = (subject.id.abs() * 37) % 360;
  return UiAnimeCard(
    id: subject.id,
    title: subject.displayTitle,
    subtitle: subtitle,
    score: score,
    coverColor: HSLColor.fromAHSL(1, hue.toDouble(), 0.38, 0.42).toColor(),
    accent: HSLColor.fromAHSL(
      1,
      ((hue + 42) % 360).toDouble(),
      0.44,
      0.56,
    ).toColor(),
    coverUrl: subject.coverUrl,
    summary: subject.summary ?? '',
  );
}

Duration _searchMotion(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
