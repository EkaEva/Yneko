import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/assets/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

enum _MineTab { library, history, cache }

enum _LibraryFilter { all, watching, wish, watched, paused, dropped }

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  _MineTab _tab = _MineTab.library;
  _LibraryFilter _filter = _LibraryFilter.all;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('mine-page'),
      padding: YnekoThemeTokens.pagePadding,
      children: [
        const _MineProfileCard(libraryCount: 0, historyCount: 0, cacheCount: 0),
        const SizedBox(height: 24),
        _MineTabsPanel(
          tab: _tab,
          filter: _filter,
          queryController: _searchController,
          historyHasItems: false,
          onTabChanged: (tab) => setState(() => _tab = tab),
          onFilterChanged: (filter) => setState(() => _filter = filter),
          onQueryChanged: (_) => setState(() {}),
          onClearHistory: () {},
        ),
        const SizedBox(height: 24),
        const _MineEmptyPrompt(),
      ],
    );
  }
}

class _MineProfileCard extends StatelessWidget {
  const _MineProfileCard({
    required this.libraryCount,
    required this.historyCount,
    required this.cacheCount,
  });

  final int libraryCount;
  final int historyCount;
  final int cacheCount;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      key: const ValueKey('mine-profile-card'),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        color: tokens.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.44)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0 : 0.48,
            ),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const YnekoProfileAvatar(size: 72),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              '喵',
              overflow: TextOverflow.ellipsis,
              style: type.pageTitle.copyWith(fontSize: 26),
            ),
          ),
          SizedBox(
            width: 360,
            child: Row(
              children: [
                _MineStat(value: libraryCount, label: '追番', bordered: false),
                _MineStat(value: historyCount, label: '历史'),
                _MineStat(value: cacheCount, label: '缓存'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MineStat extends StatelessWidget {
  const _MineStat({
    required this.value,
    required this.label,
    this.bordered = true,
  });

  final int value;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: bordered
              ? Border(left: BorderSide(color: tokens.dividerSoft))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: type.sectionTitle.copyWith(fontSize: 25, height: 1),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: type.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineTabsPanel extends StatelessWidget {
  const _MineTabsPanel({
    required this.tab,
    required this.filter,
    required this.queryController,
    required this.historyHasItems,
    required this.onTabChanged,
    required this.onFilterChanged,
    required this.onQueryChanged,
    required this.onClearHistory,
  });

  final _MineTab tab;
  final _LibraryFilter filter;
  final TextEditingController queryController;
  final bool historyHasItems;
  final ValueChanged<_MineTab> onTabChanged;
  final ValueChanged<_LibraryFilter> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      key: const ValueKey('mine-tabs-panel'),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.dividerSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              children: [
                _MineTabButton(
                  label: '追番',
                  active: tab == _MineTab.library,
                  onTap: () => onTabChanged(_MineTab.library),
                ),
                const SizedBox(width: 44),
                _MineTabButton(
                  label: '历史',
                  active: tab == _MineTab.history,
                  onTap: () => onTabChanged(_MineTab.history),
                ),
                const SizedBox(width: 44),
                _MineTabButton(
                  label: '缓存',
                  active: tab == _MineTab.cache,
                  onTap: () => onTabChanged(_MineTab.cache),
                ),
              ],
            ),
          ),
          SizedBox(
            width: tab == _MineTab.cache ? 330 : 458,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  if (tab == _MineTab.library) ...[
                    SizedBox(
                      width: 118,
                      child: _MineStatusMenu(
                        value: filter,
                        onChanged: onFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (tab == _MineTab.history) ...[
                    SizedBox(
                      width: 118,
                      child: _MineClearButton(
                        enabled: historyHasItems,
                        onTap: onClearHistory,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _MineSearchField(
                      controller: queryController,
                      hintText: switch (tab) {
                        _MineTab.library => '搜索我的追番',
                        _MineTab.history => '搜索历史',
                        _MineTab.cache => '搜索缓存',
                      },
                      onChanged: onQueryChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MineTabButton extends StatelessWidget {
  const _MineTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final textStyle = type.topTab.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w800,
    );
    return YnekoPressable(
      onTap: onTap,
      borderRadius: 0,
      scaleOnPress: false,
      builder: (context, hovered, pressed) {
        final highlighted = active || hovered || pressed;
        return SizedBox(
          height: 48,
          width: 36,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: textStyle.copyWith(
                  color: highlighted ? tokens.primary : tokens.ink,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                child: TweenAnimationBuilder<double>(
                  duration: YnekoThemeTokens.fastMotion,
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.36, end: active ? 1 : 0.36),
                  builder: (context, scale, child) => Transform.scale(
                    alignment: Alignment.centerLeft,
                    scaleX: scale,
                    child: child,
                  ),
                  child: AnimatedOpacity(
                    duration: YnekoThemeTokens.fastMotion,
                    opacity: active ? 1 : 0,
                    child: Container(
                      key: ValueKey('mine-tab-underline-$label'),
                      height: 3,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MineSearchField extends StatefulWidget {
  const _MineSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<_MineSearchField> createState() => _MineSearchFieldState();
}

class _MineSearchFieldState extends State<_MineSearchField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final focused = _focusNode.hasFocus;
    final searchIconColor = tokens.muted;
    final hintColor = tokens.muted.withValues(alpha: 0.72);
    final borderColor = focused
        ? Color.lerp(tokens.outline, tokens.primary, 0.48)!
        : tokens.outline.withValues(alpha: 0.66);
    return AnimatedContainer(
      key: const ValueKey('mine-local-search-frame'),
      duration: YnekoThemeTokens.fastMotion,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: TextField(
        key: const ValueKey('mine-local-search'),
        focusNode: _focusNode,
        controller: widget.controller,
        onChanged: widget.onChanged,
        cursorColor: tokens.primary,
        style: type.body.copyWith(
          color: tokens.ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: type.body.copyWith(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: Icon(
            Icons.search_rounded,
            color: searchIconColor,
            size: 20,
          ),
          suffixIconConstraints: const BoxConstraints.tightFor(
            width: 48,
            height: 40,
          ),
          filled: true,
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _MineStatusMenu extends StatelessWidget {
  const _MineStatusMenu({required this.value, required this.onChanged});

  final _LibraryFilter value;
  final ValueChanged<_LibraryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return YnekoHoverMenu<_LibraryFilter>(
      key: const ValueKey('mine-status-menu'),
      triggerKey: const ValueKey('mine-status-trigger'),
      value: value,
      height: 40,
      panelMaxWidth: 160,
      optionMinWidth: 118,
      optionAlignment: Alignment.center,
      triggerFontSize: 14,
      optionFontSize: 14,
      leadingPadding: 16,
      trailingPadding: 12,
      showOpenShadow: false,
      centerTriggerContent: true,
      items: [
        for (final option in _LibraryFilter.values)
          YnekoHoverMenuItem(value: option, label: _filterLabel(option)),
      ],
      onChanged: onChanged,
    );
  }

  String _filterLabel(_LibraryFilter filter) {
    return switch (filter) {
      _LibraryFilter.all => '全部',
      _LibraryFilter.watching => '在看',
      _LibraryFilter.wish => '想看',
      _LibraryFilter.watched => '看过',
      _LibraryFilter.paused => '搁置',
      _LibraryFilter.dropped => '抛弃',
    };
  }
}

class _MineClearButton extends StatelessWidget {
  const _MineClearButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: _MineSmallControl(
        icon: Icons.delete_outline_rounded,
        label: '清空历史',
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class _MineSmallControl extends StatelessWidget {
  const _MineSmallControl({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return YnekoPressable(
      onTap: onTap,
      borderRadius: 8,
      builder: (context, hovered, pressed) {
        final highlighted = hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: highlighted ? tokens.primaryContainer : tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlighted
                  ? Color.lerp(tokens.outline, tokens.primary, 0.38)!
                  : tokens.outline,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: highlighted ? tokens.primary : tokens.muted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: type.label.copyWith(
                    color: highlighted ? tokens.primary : tokens.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MineEmptyPrompt extends StatelessWidget {
  const _MineEmptyPrompt();

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return SizedBox(
      key: const ValueKey('mine-empty-prompt'),
      height: 340,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            YnekoAssets.empty,
            width: 142,
            height: 142,
            colorFilter: ColorFilter.mode(
              tokens.soft.withValues(alpha: 0.58),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '这里什么都没有喵～\n快去追番吧（=^･ω･^=）',
            textAlign: TextAlign.center,
            style: type.body.copyWith(
              color: tokens.soft,
              fontWeight: FontWeight.w600,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
