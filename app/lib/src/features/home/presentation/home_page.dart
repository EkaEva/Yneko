import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.tabIndex = 0});

  final int tabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    final controller = ref.read(shellRouteProvider.notifier);

    return ColoredBox(
      color: tokens.page,
      child: ListView(
        key: ValueKey('home-tab-panel-$tabIndex'),
        padding: YnekoThemeTokens.pagePadding,
        children: [
          switch (tabIndex) {
            1 => _ScheduleWorkbench(onOpen: controller.openSubjectDetail),
            2 => _RankingWorkbench(onOpen: controller.openSubjectDetail),
            _ => _RecommendWorkbench(onOpen: controller.openSubjectDetail),
          },
        ],
      ),
    );
  }
}

class _RecommendWorkbench extends StatelessWidget {
  const _RecommendWorkbench({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return _AnimeGrid(
      key: const ValueKey('home-anime-grid'),
      items: mockAnimeCards,
      onOpen: onOpen,
    );
  }
}

class _ScheduleWorkbench extends StatelessWidget {
  const _ScheduleWorkbench({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = now.year;
    final visibleItems = [
      ...mockAnimeCards.skip(1),
      mockAnimeCards.first,
    ].take(12).toList();

    return Column(
      key: const ValueKey('home-schedule-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterWall(
          label: '时间表筛选',
          rows: [
            _FilterRowData(
              label: '日期',
              items: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
              activeIndex: 5,
            ),
            _FilterRowData(
              label: '年份',
              items: [
                '2026',
                '2025',
                '2024',
                '2023',
                '2022',
                '2021',
                '2020',
                '2019',
                '2018',
                '2017',
                '2016',
                '2015',
              ],
            ),
            _FilterRowData(
              label: '季度',
              items: ['全年', '1月', '4月', '7月', '10月'],
              activeIndex: 2,
            ),
          ],
          trailing: _ScheduleMachineActions(),
          expanded: true,
          rowKeyPrefix: 'schedule-filter-row',
        ),
        const SizedBox(height: 22),
        _SummaryLine(text: '$year年新番'),
        const SizedBox(height: 22),
        _AnimeGrid(items: visibleItems, onOpen: onOpen),
      ],
    );
  }
}

class _ScheduleMachineActions extends StatelessWidget {
  const _ScheduleMachineActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconActionButton(icon: Icons.shuffle_rounded, tooltip: '随机选择日期和季度'),
        SizedBox(width: 12),
        _OutlineActionButton(
          icon: Icons.keyboard_arrow_up_rounded,
          label: '新番时光机',
          active: true,
        ),
      ],
    );
  }
}

class _RankingWorkbench extends StatelessWidget {
  const _RankingWorkbench({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final rankedItems = [...mockAnimeCards]
      ..sort((a, b) => b.score.compareTo(a.score));

    return Column(
      key: const ValueKey('home-ranking-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterWall(
          label: '榜单筛选',
          rows: [
            _FilterRowData(
              label: '排序',
              items: ['排名', '热度', '收藏', '日期', '名称'],
              activeIndex: 1,
            ),
            _FilterRowData(label: '地区', items: ['全部', '日本', '国产', '欧美']),
            _FilterRowData(
              label: '类型',
              items: [
                '全部',
                '科幻',
                '喜剧',
                '同人',
                '百合',
                '校园',
                '惊悚',
                '后宫',
                '机战',
                '悬疑',
                '恋爱',
                '奇幻',
                '推理',
                '运动',
                '耽美',
                '音乐',
                '战斗',
                '冒险',
                '亲子',
                '穿越',
                '玄幻',
                '乙女',
                '恐怖',
                '历史',
                '日常',
                '剧情',
                '武侠',
                '美食',
                '职场',
              ],
            ),
            _FilterRowData(
              label: '来源',
              items: ['全部', '原创', '漫画改', '游戏改', '小说改', '动画改', '影视改', '轻小说改'],
            ),
            _FilterRowData(
              label: '分类',
              items: ['全部', 'TV', 'WEB', 'OVA', '剧场版', '动态漫画', '其他'],
            ),
            _FilterRowData(
              label: '年份',
              items: [
                '年份',
                '2026',
                '2025',
                '2024',
                '2023',
                '2022',
                '2021',
                '2020',
                '2019',
                '2018',
                '2017',
                '2016',
                '2015',
              ],
            ),
            _FilterRowData(label: '季度', items: ['季度', '1月', '4月', '7月', '10月']),
          ],
          trailing: _OutlineActionButton(
            icon: Icons.keyboard_arrow_up_rounded,
            label: '更多筛选',
            active: true,
          ),
          expanded: true,
          rowKeyPrefix: 'ranking-filter-row',
        ),
        const SizedBox(height: 22),
        const _SummaryLine(text: '热度 · 全部动画'),
        const SizedBox(height: 22),
        _AnimeGrid(items: rankedItems, onOpen: onOpen),
      ],
    );
  }
}

class _AnimeGrid extends StatelessWidget {
  const _AnimeGrid({super.key, required this.items, required this.onOpen});

  final List<UiAnimeCard> items;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return AnimePosterCard(item: item, onTap: () => onOpen(item.id));
          },
        );
      },
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 1180) return 6;
    if (width >= 980) return 5;
    if (width >= 760) return 4;
    if (width >= 560) return 3;
    return 2;
  }
}

class _FilterWall extends StatelessWidget {
  const _FilterWall({
    required this.label,
    required this.rows,
    required this.trailing,
    this.expanded = true,
    this.rowKeyPrefix = 'filter-row',
  });

  final String label;
  final List<_FilterRowData> rows;
  final Widget trailing;
  final bool expanded;
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
                expanded: expanded,
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
              style: TextStyle(
                color: tokens.muted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
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
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterOption extends StatefulWidget {
  const _FilterOption({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  State<_FilterOption> createState() => _FilterOptionState();
}

class _FilterOptionState extends State<_FilterOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _homeMotion(context, YnekoThemeTokens.fastMotion);
    final active = widget.active || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: motion,
        offset: _hovered ? const Offset(0, -0.025) : Offset.zero,
        child: AnimatedContainer(
          key: ValueKey('filter-option-${widget.label}'),
          duration: motion,
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
              style: TextStyle(
                color: active ? tokens.primary : tokens.ink,
                fontSize: 15,
                fontWeight: widget.active ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatefulWidget {
  const _IconActionButton({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _homeMotion(context, YnekoThemeTokens.fastMotion);
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedSlide(
          duration: motion,
          offset: _hovered ? const Offset(0, -0.025) : Offset.zero,
          child: AnimatedContainer(
            key: const ValueKey('schedule-random-button'),
            duration: motion,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? tokens.primaryContainer : tokens.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                    ? Color.lerp(tokens.primary, tokens.outline, 0.64)!
                    : tokens.outline,
              ),
            ),
            child: AnimatedRotation(
              turns: _hovered ? 0.08 : 0,
              duration: motion,
              child: Icon(
                widget.icon,
                size: 18,
                color: _hovered ? tokens.primary : tokens.muted,
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
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  State<_OutlineActionButton> createState() => _OutlineActionButtonState();
}

class _OutlineActionButtonState extends State<_OutlineActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _homeMotion(context, YnekoThemeTokens.fastMotion);
    final active = widget.active || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
                style: TextStyle(
                  color: active ? tokens.primary : tokens.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1,
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
    return SizedBox(
      height: 22,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: tokens.muted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1,
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
  });

  final String label;
  final List<String> items;
  final int activeIndex;
}
