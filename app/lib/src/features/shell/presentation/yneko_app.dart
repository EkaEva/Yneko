import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../episode_playback/index.dart';
import '../../home/index.dart';
import '../../mine/index.dart';
import '../../search/index.dart';
import '../../settings/index.dart';
import '../../subject_detail/index.dart';
import '../../../shared/assets/index.dart';
import '../../../infrastructure/platform/window_chrome/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class YnekoApp extends ConsumerWidget {
  const YnekoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(shellRouteProvider);
    final themeMode = ref.watch(shellThemeModeProvider);

    return MaterialApp(
      title: 'Yneko',
      debugShowCheckedModeBanner: false,
      theme: ynekoTheme(Brightness.light),
      darkTheme: ynekoTheme(Brightness.dark),
      themeMode: themeMode,
      home: YnekoShell(
        route: route,
        child: switch (route) {
          HomeRoute() => const HomePage(),
          MineRoute() => const MinePage(),
          SearchRoute() => const SearchPage(),
          SubjectDetailRoute(:final subjectId) => SubjectDetailPage(
            subjectId: subjectId,
          ),
          EpisodePlaybackRoute(:final subjectId, :final episodeId) =>
            EpisodePlaybackPage(subjectId: subjectId, episodeId: episodeId),
          SettingsRoute() => const SettingsPage(),
        },
      ),
    );
  }
}

class YnekoShell extends ConsumerStatefulWidget {
  const YnekoShell({super.key, required this.route, required this.child});

  final ShellRoute route;
  final Widget child;

  @override
  ConsumerState<YnekoShell> createState() => _YnekoShellState();
}

class _YnekoShellState extends ConsumerState<YnekoShell> {
  bool _searchFocused = false;
  int _homeTab = 0;
  int _searchMode = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final route = widget.route;
    final mediumMotion = _motionDuration(
      context,
      YnekoThemeTokens.mediumMotion,
    );

