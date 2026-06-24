import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';
import '../application/search_providers.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final tagMode = ref.watch(searchTagModeProvider);
    final results = ref.watch(searchResultsProvider);
    final cleanQuery = query.trim();
    final isIncomplete = cleanQuery.isNotEmpty;
    final displayItems = cleanQuery.isEmpty
        ? <UiAnimeCard>[]
        : mockAnimeCards
              .where(
                (item) =>
                    item.title.contains(cleanQuery) ||
                    item.subtitle.contains(cleanQuery) ||
                    item.summary.contains(cleanQuery),
              )
              .toList();
    final fallbackItems = cleanQuery.isEmpty ? <UiAnimeCard>[] : mockAnimeCards;
    final visibleItems = displayItems.isEmpty && cleanQuery.isNotEmpty
        ? fallbackItems
        : displayItems;

    return ListView(
      key: const ValueKey('search-result-page'),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
      children: [
        _SearchHead(
          keyword: cleanQuery,
          tagMode: tagMode,
          onBack: () => ref.read(shellRouteProvider.notifier).openHome(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              cleanQuery.isEmpty
                  ? '等待搜索'
                  : '${isIncomplete ? '已加载' : '共'} ${visibleItems.length} 个结果',
              style: YnekoTypography.of(context).label.copyWith(
                color: YnekoThemeTokens.of(context).muted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            _SearchModeToggle(
              tagMode: tagMode,
              onChanged: (value) =>
                  ref.read(searchTagModeProvider.notifier).set(value),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('search-page-input'),
                decoration: InputDecoration(
                  hintText: tagMode ? '输入标签开始搜索' : '输入关键词开始搜索',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).set(value),
              ),
            ),
            const SizedBox(width: 12),
            YnekoActionButton(
              onPressed: () {},
              icon: const Icon(Icons.search_rounded),
              label: '搜索',
              tone: YnekoActionButtonTone.primary,
              height: 40,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final label in ['星轨', '治愈', '原创动画', '2026', '高分'])
              _SearchHotChip(
                label: label,
                onPressed: () =>
                    ref.read(searchQueryProvider.notifier).set(label),
              ),
          ],
        ),
        const SizedBox(height: 26),
        results.when(
          loading: () => const YnekoLoadingState(
            title: '正在同步 Bangumi 搜索结果',
            minHeight: 520,
          ),
          error: (error, stackTrace) => YnekoPanel(
            child: YnekoEmptyState(
              icon: Icons.bolt_rounded,
              title: tagMode ? 'Bangumi 标签页加载失败' : 'Bangumi 搜索失败',
              description: error.toString(),
            ),
          ),
          data: (_) {
            if (cleanQuery.isEmpty) {
              return const YnekoPanel(
                child: YnekoEmptyState(
                  icon: Icons.search_rounded,
                  title: '输入关键词开始搜索',
                  description: '可以使用顶部搜索，也可以在这里输入关键词或标签。',
                ),
              );
            }
            if (visibleItems.isEmpty) {
              return const YnekoPanel(
                child: YnekoEmptyState(
                  icon: Icons.search_off_rounded,
                  title: '没有匹配条目',
                  description: '换一个关键词试试，或等待接入更多元数据源。',
                ),
              );
            }
            return Column(
              children: [
                _SearchGrid(items: visibleItems, highlight: cleanQuery),
                const SizedBox(height: 18),
                Text(
                  '已经到底了',
                  style: YnekoTypography.of(context).label.copyWith(
                    color: YnekoThemeTokens.of(context).muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SearchHead extends StatelessWidget {
  const _SearchHead({
    required this.keyword,
    required this.tagMode,
    required this.onBack,
  });

  final String keyword;
  final bool tagMode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1, right: 18),
          child: YnekoActionButton(
            key: const ValueKey('search-back-button'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: '返回',
            tone: YnekoActionButtonTone.outline,
            height: 36,
            minWidth: 78,
            borderRadius: 999,
            textStyle: type.label.copyWith(
              color: tokens.primaryStrong,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            key: const ValueKey('search-heading'),
            text: TextSpan(
              style: type.pageTitle,
              children: [
                TextSpan(
                  text: keyword.isEmpty
                      ? (tagMode ? '输入标签开始搜索' : '输入关键词开始搜索')
                      : (tagMode ? '标签 ' : '搜索 '),
                ),
                if (keyword.isNotEmpty)
                  TextSpan(
                    text: keyword,
                    style: type.pageTitle.copyWith(color: tokens.primary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHotChip extends StatefulWidget {
  const _SearchHotChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_SearchHotChip> createState() => _SearchHotChipState();
}

class _SearchHotChipState extends State<_SearchHotChip> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final active = _hovered || _pressed;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: YnekoThemeTokens.fastMotion,
          scale: _pressed ? 0.98 : 1,
          child: AnimatedContainer(
            duration: YnekoThemeTokens.fastMotion,
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? tokens.primaryContainer : tokens.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active
                    ? Color.lerp(tokens.outline, tokens.primary, 0.38)!
                    : tokens.outline.withValues(alpha: 0.52),
              ),
            ),
            child: Text(
              widget.label,
              style: type.label.copyWith(
                color: active ? tokens.primary : tokens.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchModeToggle extends StatelessWidget {
  const _SearchModeToggle({required this.tagMode, required this.onChanged});

  final bool tagMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      key: const ValueKey('search-mode-toggle'),
      segments: const [
        ButtonSegment(value: false, label: Text('关键词')),
        ButtonSegment(value: true, label: Text('标签')),
      ],
      selected: {tagMode},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _SearchGrid extends ConsumerWidget {
  const _SearchGrid({required this.items, required this.highlight});

  final List<UiAnimeCard> items;
  final String highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + 24) / (206 + 24))
            .floor()
            .clamp(1, 6);
        return GridView.builder(
          key: const ValueKey('search-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 34,
            crossAxisSpacing: 24,
            childAspectRatio: 1.52,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _SearchResultCard(
              item: item,
              highlight: highlight,
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

class _SearchResultCard extends StatefulWidget {
  const _SearchResultCard({
    required this.item,
    required this.highlight,
    required this.onTap,
  });

  final UiAnimeCard item;
  final String highlight;
  final VoidCallback onTap;

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<_SearchResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return MouseRegion(
      key: ValueKey('search-result-card-${widget.item.id}'),
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: YnekoThemeTokens.fastMotion,
          offset: _hovered ? const Offset(0, -0.025) : Offset.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [widget.item.coverColor, widget.item.accent],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: 18,
                          bottom: 14,
                          child: Text(
                            widget.item.title.characters.first,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xB8141216),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              child: Text(
                                widget.item.score,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                overflow: TextOverflow.ellipsis,
                text: _highlightedText(
                  widget.item.title,
                  widget.highlight,
                  type.cardTitle.copyWith(
                    color: _hovered ? tokens.primary : tokens.ink,
                  ),
                  tokens.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.item.subtitle,
                overflow: TextOverflow.ellipsis,
                style: type.meta.copyWith(
                  color: _hovered ? tokens.primary : tokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _highlightedText(
    String text,
    String highlight,
    TextStyle style,
    Color highlightColor,
  ) {
    if (highlight.isEmpty || !text.contains(highlight)) {
      return TextSpan(text: text, style: style);
    }
    final index = text.indexOf(highlight);
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: highlight,
          style: style.copyWith(color: highlightColor),
        ),
        TextSpan(text: text.substring(index + highlight.length)),
      ],
    );
  }
}
