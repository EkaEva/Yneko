import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/features/episode_playback/index.dart';
import 'package:yneko/src/features/shell/index.dart';
import 'package:yneko/src/infrastructure/bridge/yneko_backend.dart';
import 'package:yneko/src/shared/assets/index.dart';
import 'package:yneko/src/shared/theme/index.dart';

import 'support/fake_yneko_backend.dart';

void main() {
  testWidgets('shell renders rail, top tabs, search box, and page content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Yneko'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('返回'), findsNothing);
    expect(find.text('推荐'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('开发预览数据'), findsNothing);
    expect(find.text('排序'), findsNothing);
    expect(find.text('最高热度'), findsNothing);
    expect(find.byKey(const ValueKey('home-anime-grid')), findsOneWidget);
    expect(find.text('今天想看点什么'), findsNothing);
    expect(find.byKey(const ValueKey('rail-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('top-action-divider')), findsOneWidget);
  });

  testWidgets('top search focus changes layout without hiding the input', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索番剧'), findsOneWidget);
    final tabOpacity = tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity).first,
    );
    expect(tabOpacity.opacity, 0);
  });

  testWidgets('shell uses original rail svg assets without whole-icon tint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    final svgPictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(
      svgPictures.any(
        (picture) =>
            picture.bytesLoader.toString().contains(YnekoAssets.railHome),
      ),
      isTrue,
    );
    final railHome = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('rail-svg-${YnekoAssets.railHome}')),
    );
    expect(railHome.colorFilter, isNull);
    final homeLoaderText = railHome.bytesLoader.toString();
    expect(homeLoaderText, contains(YnekoAssets.railHome));
    expect(
      svgPictures.any(
        (picture) =>
            picture.bytesLoader.toString().contains(YnekoAssets.railUser),
      ),
      isTrue,
    );
    expect(
      svgPictures.any(
        (picture) =>
            picture.bytesLoader.toString().contains(YnekoAssets.railSettings),
      ),
      isTrue,
    );
  });

  testWidgets('dark rail icons map project cutouts to rail surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ynekoBackendProvider.overrideWithValue(const FakeYnekoBackend()),
          shellThemeModeProvider.overrideWith(
            () => _FixedThemeModeController(ThemeMode.dark),
          ),
        ],
        child: const YnekoApp(),
      ),
    );

    final railHome = tester.widget<SvgPicture>(
      find.byKey(const ValueKey('rail-svg-${YnekoAssets.railHome}')),
    );
    expect(railHome.colorFilter, isNull);
    final loader = railHome.bytesLoader as SvgLoader<Object?>;
    expect(loader.colorMapper, isNotNull);
    expect(YnekoThemeTokens.dark.railSurface, isNot(const Color(0xFFF2F3F5)));
  });

  testWidgets(
    'topbar brand is text-only and theme toggle keeps original size',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_appWithBackend());

      final logoPictures = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .where(
            (picture) =>
                picture.bytesLoader.toString().contains(YnekoAssets.logoSvg),
          );
      expect(logoPictures, isEmpty);
      expect(find.textContaining('Yneko'), findsOneWidget);

      final toggleSize = tester.getSize(
        find.byKey(const ValueKey('day-night-toggle')),
      );
      expect(toggleSize, const Size(86, 40));
    },
  );

  testWidgets('window buttons match original scale and maximize icon toggles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    for (final tooltip in ['最小化', '最大化', '关闭']) {
      expect(
        tester.getSize(find.byKey(ValueKey('window-button-$tooltip'))),
        const Size(44, 38),
      );
    }

    expect(find.byKey(const ValueKey('window-icon-maximize')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('window-maximize-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('window-icon-restore')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('window-button-还原'))),
      const Size(44, 38),
    );
  });

  testWidgets('home top tabs inherit theme font and mapped MiSans weights', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    AnimatedDefaultTextStyle tabStyleFor(String label) {
      final styles = find.ancestor(
        of: find.text(label).first,
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      return tester
          .widgetList<AnimatedDefaultTextStyle>(styles)
          .firstWhere((style) => style.style.fontSize == 16);
    }

    expect(tabStyleFor('推荐').style.fontFamily, YnekoThemeTokens.fontFamily);
    expect(
      tabStyleFor('推荐').style.fontFamilyFallback,
      YnekoThemeTokens.fontFallback,
    );
    expect(tabStyleFor('推荐').style.fontWeight, FontWeight.w700);
    expect(tabStyleFor('时间表').style.fontWeight, FontWeight.w600);

    await tester.tap(find.text('榜单').first);
    await tester.pumpAndSettle();

    final filterText = tester.widget<Text>(find.text('推理').first);
    expect(filterText.style?.fontFamily, YnekoThemeTokens.fontFamily);
    expect(filterText.style?.fontFamilyFallback, YnekoThemeTokens.fontFallback);
  });

  testWidgets('settings renders root groups and navigates into detail panels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-root-page')), findsOneWidget);
    expect(find.text('常规'), findsOneWidget);
    expect(find.text('播放设置'), findsOneWidget);
    expect(find.text('数据与备份'), findsOneWidget);
    expect(find.text('下载设置'), findsOneWidget);
    expect(find.text('规则管理'), findsOneWidget);
    expect(find.byKey(const ValueKey('yneko-profile-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-avatar-logo')), findsOneWidget);

    await tester.tap(find.text('外观').first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-detail-appearance')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings-detail-back')), findsNothing);
    expect(find.text('返回设置'), findsNothing);
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.text('配色方案'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rail-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-root-page')), findsOneWidget);

    await tester.tap(find.text('规则管理').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-detail-rules')), findsOneWidget);
    expect(find.text('导入规则源'), findsOneWidget);
    expect(find.text('规则编辑器'), findsOneWidget);
  });

  testWidgets('mine page renders empty profile shell without fake list data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mine-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-profile-card')), findsOneWidget);
    expect(find.text('追番'), findsWidgets);
    expect(find.text('历史'), findsWidgets);
    expect(find.text('缓存'), findsWidgets);
    expect(find.byKey(const ValueKey('mine-local-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('yneko-profile-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-avatar-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-empty-prompt')), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-cover-grid')), findsNothing);
    expect(find.text('星轨回响 第 1-3 话'), findsNothing);

    await tester.tap(find.text('缓存').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mine-empty-prompt')), findsOneWidget);
    expect(find.text('星轨回响 第 1-3 话'), findsNothing);
  });

  testWidgets('search route renders result page chrome and horizontal cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.enterText(find.byType(TextField).first, '星轨');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-result-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-heading')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-mode-toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-grid')), findsOneWidget);
    expect(find.text('已经到底了'), findsOneWidget);
  });

  testWidgets('theme toggle keeps sun halo attached to the clipped sun orb', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    expect(find.byKey(const ValueKey('toggle-sky')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-capsule-clip')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-orb')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-halo-outer')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-halo-inner')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-cloud-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-cloud-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-c')), findsOneWidget);

    final toggleStack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byKey(const ValueKey('day-night-toggle')),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(toggleStack.clipBehavior, Clip.hardEdge);

    final capsuleClip = tester.widget<ClipRRect>(
      find.byKey(const ValueKey('toggle-capsule-clip')),
    );
    expect(capsuleClip.borderRadius, BorderRadius.circular(999));

    final haloAncestor = find
        .ancestor(
          of: find.byKey(const ValueKey('toggle-halo-outer')),
          matching: find.byKey(const ValueKey('toggle-orb')),
        )
        .first;
    expect(haloAncestor, findsOneWidget);

    final orbStack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byKey(const ValueKey('toggle-orb')),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(orbStack.clipBehavior, Clip.none);
  });

  testWidgets('theme toggle keeps clouds and stars mounted while switching', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.tap(find.byKey(const ValueKey('day-night-toggle')));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('toggle-cloud-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-cloud-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-c')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('toggle-cloud-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-cloud-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle-star-c')), findsOneWidget);
  });

  testWidgets('home top tabs switch to original schedule and ranking panels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    await tester.tap(find.text('时间表').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-schedule-panel')), findsOneWidget);
    expect(find.text('日期'), findsOneWidget);
    expect(find.text('年份'), findsWidgets);
    expect(find.text('季度'), findsWidgets);
    expect(
      find.byKey(const ValueKey('schedule-random-button')),
      findsOneWidget,
    );
    expect(find.text('新番时光机'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('filter-option-周一'))).width,
      lessThan(80),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('filter-option-周一'))).dy,
      tester.getTopLeft(find.byKey(const ValueKey('filter-option-周二'))).dy,
    );

    await tester.tap(find.text('榜单').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-ranking-panel')), findsOneWidget);
    expect(find.text('排序'), findsOneWidget);
    expect(find.text('地区'), findsOneWidget);
    expect(find.text('类型'), findsOneWidget);
    expect(find.text('来源'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('年份'), findsWidgets);
    expect(find.text('季度'), findsWidgets);
    expect(find.text('更多筛选'), findsOneWidget);
  });

  testWidgets('home poster card click opens subject detail route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    await tester.pumpAndSettle();
    await tester.tap(find.text('mono女孩').first);
    await tester.pumpAndSettle();

    expect(find.text('番剧详情'), findsOneWidget);
  });

  testWidgets(
    'episode playback page has full detail player and right panel tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EpisodePlaybackPage(subjectId: 1001, episodeId: 100101),
          ),
        ),
      );

      expect(find.text('等待播放源'), findsOneWidget);
      expect(find.text('剧集'), findsOneWidget);
      expect(find.text('系列'), findsOneWidget);
      expect(find.text('规则源'), findsOneWidget);
      expect(find.byKey(const ValueKey('episode-list-panel')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('episode-layout-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('episode-grid-panel')), findsOneWidget);

      await tester.tap(find.text('规则源'));
      await tester.pumpAndSettle();
      expect(find.text('导出矩阵'), findsOneWidget);
      expect(find.text('默认规则组'), findsWidgets);
    },
  );

  testWidgets('theme tokens are available in light and dark themes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ynekoTheme(Brightness.light),
        darkTheme: ynekoTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            final tokens = YnekoThemeTokens.of(context);
            final theme = Theme.of(context);
            return Text(
              'primary-${tokens.primary.toARGB32()} '
              'font-${theme.textTheme.bodyMedium?.fontFamily} '
              'fallback-${theme.textTheme.bodyMedium?.fontFamilyFallback?.join(',')}',
            );
          },
        ),
      ),
    );

    expect(find.textContaining('primary-'), findsOneWidget);
    expect(find.textContaining('font-MiSansYneko'), findsOneWidget);
    expect(find.textContaining('Microsoft YaHei UI'), findsOneWidget);
  });

  test('dark theme separates the rail from the content canvas', () {
    final tokens = YnekoThemeTokens.dark;
    expect(
      tokens.railSurface.computeLuminance(),
      lessThan(tokens.page.computeLuminance()),
    );
    expect(
      tokens.page.computeLuminance() - tokens.railSurface.computeLuminance(),
      greaterThan(0.002),
    );
    expect(
      tokens.dividerSoft.computeLuminance(),
      greaterThan(tokens.page.computeLuminance()),
    );
  });

  test('YnekoAssets exposes required project-owned assets', () {
    expect(YnekoAssets.logoSvg, 'assets/icons/Yneko/logo.svg');
    expect(YnekoAssets.railHome, 'assets/icons/rail/home.svg');
    expect(YnekoAssets.railUser, 'assets/icons/rail/user.svg');
    expect(YnekoAssets.railSettings, 'assets/icons/rail/settings.svg');
    expect(YnekoAssets.required, contains(YnekoAssets.empty));
    expect(YnekoAssets.required, contains(YnekoAssets.railHome));
    expect(YnekoAssets.required, contains(YnekoAssets.playerPlay));
  });
}

class _FixedThemeModeController extends ShellThemeModeController {
  _FixedThemeModeController(this._mode);

  final ThemeMode _mode;

  @override
  ThemeMode build() => _mode;
}

Widget _appWithBackend() {
  return ProviderScope(
    overrides: [
      ynekoBackendProvider.overrideWithValue(const FakeYnekoBackend()),
    ],
    child: const YnekoApp(),
  );
}