    return Scaffold(
      backgroundColor: tokens.page,
      body: Row(
        children: [
          _SideRail(route: route),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(color: tokens.page),
              child: Column(
                children: [
                  _TopBar(
                    route: route,
                    searchFocused: _searchFocused,
                    homeTab: _homeTab,
                    searchMode: _searchMode,
                    onSearchFocusChanged: (focused) =>
                        setState(() => _searchFocused = focused),
                    onHomeTabChanged: (index) =>
                        setState(() => _homeTab = index),
                    onSearchModeChanged: (index) =>
                        setState(() => _searchMode = index),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: mediumMotion,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(
                          route.runtimeType.toString() +
                              _routeIdentity(route) +
                              (route is HomeRoute ? '-tab-$_homeTab' : ''),
                        ),
                        child: _contentForRoute(route),
                      ),
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

  Widget _contentForRoute(ShellRoute route) {
    return switch (route) {
      HomeRoute() => HomePage(tabIndex: _homeTab),
      _ => widget.child,
    };
  }

  String _routeIdentity(ShellRoute route) {
    return switch (route) {
      HomeRoute() => 'home',
      MineRoute() => 'mine',
      SearchRoute() => 'search',
      SubjectDetailRoute(:final subjectId) => 'detail-$subjectId',
      EpisodePlaybackRoute(:final subjectId, :final episodeId) =>
        'play-$subjectId-$episodeId',
      SettingsRoute() => 'settings',
    };
  }
}

class _SideRail extends ConsumerWidget {
  const _SideRail({required this.route});

  final ShellRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    final controller = ref.read(shellRouteProvider.notifier);
    final settingsPanel = ref.watch(settingsPanelProvider);

    return Container(
      width: YnekoThemeTokens.railWidth,
      color: tokens.railSurface,
      padding: const EdgeInsets.fromLTRB(7, 14, 7, 26),
      child: Column(
        children: [
          _RailBackButton(
            onTap: () {
              if (route case EpisodePlaybackRoute(:final subjectId)) {
                controller.openSubjectDetail(subjectId);
              } else if (route is SettingsRoute &&
                  settingsPanel != SettingsPanel.root) {
                ref.read(settingsPanelProvider.notifier).openRoot();
              } else {
                controller.openHome();
              }
            },
          ),
          const Spacer(),
          _RailIconButton(
            icon: _RailGlyph.home,
            label: '首页',
            active: route is HomeRoute || route is SearchRoute,
            onTap: controller.openHome,
          ),
          const SizedBox(height: 14),
          _RailIconButton(
            icon: _RailGlyph.mine,
            label: '我的',
            active: route is MineRoute,
            onTap: controller.openMine,
          ),
          const SizedBox(height: 14),
          _RailIconButton(
            icon: _RailGlyph.settings,
            label: '设置',
            active: route is SettingsRoute,
            onTap: controller.openSettings,
          ),
        ],
      ),
    );
  }
}

class _RailBackButton extends StatefulWidget {
  const _RailBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RailBackButton> createState() => _RailBackButtonState();
}

class _RailBackButtonState extends State<_RailBackButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _motionDuration(context, const Duration(milliseconds: 220));
    final color = _hovered || _pressed ? tokens.ink : tokens.muted;

    return Tooltip(
      message: '返回',
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedContainer(
            key: const ValueKey('rail-back-button'),
            duration: motion,
            curve: YnekoThemeTokens.springCurve,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            transform:
                Matrix4.translationValues(
                  0,
                  _pressed ? 1 : (_hovered ? -1 : 0),
                  0,
                )..scaleByDouble(
                  _pressed ? 0.96 : 1.0,
                  _pressed ? 0.96 : 1.0,
                  1,
                  1,
                ),
            decoration: BoxDecoration(
              color: _pressed
                  ? Color.lerp(tokens.surfaceHigh, tokens.railSurface, 0.22)
                  : _hovered
                  ? Color.lerp(tokens.surface, tokens.railSurface, 0.28)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered || _pressed
                    ? tokens.outline.withValues(alpha: _pressed ? 0.88 : 0.82)
                    : Colors.transparent,
              ),
              boxShadow: _hovered || _pressed
                  ? [
                      BoxShadow(
                        color: const Color(
                          0xFF18191C,
                        ).withValues(alpha: _pressed ? 0.08 : 0.07),
                        blurRadius: _pressed ? 10 : 16,
                        offset: Offset(0, _pressed ? 4 : 8),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSlide(
              duration: motion,
              curve: YnekoThemeTokens.springCurve,
              offset: Offset(_pressed ? -0.16 : (_hovered ? -0.12 : -0.04), 0),
              child: Icon(Icons.chevron_left_rounded, color: color, size: 25),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailIconButton extends StatefulWidget {
  const _RailIconButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final _RailGlyph icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_RailIconButton> createState() => _RailIconButtonState();
}

class _RailIconButtonState extends State<_RailIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final active = widget.active || _hovered;
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: motion,
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RailIcon(glyph: widget.icon, active: active),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: active ? tokens.primary : tokens.railLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _RailGlyph { back, home, mine, settings }

class _RailIcon extends StatelessWidget {
  const _RailIcon({required this.glyph, required this.active});

  final _RailGlyph glyph;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final color = active ? tokens.primary : tokens.railIcon;
    if (glyph == _RailGlyph.back) {
      return Icon(Icons.chevron_left_rounded, color: color, size: 25);
    }
    final asset = switch (glyph) {
      _RailGlyph.home => YnekoAssets.railHome,
      _RailGlyph.mine => YnekoAssets.railUser,
      _RailGlyph.settings => YnekoAssets.railSettings,
      _RailGlyph.back => YnekoAssets.railHome,
    };
    return _RailSvgIcon(asset: asset, color: color);
  }
}

class _RailSvgIcon extends StatelessWidget {
  const _RailSvgIcon({required this.asset, required this.color});

  final String asset;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return SvgPicture.asset(
      asset,
      key: ValueKey('rail-svg-$asset'),
      width: 25,
      height: 25,
      theme: SvgTheme(currentColor: color),
      colorMapper: _RailIconCutoutMapper(tokens.railSurface),
    );
  }
}

@immutable
class _RailIconCutoutMapper extends ColorMapper {
  const _RailIconCutoutMapper(this.cutoutColor);

  final Color cutoutColor;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color.toARGB32() == 0xFFF2F3F5) {
      return cutoutColor;
    }
    return color;
  }

  @override
  bool operator ==(Object other) {
    return other is _RailIconCutoutMapper && other.cutoutColor == cutoutColor;
  }

  @override
  int get hashCode => cutoutColor.hashCode;
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.route,
    required this.searchFocused,
    required this.homeTab,
    required this.searchMode,
    required this.onSearchFocusChanged,
    required this.onHomeTabChanged,
    required this.onSearchModeChanged,
  });

  final ShellRoute route;
  final bool searchFocused;
  final int homeTab;
  final int searchMode;
  final ValueChanged<bool> onSearchFocusChanged;
  final ValueChanged<int> onHomeTabChanged;
  final ValueChanged<int> onSearchModeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final fastMotion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    final mediumMotion = _motionDuration(
      context,
      YnekoThemeTokens.mediumMotion,
    );
    final width = MediaQuery.sizeOf(context).width;
    final searchRestWidth = (width * 0.31).clamp(260.0, 376.0);
    final searchFocusedWidth = (width - 560).clamp(320.0, 520.0);
    final searchWidth = searchFocused ? searchFocusedWidth : searchRestWidth;
    final searchTranslate = searchFocused
        ? ((searchFocusedWidth / 2) - (width / 2 - 269))
        : 0.0;

    return SizedBox(
      height: YnekoThemeTokens.topbarHeight,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: tokens.page)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    tokens.dividerFaint,
                    tokens.dividerSoft,
                    tokens.dividerSoft,
                  ],
                  stops: const [0, 0.14, 0.38, 1],
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) => WindowChromeService.startDragging(),
            child: const SizedBox.expand(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                const _BrandWord(),
                const SizedBox(width: 28),
                Expanded(
                  child: AnimatedOpacity(
                    duration: fastMotion,
                    opacity: searchFocused ? 0 : 1,
                    child: AnimatedSlide(
                      duration: fastMotion,
                      offset: searchFocused
                          ? const Offset(0, -0.14)
                          : Offset.zero,
                      child: IgnorePointer(
                        ignoring: searchFocused,
                        child: route is HomeRoute
                            ? YnekoSegmentedTabs(
                                tabs: const ['推荐', '时间表', '榜单'],
                                activeIndex: homeTab,
                                onChanged: onHomeTabChanged,
                              )
                            : route is SearchRoute
                            ? YnekoSegmentedTabs(
                                tabs: const ['动画', '动画标签'],
                                activeIndex: searchMode,
                                onChanged: onSearchModeChanged,
                              )
                            : Text(
                                _pageTitle(route),
                                style: type.topTab.copyWith(
                                  color: tokens.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: mediumMotion,
                  curve: YnekoThemeTokens.springCurve,
                  transform: Matrix4.translationValues(searchTranslate, 0, 0),
                  width: searchWidth,
                  child: _TopSearch(
                    onFocusChanged: onSearchFocusChanged,
                    onSubmitted: (query) {
                      ref.read(searchQueryProvider.notifier).set(query);
                      ref.read(shellRouteProvider.notifier).openSearch();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                _DayNightToggle(
                  dark: ref.watch(shellThemeModeProvider) == ThemeMode.dark,
                  onTap: () =>
                      ref.read(shellThemeModeProvider.notifier).toggle(),
                ),
                const SizedBox(width: 12),
                const _TopActionDivider(),
                const SizedBox(width: 12),
                const _WindowButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle(ShellRoute route) {
    return switch (route) {
      HomeRoute() => '首页',
      MineRoute() => '我的',
      SearchRoute() => '搜索',
      SubjectDetailRoute() => '番剧详情',
      EpisodePlaybackRoute() => '播放详情',
      SettingsRoute() => '设置',
    };
  }
}

class _TopSearch extends StatefulWidget {
  const _TopSearch({required this.onFocusChanged, required this.onSubmitted});

  final ValueChanged<bool> onFocusChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_TopSearch> createState() => _TopSearchState();
}

class _TopSearchState extends State<_TopSearch> {
  bool _focused = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    return Focus(
      onFocusChange: (focused) {
        setState(() => _focused = focused);
        widget.onFocusChanged(focused);
      },
      child: AnimatedContainer(
        duration: motion,
        height: 48,
        decoration: BoxDecoration(
          color: _focused ? tokens.surface : tokens.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focused ? tokens.primary : Colors.transparent,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: tokens.primary.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _controller,
          onSubmitted: widget.onSubmitted,
          textAlignVertical: TextAlignVertical.center,
          style: type.body.copyWith(color: tokens.ink, fontSize: 16),
          decoration: InputDecoration(
            hintText: '搜索番剧',
            hintStyle: type.body.copyWith(color: tokens.muted, fontSize: 16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            prefixIcon: const SizedBox(width: 22),
            prefixIconConstraints: const BoxConstraints.tightFor(
              width: 22,
              height: 46,
            ),
            suffixIcon: SizedBox(
              width: 48,
              height: 46,
              child: IconButton(
                tooltip: '搜索',
                onPressed: () => widget.onSubmitted(_controller.text),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 46),
                  fixedSize: const Size(48, 46),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.search_rounded, color: tokens.ink, size: 23),
              ),
            ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: 48,
              height: 46,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandWord extends StatelessWidget {
  const _BrandWord();

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Semantics(
      container: true,
      label: 'Yneko',
      child: ExcludeSemantics(
        child: Tooltip(
          message: 'Yneko',
          waitDuration: const Duration(milliseconds: 900),
          child: SizedBox(
            height: YnekoThemeTokens.topbarHeight,
            child: Align(
              alignment: const Alignment(0, -0.04),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Y',
                      style: TextStyle(color: tokens.brandY),
                    ),
                    TextSpan(
                      text: 'neko',
                      style: TextStyle(color: tokens.brandNekoText),
                    ),
                  ],
                ),
                style: YnekoTypography.brand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayNightToggle extends StatefulWidget {
  const _DayNightToggle({required this.dark, required this.onTap});

  final bool dark;
  final VoidCallback onTap;

  @override
  State<_DayNightToggle> createState() => _DayNightToggleState();
}

class _DayNightToggleState extends State<_DayNightToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final skyMotion = _motionDuration(
      context,
      const Duration(milliseconds: 460),
    );
    final orbMotion = _motionDuration(
      context,
      const Duration(milliseconds: 540),
    );
    return Tooltip(
      message: '切换主题',
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedSlide(
            duration: _motionDuration(
              context,
              const Duration(milliseconds: 240),
            ),
            offset: _hovered && !reduceMotion
                ? const Offset(0, -0.025)
                : Offset.zero,
            child: AnimatedContainer(
              key: const ValueKey('day-night-toggle'),
              duration: skyMotion,
              width: 86,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: widget.dark
                        ? Colors.black.withValues(alpha: _hovered ? 0.36 : 0.3)
                        : const Color(
                            0xFF488DAA,
                          ).withValues(alpha: _hovered ? 0.24 : 0.18),
                    blurRadius: _hovered ? 28 : 22,
                    offset: Offset(0, _hovered ? 14 : 10),
                  ),
                ],
              ),
              child: ClipRRect(
                key: const ValueKey('toggle-capsule-clip'),
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: _ToggleSky(dark: widget.dark, hovered: _hovered),
                    ),
                    _ToggleStars(
                      dark: widget.dark,
                      motion: _motionDuration(
                        context,
                        const Duration(milliseconds: 500),
                      ),
                    ),
                    _ToggleCloudLayer(
                      dark: widget.dark,
                      motion: _motionDuration(
                        context,
                        const Duration(milliseconds: 500),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: orbMotion,
                      curve: YnekoThemeTokens.springCurve,
                      top: 4,
                      left: widget.dark ? 49 : 5,
                      child: AnimatedRotation(
                        duration: orbMotion,
                        turns: widget.dark && !reduceMotion ? 1 : 0,
                        curve: YnekoThemeTokens.springCurve,
                        child: _ToggleOrb(
                          key: const ValueKey('toggle-orb'),
                          dark: widget.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleSky extends StatelessWidget {
  const _ToggleSky({required this.dark, required this.hovered});

  final bool dark;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('toggle-sky'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF26282D), Color(0xFF3B3D44), Color(0xFF5A5A61)]
              : const [Color(0xFF7CCCF7), Color(0xFFB6ECFF), Color(0xFFFFE6A7)],
          stops: dark ? const [0, 0.54, 1] : const [0, 0.52, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  center: dark
                      ? const Alignment(0.36, -0.52)
                      : const Alignment(-0.52, -0.48),
                  radius: dark ? 0.24 : 0.2,
                  colors: [
                    Colors.white.withValues(alpha: dark ? 0.16 : 0.86),
                    Colors.transparent,
                  ],
                  stops: const [0, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                          Colors.black.withValues(alpha: hovered ? 0.14 : 0.12),
                        ]
                      : [
                          Colors.white.withValues(alpha: hovered ? 0.22 : 0.18),
                          Colors.transparent,
                          Colors.white.withValues(alpha: hovered ? 0.22 : 0.18),
                        ],
                  stops: const [0, 0.2, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleCloudLayer extends StatelessWidget {
  const _ToggleCloudLayer({required this.dark, required this.motion});

  final bool dark;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: motion,
        curve: Curves.easeOut,
        opacity: dark ? 0 : 1,
        child: AnimatedSlide(
          duration: motion,
          curve: YnekoThemeTokens.springCurve,
          offset: dark ? const Offset(-0.24, 0.33) : Offset.zero,
          child: const Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 9,
                bottom: 7,
                child: _ToggleCloud(key: ValueKey('toggle-cloud-a'), width: 28),
              ),
              Positioned(
                right: 29,
                top: 9,
                child: _ToggleCloud(
                  key: ValueKey('toggle-cloud-b'),
                  width: 19,
                  opacity: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleStars extends StatelessWidget {
  const _ToggleStars({required this.dark, required this.motion});

  final bool dark;
  final Duration motion;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: motion,
        curve: Curves.easeOut,
        opacity: dark ? 1 : 0,
        child: AnimatedSlide(
          duration: motion,
          curve: Curves.easeOut,
          offset: dark ? Offset.zero : const Offset(0, -0.1),
          child: const Stack(
            children: [
              Positioned(
                left: 18,
                top: 9,
                child: _ToggleStar(key: ValueKey('toggle-star-a'), size: 3),
              ),
              Positioned(
                left: 28,
                top: 22,
                child: _ToggleStar(
                  key: ValueKey('toggle-star-b'),
                  size: 2,
                  opacity: 0.72,
                ),
              ),
              Positioned(
                right: 16,
                top: 13,
                child: _ToggleStar(
                  key: ValueKey('toggle-star-c'),
                  size: 4,
                  opacity: 0.92,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleOrb extends StatelessWidget {
  const _ToggleOrb({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ToggleSunHalo(dark: dark),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, 0),
                  radius: 0.74,
                  colors: dark
                      ? const [
                          Color(0xFFFBF5DC),
                          Color(0xFFFBF5DC),
                          Color(0xFFBFC3DF),
                        ]
                      : const [
                          Color(0xFFFFF5A9),
                          Color(0xFFFFF5A9),
                          Color(0xFFFFC35C),
                        ],
                  stops: dark ? const [0, 0.42, 1] : const [0, 0.42, 0.7],
                ),
                boxShadow: [
                  if (dark)
                    const BoxShadow(
                      color: Color(0x2EFFFFFF),
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: dark
                        ? const Color(0xFFD7E8FF).withValues(alpha: 0.42)
                        : const Color(0xFFFFD35B).withValues(alpha: 0.76),
                    blurRadius: dark ? 18 : 22,
                  ),
                  BoxShadow(
                    color: dark
                        ? const Color(0xFF0C1020).withValues(alpha: 0.34)
                        : const Color(0xFFE2912B).withValues(alpha: 0.34),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          _ToggleSunHighlight(dark: dark),
          _ToggleMoonCraters(dark: dark),
        ],
      ),
    );
  }
}

class _ToggleSunHalo extends StatelessWidget {
  const _ToggleSunHalo({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final motion = _motionDuration(context, const Duration(milliseconds: 450));
    return AnimatedOpacity(
      duration: motion,
      curve: Curves.easeOut,
      opacity: dark ? 0 : 1,
      child: AnimatedScale(
        duration: motion,
        curve: YnekoThemeTokens.springCurve,
        scale: dark ? 0.5 : 1,
        child: const Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              key: ValueKey('toggle-halo-outer'),
              left: -14,
              top: -14,
              child: _ToggleOrbHalo(size: 60, stop: 0.64, alpha: 0.14),
            ),
            Positioned(
              key: ValueKey('toggle-halo-inner'),
              left: -7,
              top: -7,
              child: _ToggleOrbHalo(size: 46, stop: 0.46, alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSunHighlight extends StatelessWidget {
  const _ToggleSunHighlight({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final motion = _motionDuration(context, const Duration(milliseconds: 280));
    return Positioned(
      left: 5.5,
      top: 3.5,
      child: AnimatedOpacity(
        duration: motion,
        curve: Curves.easeOut,
        opacity: dark ? 0 : 1,
        child: const _SunHighlight(),
      ),
    );
  }
}

class _ToggleMoonCraters extends StatelessWidget {
  const _ToggleMoonCraters({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final motion = _motionDuration(context, const Duration(milliseconds: 380));
    return AnimatedOpacity(
      duration: motion,
      curve: Curves.easeOut,
      opacity: dark ? 1 : 0,
      child: AnimatedScale(
        duration: motion,
        curve: YnekoThemeTokens.springCurve,
        scale: dark ? 1 : 0.4,
        child: const Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 9,
              top: 7,
              child: _ToggleDot(size: 6, color: Color(0x61796F99)),
            ),
            Positioned(
              right: 7,
              bottom: 8,
              child: _ToggleDot(size: 4, color: Color(0x61796F99)),
            ),
            Positioned(
              left: 8,
              bottom: 7,
              child: _ToggleDot(size: 3, color: Color(0x61796F99)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunHighlight extends StatelessWidget {
  const _SunHighlight();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.28, -0.32),
            radius: 0.72,
            colors: [
              Colors.white.withValues(alpha: 0.96),
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0.24),
              Colors.transparent,
            ],
            stops: const [0, 0.36, 0.78, 1],
          ),
        ),
      ),
    );
  }
}

class _ToggleOrbHalo extends StatelessWidget {
  const _ToggleOrbHalo({
    required this.size,
    required this.stop,
    required this.alpha,
  });

  final double size;
  final double stop;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFFFF5AC).withValues(alpha: alpha),
              const Color(0xFFFFF5AC).withValues(alpha: alpha),
              Colors.transparent,
            ],
            stops: [0, stop, stop + 0.01],
          ),
        ),
        child: SizedBox(width: size, height: size),
      ),
    );
  }
}

class _ToggleDot extends StatelessWidget {
  const _ToggleDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ToggleStar extends StatelessWidget {
  const _ToggleStar({super.key, required this.size, this.opacity = 0.92});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 8),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            offset: const Offset(16, 8),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.68),
            offset: const Offset(37, 4),
            spreadRadius: -1,
          ),
        ],
      ),
    );
  }
}

class _ToggleCloud extends StatelessWidget {
  const _ToggleCloud({super.key, required this.width, this.opacity = 0.88});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              offset: Offset(8, -4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white70,
              offset: Offset(18, 0),
              spreadRadius: -1,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopActionDivider extends StatelessWidget {
  const _TopActionDivider();

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      key: const ValueKey('top-action-divider'),
      width: 1,
      height: 20,
      decoration: BoxDecoration(
        color: tokens.dividerSoft,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _WindowButton(
          icon: _WindowControlGlyph.minimize,
          tooltip: '最小化',
          onTap: WindowChromeService.minimize,
        ),
        _MaximizeWindowButton(),
        _WindowButton(
          icon: _WindowControlGlyph.close,
          tooltip: '关闭',
          close: true,
          onTap: WindowChromeService.close,
        ),
      ],
    );
  }
}

class _MaximizeWindowButton extends StatefulWidget {
  const _MaximizeWindowButton();

  @override
  State<_MaximizeWindowButton> createState() => _MaximizeWindowButtonState();
}

class _MaximizeWindowButtonState extends State<_MaximizeWindowButton> {
  bool _maximized = false;

  @override
  Widget build(BuildContext context) {
    return _WindowButton(
      key: const ValueKey('window-maximize-button'),
      icon: _maximized
          ? _WindowControlGlyph.restore
          : _WindowControlGlyph.maximize,
      tooltip: _maximized ? '还原' : '最大化',
      onTap: () async {
        if (mounted) {
          setState(() => _maximized = !_maximized);
        }
        await WindowChromeService.toggleMaximize();
      },
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.close = false,
  });

  final _WindowControlGlyph icon;
  final String tooltip;
  final Future<void> Function() onTap;
  final bool close;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _motionDuration(context, const Duration(milliseconds: 160));
    final closeHover = widget.close && _hovered;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(),
          child: AnimatedContainer(
            key: ValueKey('window-button-${widget.tooltip}'),
            duration: motion,
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: closeHover
                  ? const Color(0xFFFF5C7A)
                  : _hovered
                  ? const Color(0xFFE3E5E7).withValues(alpha: 0.56)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _WindowControlSvgIcon(
              key: ValueKey('window-icon-${widget.icon.name}'),
              glyph: widget.icon,
              color: closeHover ? Colors.white : tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}

enum _WindowControlGlyph { minimize, maximize, restore, close }

class _WindowControlSvgIcon extends StatelessWidget {
  const _WindowControlSvgIcon({
    super.key,
    required this.glyph,
    required this.color,
  });

  final _WindowControlGlyph glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.string(
        _svg,
        width: 16,
        height: 16,
        allowDrawingOutsideViewBox: false,
      ),
    );
  }

  String get _svg {
    final stroke = _svgColor(color);
    final body = switch (glyph) {
      _WindowControlGlyph.minimize => '<path d="M5 12h14"/>',
      _WindowControlGlyph.maximize =>
        '<rect width="18" height="18" x="3" y="3" rx="2"/>',
      _WindowControlGlyph.restore =>
        '<rect width="14" height="14" x="8" y="8" rx="2" ry="2"/>'
            '<path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
      _WindowControlGlyph.close =>
        '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    };
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  $body
</svg>
''';
  }
}

String _svgColor(Color color) {
  final value = color.toARGB32() & 0xFFFFFFFF;
  return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

Duration _motionDuration(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

sealed class ShellRoute {
  const ShellRoute();
}

class HomeRoute extends ShellRoute {
  const HomeRoute();
}

class SearchRoute extends ShellRoute {
  const SearchRoute();
}

class MineRoute extends ShellRoute {
  const MineRoute();
}

class SettingsRoute extends ShellRoute {
  const SettingsRoute();
}

class SubjectDetailRoute extends ShellRoute {
  const SubjectDetailRoute({required this.subjectId});

  final int subjectId;
}

class EpisodePlaybackRoute extends ShellRoute {
  const EpisodePlaybackRoute({
    required this.subjectId,
    required this.episodeId,
  });

  final int subjectId;
  final int episodeId;
}

class ShellRouteController extends Notifier<ShellRoute> {
  @override
  ShellRoute build() => const HomeRoute();

  void openHome() {
    state = const HomeRoute();
  }

  void openSearch() {
    state = const SearchRoute();
  }

  void openMine() {
    state = const MineRoute();
  }

  void openSubjectDetail(int subjectId) {
    state = SubjectDetailRoute(subjectId: subjectId);
  }

  void openSettings() {
    ref.read(settingsPanelProvider.notifier).openRoot();
    state = const SettingsRoute();
  }

  void openEpisodePlayback({required int subjectId, required int episodeId}) {
    state = EpisodePlaybackRoute(subjectId: subjectId, episodeId: episodeId);
  }
}

final shellRouteProvider = NotifierProvider<ShellRouteController, ShellRoute>(
  ShellRouteController.new,
);

class ShellThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final shellThemeModeProvider =
    NotifierProvider<ShellThemeModeController, ThemeMode>(
      ShellThemeModeController.new,
    );
