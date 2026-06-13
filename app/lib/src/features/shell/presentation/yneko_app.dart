import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../episode_playback/index.dart';
import '../../home/index.dart';
import '../../search/index.dart';
import '../../settings/index.dart';
import '../../subject_detail/index.dart';
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
          SearchRoute() => const SearchPage(),
          SubjectDetailRoute(:final subjectId) => SubjectDetailPage(subjectId: subjectId),
          EpisodePlaybackRoute(:final subjectId, :final episodeId) => EpisodePlaybackPage(
            subjectId: subjectId,
            episodeId: episodeId,
          ),
          SettingsRoute() => const SettingsPage(),
        },
      ),
    );
  }
}

class YnekoShell extends ConsumerStatefulWidget {
  const YnekoShell({
    super.key,
    required this.route,
    required this.child,
  });

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
                    onSearchFocusChanged: (focused) => setState(() => _searchFocused = focused),
                    onHomeTabChanged: (index) => setState(() => _homeTab = index),
                    onSearchModeChanged: (index) => setState(() => _searchMode = index),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey(route.runtimeType.toString() + _routeIdentity(route)),
                        child: widget.child,
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

  String _routeIdentity(ShellRoute route) {
    return switch (route) {
      HomeRoute() => 'home',
      SearchRoute() => 'search',
      SubjectDetailRoute(:final subjectId) => 'detail-$subjectId',
      EpisodePlaybackRoute(:final subjectId, :final episodeId) => 'play-$subjectId-$episodeId',
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

    return Container(
      width: 64,
      color: tokens.railSurface,
      padding: const EdgeInsets.fromLTRB(7, 14, 7, 26),
      child: Column(
        children: [
          _RailIconButton(
            icon: Icons.chevron_left_rounded,
            label: '返回',
            active: false,
            onTap: () {
              if (route case EpisodePlaybackRoute(:final subjectId)) {
                controller.openSubjectDetail(subjectId);
              } else {
                controller.openHome();
              }
            },
          ),
          const Spacer(),
          _RailIconButton(
            icon: Icons.home_rounded,
            label: '首页',
            active: route is HomeRoute || route is SearchRoute,
            onTap: controller.openHome,
          ),
          const SizedBox(height: 14),
          _RailIconButton(
            icon: Icons.person_rounded,
            label: '我的',
            active: false,
            onTap: () {},
          ),
          const SizedBox(height: 14),
          _RailIconButton(
            icon: Icons.settings_rounded,
            label: '设置',
            active: route is SettingsRoute,
            onTap: controller.openSettings,
          ),
        ],
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

  final IconData icon;
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
            duration: const Duration(milliseconds: 180),
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
                Icon(widget.icon, color: active ? tokens.primary : tokens.muted, size: 25),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: active ? tokens.primary : tokens.soft,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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
    final width = MediaQuery.sizeOf(context).width;
    final searchWidth = searchFocused ? (width * 0.34).clamp(320.0, 520.0) : (width * 0.24).clamp(260.0, 376.0);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: tokens.page,
        border: Border(bottom: BorderSide(color: tokens.outline.withValues(alpha: 0.48))),
      ),
      child: Row(
        children: [
          const _BrandWord(),
          const SizedBox(width: 28),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: searchFocused ? 0 : 1,
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
                            style: TextStyle(color: tokens.primary, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: searchWidth,
            child: Focus(
              onFocusChange: onSearchFocusChanged,
              child: TextField(
                onSubmitted: (_) => ref.read(shellRouteProvider.notifier).openSearch(),
                decoration: const InputDecoration(
                  hintText: '搜索番剧、标签、角色',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: '切换主题',
            onPressed: () => ref.read(shellThemeModeProvider.notifier).toggle(),
            icon: const Icon(Icons.brightness_6_rounded),
          ),
          const SizedBox(width: 8),
          const _WindowButtons(),
        ],
      ),
    );
  }

  String _pageTitle(ShellRoute route) {
    return switch (route) {
      HomeRoute() => '首页',
      SearchRoute() => '搜索',
      SubjectDetailRoute() => '番剧详情',
      EpisodePlaybackRoute() => '播放详情',
      SettingsRoute() => '设置',
    };
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Y',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: tokens.ink),
            ),
            Text(
              'neko',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: tokens.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Row(
      children: [
        for (final icon in [Icons.remove_rounded, Icons.crop_square_rounded, Icons.close_rounded])
          SizedBox(
            width: 38,
            height: 34,
            child: IconButton(
              tooltip: '窗口控制占位',
              onPressed: () {},
              icon: Icon(icon, size: 16),
              color: icon == Icons.close_rounded ? tokens.danger : tokens.muted,
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
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

  void openSubjectDetail(int subjectId) {
    state = SubjectDetailRoute(subjectId: subjectId);
  }

  void openSettings() {
    state = const SettingsRoute();
  }

  void openEpisodePlayback({
    required int subjectId,
    required int episodeId,
  }) {
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

final shellThemeModeProvider = NotifierProvider<ShellThemeModeController, ThemeMode>(
  ShellThemeModeController.new,
);
