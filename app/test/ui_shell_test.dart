import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/features/home/application/home_providers.dart';
import 'package:yneko/src/features/search/index.dart';
import 'package:yneko/src/features/shell/index.dart';
import 'package:yneko/src/features/watch/application/watch_providers.dart';
import 'package:yneko/src/infrastructure/bridge/yneko_backend.dart';
import 'package:yneko/src/infrastructure/platform/directory_picker/index.dart';
import 'package:yneko/src/shared/assets/index.dart';
import 'package:yneko/src/shared/domain/index.dart';
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

    final backend = FakeYnekoBackend();
    await tester.pumpWidget(_appWithBackend(backend: backend));

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索动画'), findsOneWidget);
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
          ynekoBackendProvider.overrideWithValue(
            FakeYnekoBackend(
              appearanceSettings: const AppearanceSettings(
                themeMode: ThemeMode.dark,
                colorScheme: YnekoColorScheme.yneko,
              ),
            ),
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

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('window-button-关闭'))),
    );
    await tester.pumpAndSettle();

    final closeButton = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('window-button-关闭')),
    );
    final closeDecoration = closeButton.decoration! as BoxDecoration;
    expect(closeDecoration.color, const Color(0xFFFF5C7A));
  });

  testWidgets('rail hover only recolors icons and keeps transparent surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    final mineButton = find.byKey(const ValueKey('rail-button-我的'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(mineButton));
    await tester.pumpAndSettle();

    final railButton = tester.widget<AnimatedContainer>(mineButton);
    final decoration = railButton.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);

    final mineLabel = tester.widget<Text>(find.text('我的').first);
    expect(mineLabel.style?.color, YnekoThemeTokens.light.primary);
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

  testWidgets('single top tabs align to home tab without underline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.pumpAndSettle();

    final homeLeft = tester.getTopLeft(_topTabText(tester, '推荐')).dx;
    final homeStyle = _topTabStyle(tester, '推荐').style;

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    final mine = _topTabText(tester, '我的');
    expect(tester.getTopLeft(mine).dx, closeTo(homeLeft, 0.01));
    expect(_topTabStyle(tester, '我的').style.fontFamily, homeStyle.fontFamily);
    expect(
      _topTabStyle(tester, '我的').style.fontFamilyFallback,
      homeStyle.fontFamilyFallback,
    );
    expect(find.byKey(const ValueKey('top-tab-underline-我的')), findsNothing);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    final settings = _topTabText(tester, '设置');
    expect(tester.getTopLeft(settings).dx, closeTo(homeLeft, 0.01));
    expect(find.byKey(const ValueKey('top-tab-underline-设置')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-entry-外观')));
    await tester.pumpAndSettle();
    final detail = _topTabText(tester, '外观');
    expect(tester.getTopLeft(detail).dx, closeTo(homeLeft, 0.01));
    expect(find.byKey(const ValueKey('top-tab-underline-外观')), findsNothing);
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

    final downloadEntry = find.byKey(const ValueKey('settings-entry-下载设置'));
    final idleEntry = tester.widget<AnimatedContainer>(downloadEntry);
    final idleDecoration = idleEntry.decoration! as BoxDecoration;
    expect(idleDecoration.color, YnekoThemeTokens.light.surface);
    expect(idleDecoration.color, isNot(Colors.transparent));
    expect(
      find.ancestor(of: downloadEntry, matching: find.byType(ClipRRect)),
      findsWidgets,
    );

    final settingsMouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await settingsMouse.addPointer();
    await settingsMouse.moveTo(tester.getCenter(downloadEntry));
    await tester.pumpAndSettle();

    final hoveredEntry = tester.widget<AnimatedContainer>(downloadEntry);
    final hoveredDecoration = hoveredEntry.decoration! as BoxDecoration;
    expect(
      hoveredDecoration.color,
      Color.lerp(
        YnekoThemeTokens.light.surfaceHigh,
        YnekoThemeTokens.light.surface,
        0.12,
      ),
    );
    expect(
      hoveredDecoration.color,
      isNot(YnekoThemeTokens.light.primaryContainer),
    );
    await settingsMouse.removePointer();

    await tester.tap(downloadEntry);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-detail-download')),
      findsOneWidget,
    );
    expect(find.text('保存位置'), findsOneWidget);
    expect(find.text('下载路径'), findsOneWidget);
    expect(find.text('D:\\Yneko\\Downloads'), findsOneWidget);
    expect(find.text('任务设置'), findsOneWidget);
    expect(find.text('并发任务'), findsOneWidget);
    expect(find.text('同时下载的任务数量'), findsOneWidget);
    await tester.tap(find.byTooltip('增加'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('增加'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('增加'));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing);
    expect(find.text('下载策略'), findsOneWidget);
    expect(find.text('自动'), findsWidgets);
    expect(find.text('仅 Wi-Fi'), findsOneWidget);
    expect(find.text('手动确认'), findsOneWidget);
    expect(find.text('文件命名'), findsOneWidget);
    expect(find.text('命名规范'), findsOneWidget);
    expect(find.text('葬送的芙莉莲/S01E01.mp4'), findsOneWidget);
    expect(find.text('下载与离线缓存不在 V1 范围内，本页先保留完整设置入口。'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-entry-下载路径')));
    await tester.pumpAndSettle();
    expect(find.text('系统下载目录'), findsOneWidget);
    expect(find.text('使用系统常用下载位置'), findsOneWidget);
    expect(find.text('Yneko 默认目录'), findsOneWidget);
    expect(find.text('按应用独立归档'), findsOneWidget);
    expect(find.text('自定义路径'), findsOneWidget);
    expect(find.text('在下方输入保存位置'), findsOneWidget);
    expect(find.text('保存位置'), findsWidgets);
    await tester.tap(find.text('自定义路径'));
    await tester.pumpAndSettle();
    expect(find.text('E:\\Yneko\\Picked'), findsOneWidget);
    expect(find.text('桌面端会打开文件夹选择器，当前预览环境可手动输入路径。'), findsNothing);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭下载路径'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-entry-命名规范')));
    await tester.pumpAndSettle();
    expect(find.text('番剧名/集数'), findsOneWidget);
    expect(find.text('番剧名 - S01E01'), findsOneWidget);
    expect(find.text('番剧名/季度/集数'), findsOneWidget);
    expect(find.text('自定义模板'), findsOneWidget);
    expect(find.text('预览'), findsOneWidget);
    expect(find.text('葬送的芙莉莲/S01E01.mp4'), findsWidgets);
    await tester.tap(find.text('番剧名 - S01E01'));
    await tester.pumpAndSettle();
    expect(find.text('葬送的芙莉莲 - S01E01.mp4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-entry-命名规范')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义模板'));
    await tester.pumpAndSettle();
    expect(find.text('自定义模板'), findsWidgets);
    expect(find.text('{title}/S{season}E{episode}'), findsWidgets);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭命名规范'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rail-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-root-page')), findsOneWidget);

    await tester.tap(find.text('外观').first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-detail-appearance')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings-detail-back')), findsNothing);
    expect(find.text('返回设置'), findsNothing);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('主题配色'), findsOneWidget);
    expect(find.text('字体设置'), findsOneWidget);
    expect(find.text('启动页设置'), findsOneWidget);
    expect(find.text('默认模式'), findsOneWidget);
    expect(find.text('配色方案'), findsOneWidget);
    expect(find.text('启动后打开'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('settings-entry-默认模式')),
        matching: find.byType(ClipRRect),
      ),
      findsWidgets,
    );
    final fontEntry = find.byKey(const ValueKey('settings-entry-使用系统字体'));
    final fontMouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await fontMouse.addPointer();
    await fontMouse.moveTo(tester.getCenter(fontEntry));
    await tester.pumpAndSettle();
    final hoveredFontEntry = tester.widget<AnimatedContainer>(fontEntry);
    final hoveredFontDecoration = hoveredFontEntry.decoration! as BoxDecoration;
    expect(
      hoveredFontDecoration.color,
      Color.lerp(
        YnekoThemeTokens.light.surfaceHigh,
        YnekoThemeTokens.light.surface,
        0.12,
      ),
    );
    await fontMouse.removePointer();

    await tester.tap(find.byKey(const ValueKey('settings-entry-配色方案')));
    await tester.pumpAndSettle();
    expect(YnekoColorScheme.values, hasLength(16));
    for (final scheme in YnekoColorScheme.values) {
      expect(
        find.byKey(ValueKey('settings-color-scheme-option-${scheme.label}')),
        findsOneWidget,
      );
    }
    final firstOption = find.byKey(
      const ValueKey('settings-color-scheme-option-Yneko 粉'),
    );
    final eighthOption = find.byKey(
      const ValueKey('settings-color-scheme-option-珊瑚红'),
    );
    final ninthOption = find.byKey(
      const ValueKey('settings-color-scheme-option-琥珀黄'),
    );
    expect(
      (tester.getCenter(firstOption).dy - tester.getCenter(eighthOption).dy)
          .abs(),
      lessThan(1),
    );
    expect(
      tester.getCenter(ninthOption).dy,
      greaterThan(tester.getCenter(firstOption).dy + 80),
    );
    await tester.tap(find.text('湖水蓝'));
    await tester.pumpAndSettle();
    expect(find.text('湖水蓝'), findsOneWidget);
    final cyanTokens = Theme.of(
      tester.element(find.byKey(const ValueKey('settings-detail-appearance'))),
    ).extension<YnekoThemeTokens>()!;
    expect(cyanTokens.primary, const Color(0xFF2BA7B8));
    expect(cyanTokens.page, const Color(0xFFFAFEFF));
    expect(cyanTokens.railSurface, const Color(0xFFE9F8FA));
    final activeSettingsTokens = cyanTokens;

    await tester.tap(find.byKey(const ValueKey('rail-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-root-page')), findsOneWidget);

    await tester.tap(find.text('播放器设置').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-detail-player')),
      findsOneWidget,
    );
    expect(find.text('播放引擎'), findsWidgets);
    expect(find.text('画面设置'), findsOneWidget);
    expect(find.text('视频比例'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('settings-entry-播放引擎')),
        matching: find.byType(ClipRRect),
      ),
      findsWidgets,
    );
    await tester.tap(find.byKey(const ValueKey('settings-entry-视频比例')));
    await tester.pumpAndSettle();
    expect(find.text('适应窗口'), findsOneWidget);
    expect(find.text('填充窗口'), findsOneWidget);
    await tester.tap(find.text('适应窗口').last);
    await tester.pumpAndSettle();
    expect(find.text('适应窗口'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('rail-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-root-page')), findsOneWidget);

    await tester.tap(find.text('规则管理').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-detail-rules')), findsOneWidget);
    expect(find.text('规则管理'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-source-import-open')),
      findsNothing,
    );
    expect(find.text('规则组'), findsOneWidget);
    expect(find.text('默认规则组'), findsOneWidget);
    expect(find.text('采集插件组'), findsOneWidget);
    expect(find.text('播放插件组'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('rule-group-create-open')),
      findsOneWidget,
    );

    final defaultRuleRow = find.byKey(const ValueKey('source-row-默认规则组'));
    final idleRuleRow = tester.widget<AnimatedContainer>(defaultRuleRow);
    final idleRuleDecoration = idleRuleRow.decoration! as BoxDecoration;
    expect(idleRuleDecoration.color, activeSettingsTokens.surface);
    expect(idleRuleDecoration.color, isNot(Colors.transparent));
    expect(
      find.ancestor(of: defaultRuleRow, matching: find.byType(ClipRRect)),
      findsWidgets,
    );
    final ruleGroupContainer = tester
        .widgetList<Container>(
          find.ancestor(of: defaultRuleRow, matching: find.byType(Container)),
        )
        .firstWhere((container) => container.foregroundDecoration != null);
    final ruleGroupForeground =
        ruleGroupContainer.foregroundDecoration! as BoxDecoration;
    expect(
      (ruleGroupForeground.border! as Border).top.color,
      activeSettingsTokens.outline.withValues(alpha: 0.58),
    );

    final ruleMouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await ruleMouse.addPointer();
    await ruleMouse.moveTo(tester.getCenter(defaultRuleRow));
    await tester.pumpAndSettle();

    final hoveredRuleRow = tester.widget<AnimatedContainer>(defaultRuleRow);
    final hoveredRuleDecoration = hoveredRuleRow.decoration! as BoxDecoration;
    expect(
      hoveredRuleDecoration.color,
      Color.lerp(
        activeSettingsTokens.surfaceHigh,
        activeSettingsTokens.surface,
        0.12,
      ),
    );
    expect(
      hoveredRuleDecoration.color,
      isNot(activeSettingsTokens.primaryContainer),
    );
    await ruleMouse.removePointer();

    await tester.tap(find.byKey(const ValueKey('rule-group-default')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rule-repository-import-open')));
    await tester.pumpAndSettle();
    expect(find.text('KazumiRules'), findsOneWidget);
    expect(find.text('支持 GitHub 仓库地址或 raw index.json。'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);

    final menu = find.byKey(
      const ValueKey('rule-repository-subscription-menu'),
    );
    expect(menu, findsOneWidget);
    await tester.ensureVisible(menu);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(menu));
    await tester.pump(const Duration(milliseconds: 180));
    expect(
      find.byKey(const ValueKey('rule-repository-subscription-trigger')),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('rule-repository-refresh-slot')),
      ),
      const Size(104, 40),
    );
    final refreshButton = find.byKey(
      const ValueKey('rule-repository-refresh-button'),
    );
    expect(refreshButton, findsOneWidget);
    expect(tester.getSize(refreshButton).width, 104);
    expect(tester.getSize(refreshButton).height, 40);
    expect(
      find.byKey(const ValueKey('yneko-hover-menu-option-KazumiRules')),
      findsOneWidget,
    );
    final subscriptionOption = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('yneko-hover-menu-option-KazumiRules')),
    );
    final subscriptionDecoration =
        subscriptionOption.decoration! as BoxDecoration;
    expect(subscriptionDecoration.color, activeSettingsTokens.surface);
    expect(subscriptionDecoration.color, isNot(Colors.transparent));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('yneko-hover-menu-panel')))
          .width,
      lessThan(340),
    );
    await tester.tap(
      find.byKey(const ValueKey('yneko-hover-menu-option-KazumiRules')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('yneko-hover-menu-option-KazumiRules')),
      findsNothing,
    );
    await mouse.removePointer();

    await tester.tap(
      find.byKey(const ValueKey('rule-repository-refresh-button')),
    );
    await tester.pump();
    expect(tester.getSize(refreshButton).width, 104);
    await tester.pumpAndSettle();
    expect(tester.getSize(refreshButton).width, 104);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rule-source-editor-open')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('source-editor-mode-segmented')),
      findsOneWidget,
    );
    final modeTrack = tester.widget<Container>(
      find.byKey(const ValueKey('source-editor-mode-segmented')),
    );
    final modeTrackDecoration = modeTrack.decoration! as BoxDecoration;
    expect(modeTrackDecoration.color, activeSettingsTokens.surfaceLow);

    AnimatedPositioned modeThumb() => tester.widget<AnimatedPositioned>(
      find.byKey(const ValueKey('source-editor-mode-thumb')),
    );
    final visualThumb = modeThumb();
    expect(visualThumb.left, 0);
    final thumbBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('source-editor-mode-thumb')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final thumbDecoration = thumbBox.decoration as BoxDecoration;
    expect(thumbDecoration.color, activeSettingsTokens.surface);

    await tester.tap(find.byKey(const ValueKey('source-editor-mode-config')));
    await tester.pumpAndSettle();
    expect(modeThumb().left, 74);
    final configItem = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('source-editor-mode-config')),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(configItem.width, 74);
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
    final mineTabPanel = find.byKey(const ValueKey('mine-tabs-panel'));
    final mineLibraryTabFinder = find.descendant(
      of: mineTabPanel,
      matching: find.text('追番'),
    );
    final mineHistoryTabFinder = find.descendant(
      of: mineTabPanel,
      matching: find.text('历史'),
    );
    final mineLibraryTab = tester.widget<Text>(mineLibraryTabFinder);
    final mineHistoryTab = tester.widget<Text>(mineHistoryTabFinder);
    expect(mineLibraryTab.style?.fontWeight, FontWeight.w800);
    expect(mineHistoryTab.style?.fontWeight, FontWeight.w800);
    expect(
      tester.getSize(find.byKey(const ValueKey('mine-tab-underline-追番'))).width,
      36,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('mine-tab-underline-追番'))).dx,
      closeTo(tester.getCenter(mineLibraryTabFinder).dx, 0.01),
    );
    expect(find.byKey(const ValueKey('mine-local-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('yneko-profile-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-avatar-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-empty-prompt')), findsOneWidget);
    expect(find.text('这里什么都没有喵～\n快去追番吧（=^･ω･^=）'), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-cover-grid')), findsNothing);
    expect(find.text('星轨回响 第 1-3 话'), findsNothing);

    final idleSearch = tester.widget<TextField>(
      find.byKey(const ValueKey('mine-local-search')),
    );
    final idleSearchDecoration = idleSearch.decoration!;
    final idleSearchFrame = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('mine-local-search-frame')),
    );
    final idleSearchFrameDecoration =
        idleSearchFrame.decoration! as BoxDecoration;
    expect(idleSearchFrameDecoration.color, YnekoThemeTokens.light.surface);
    expect(idleSearchDecoration.fillColor, Colors.transparent);
    expect(idleSearchDecoration.hintText, '搜索我的追番');
    expect(
      idleSearchDecoration.hintStyle?.color,
      YnekoThemeTokens.light.muted.withValues(alpha: 0.72),
    );
    expect(
      (idleSearchDecoration.suffixIcon! as Icon).color,
      YnekoThemeTokens.light.muted,
    );
    expect(
      idleSearchFrameDecoration.border!.top.color,
      YnekoThemeTokens.light.outline.withValues(alpha: 0.66),
    );
    expect(idleSearchFrameDecoration.border!.top.width, 1);

    final searchMouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await searchMouse.addPointer();
    await searchMouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('mine-local-search-frame'))),
    );
    await tester.pumpAndSettle();
    final hoveredSearchFrame = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('mine-local-search-frame')),
    );
    final hoveredSearchFrameDecoration =
        hoveredSearchFrame.decoration! as BoxDecoration;
    expect(hoveredSearchFrameDecoration.color, YnekoThemeTokens.light.surface);
    await searchMouse.removePointer();

    await tester.tap(find.byKey(const ValueKey('mine-local-search')));
    await tester.pumpAndSettle();
    final focusedSearchFrame = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('mine-local-search-frame')),
    );
    final focusedSearchFrameDecoration =
        focusedSearchFrame.decoration! as BoxDecoration;
    expect(focusedSearchFrameDecoration.color, YnekoThemeTokens.light.surface);
    expect(
      focusedSearchFrameDecoration.border!.top.color,
      Color.lerp(
        YnekoThemeTokens.light.outline,
        YnekoThemeTokens.light.primary,
        0.48,
      ),
    );
    expect(focusedSearchFrameDecoration.border!.top.width, 1);
    expect(focusedSearchFrameDecoration.boxShadow, isNotNull);
    expect(focusedSearchFrameDecoration.boxShadow!.single.blurRadius, 22);

    final focusedSearch = tester.widget<TextField>(
      find.byKey(const ValueKey('mine-local-search')),
    );
    expect(
      (focusedSearch.decoration!.suffixIcon! as Icon).color,
      YnekoThemeTokens.light.muted,
    );

    final statusMouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await statusMouse.addPointer();
    await statusMouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('mine-status-trigger'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsWidgets);
    expect(
      find.byKey(const ValueKey('yneko-hover-menu-option-全部')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('yneko-hover-menu-option-搁置')),
      findsOneWidget,
    );
    final idleMenuOption = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('yneko-hover-menu-option-搁置')),
    );
    final idleMenuDecoration = idleMenuOption.decoration! as BoxDecoration;
    expect(idleMenuDecoration.color, YnekoThemeTokens.light.surface);
    expect(idleMenuDecoration.color, isNot(Colors.transparent));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('yneko-hover-menu-panel')))
          .width,
      lessThan(180),
    );
    await statusMouse.moveTo(const Offset(40, 40));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('yneko-hover-menu-option-搁置')),
      findsNothing,
    );
    await statusMouse.removePointer();

    await tester.tap(find.text('缓存').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mine-empty-prompt')), findsOneWidget);
    expect(find.text('星轨回响 第 1-3 话'), findsNothing);
  });

  testWidgets('search route renders real results and keeps top input text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final backend = FakeYnekoBackend();
    await tester.pumpWidget(_appWithBackend(backend: backend));
    await tester.enterText(
      find.byKey(const ValueKey('top-search-field')),
      '芙莉莲',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-result-page')), findsOneWidget);
    expect(backend.searchRequests.single, (query: '芙莉莲', page: 1));
    expect(find.byKey(const ValueKey('search-heading')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-back-button')), findsNothing);
    expect(find.byKey(const ValueKey('search-page-input')), findsNothing);
    expect(find.byKey(const ValueKey('search-mode-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('search-grid')), findsOneWidget);
    expect(
      find.byKey(ValueKey('search-result-card-${FakeYnekoBackend.subject.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('anime-poster-title-highlight')),
      findsWidgets,
    );
    expect(find.text('已经到底了'), findsOneWidget);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('首页').last);
    await tester.pumpAndSettle();
    final topSearch = tester.widget<TextField>(
      find.byKey(const ValueKey('top-search-field')),
    );
    expect(topSearch.controller!.text, '芙莉莲');

    ProviderScope.containerOf(
      tester.element(find.byType(YnekoApp)),
    ).read(shellRouteProvider.notifier).openSearch();
    await tester.pumpAndSettle();
    ProviderScope.containerOf(
      tester.element(find.byType(YnekoApp)),
    ).read(shellRouteProvider.notifier).openHome();
    await tester.pumpAndSettle();
    final clearedTopSearch = tester.widget<TextField>(
      find.byKey(const ValueKey('top-search-field')),
    );
    expect(clearedTopSearch.controller!.text, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('top-search-field')),
      '芙莉莲',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('top-search-field')));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('search-result-card-${FakeYnekoBackend.subject.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('watch-page')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('rail-back-button')), findsNothing);
  });

  testWidgets('search history appears below top search and can be reused', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final backend = FakeYnekoBackend(initialSearchHistory: const ['既有历史']);
    await tester.pumpWidget(_appWithBackend(backend: backend));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('top-search-field')),
      '星轨',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(backend.savedSearchHistory.last.first, '星轨');

    await tester.tap(find.byKey(const ValueKey('top-search-field')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('search-history-popover')),
      findsOneWidget,
    );
    final popover = find.byKey(const ValueKey('search-history-popover'));
    expect(
      find.descendant(of: popover, matching: find.text('星轨')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: popover, matching: find.text('既有历史')),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: popover, matching: find.text('星轨')));
    await tester.pumpAndSettle();
    expect(backend.searchRequests.last, (query: '星轨', page: 1));

    await tester.tap(find.byKey(const ValueKey('top-search-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('清空历史'));
    await tester.pumpAndSettle();
    expect(backend.savedSearchHistory.last, isEmpty);
    expect(find.byKey(const ValueKey('search-history-popover')), findsNothing);
  });

  testWidgets('search history popover uses focused search target width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1680, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _appWithBackend(
        backend: FakeYnekoBackend(initialSearchHistory: const ['你好']),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('top-search-field')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final popoverSize = tester.getSize(
      find.byKey(const ValueKey('search-history-popover')),
    );
    final searchContainerSize = tester.getSize(
      find.byKey(const ValueKey('top-search-container')),
    );
    expect(popoverSize.width, greaterThanOrEqualTo(searchContainerSize.width));
  });

  testWidgets('search auto loads more results and dedupes subjects', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final firstPage = [
      for (var index = 0; index < searchPageLimit; index++)
        _searchSubject(8000 + index, '搜索条目$index'),
    ];
    final backend = FakeYnekoBackend(
      searchPages: [
        firstPage,
        [firstPage.first, _searchSubject(9000, '追加条目')],
      ],
    );

    await tester.pumpWidget(_appWithBackend(backend: backend));
    await tester.enterText(
      find.byKey(const ValueKey('top-search-field')),
      '分页',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(backend.searchRequests, contains((query: '分页', page: 1)));
    expect(
      find.byKey(const ValueKey('search-result-card-8000')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('search-result-page')),
      const Offset(0, -2800),
    );
    await tester.pumpAndSettle();

    expect(backend.searchRequests, contains((query: '分页', page: 2)));
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('search-result-page'))),
    );
    expect(container.read(searchControllerProvider).subjects.length, 25);
    expect(
      find.byKey(const ValueKey('search-result-card-9000')),
      findsOneWidget,
    );
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
    expect(find.byKey(const ValueKey('schedule-random-button')), findsNothing);
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

  testWidgets('home ranking filters map to Bangumi ranking requests', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final backend = FakeYnekoBackend();
    await tester.pumpWidget(_appWithBackend(backend: backend));
    await tester.tap(find.text('榜单').first);
    await tester.pumpAndSettle();

    await _tapFilterOption(tester, '排名');
    await _tapFilterOption(tester, '日本');
    await _tapFilterOption(tester, '推理');
    final request = backend.rankingRequests.last;
    expect(request.sort, AnimeRankingSort.rank);
    expect(request.filters['region'], '日本');
    expect(request.filters['type'], '推理');
    expect(request.page, 1);
    expect(request.limit, 24);

    final mappingBackend = FakeYnekoBackend();
    final container = ProviderContainer(
      overrides: [ynekoBackendProvider.overrideWithValue(mappingBackend)],
    );
    addTearDown(container.dispose);
    final filters = container.read(homeRankingFiltersProvider.notifier);
    filters.setSort(AnimeRankingSort.heat);
    filters.setFilter('category', '动态漫画');
    filters.setYear(2025);
    filters.setSeason(AnimeSeason.spring);
    final mappedState = await container.read(homeRankingProvider.future);

    final mappedRequest = mappingBackend.rankingRequests.last;
    expect(mappedRequest.filters['category'], '动态漫画');
    expect(mappedRequest.filterGroup, 'category');
    expect(mappedRequest.filter, 'anime_comic');
    expect(mappedRequest.year, 2025);
    expect(mappedRequest.season, AnimeSeason.spring);
    expect(
      rankingResponseSummary(
        mappedState.applied,
        container.read(homeRankingFiltersProvider),
      ),
      '热度 · 动态漫画 · 2025 4月',
    );
  });

  testWidgets(
    'home ranking auto loads more, dedupes, and reports append failure',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const rankingSubject = AnimeSubject(
        id: 7001,
        name: 'Ranking A',
        nameCn: '榜单 A',
        airDate: '2025-04-01',
      );
      const secondRankingSubject = AnimeSubject(
        id: 7002,
        name: 'Ranking B',
        nameCn: '榜单 B',
        airDate: '2025-04-02',
      );
      final backend = FakeYnekoBackend(
        rankingPages: const [
          [rankingSubject],
          [rankingSubject, secondRankingSubject],
        ],
      );
      await tester.pumpWidget(_appWithBackend(backend: backend));
      await tester.tap(find.text('榜单').first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ranking-load-more-button')),
        findsNothing,
      );
      await tester.drag(
        find.byKey(const ValueKey('home-tab-panel-2')),
        const Offset(0, -900),
      );
      await tester.pump(const Duration(milliseconds: 240));

      expect(
        backend.rankingRequests.map((request) => request.page),
        contains(2),
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.text('榜单 A'), findsOneWidget);
      expect(find.text('榜单 B'), findsOneWidget);
      expect(find.text('已经到底了'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final failingBackend = FakeYnekoBackend(
        rankingPages: const [
          [rankingSubject],
          [secondRankingSubject],
        ],
        rankingErrorPage: 2,
      );
      await tester.pumpWidget(_appWithBackend(backend: failingBackend));
      await tester.tap(find.text('榜单').first);
      await tester.pump(const Duration(milliseconds: 240));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 240));
      await tester.drag(
        find.byKey(const ValueKey('home-tab-panel-2')),
        const Offset(0, -900),
      );
      await tester.pump(const Duration(milliseconds: 240));

      expect(find.text('继续加载失败'), findsOneWidget);
      expect(find.textContaining('ranking page 2 failed'), findsOneWidget);
    },
  );

  testWidgets('home back-to-top appears after scrolling home tabs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final subjects = [
      for (var index = 0; index < 24; index++)
        AnimeSubject(
          id: 8000 + index,
          name: 'Scroll $index',
          nameCn: '滚动 $index',
          airDate: '2025-04-01',
        ),
    ];
    await tester.pumpWidget(
      _appWithBackend(backend: FakeYnekoBackend(rankingPages: [subjects])),
    );
    await tester.tap(find.text('榜单').first);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-back-top-button')), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('home-back-top-opacity')),
          )
          .opacity,
      0,
    );

    await tester.drag(
      find.byKey(const ValueKey('home-tab-panel-2')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('home-back-top-opacity')),
          )
          .opacity,
      1,
    );
    await tester.tap(find.byKey(const ValueKey('home-back-top-button')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'home schedule archive uses browse requests and weekday buckets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const archivedSubject = AnimeSubject(
        id: 9001,
        name: 'Archive Sunday',
        nameCn: '归档周日',
        airDate: '2025-04-13',
        totalEpisodes: 12,
      );
      final backend = FakeYnekoBackend(
        browseSubjectsResult: const [archivedSubject],
      );
      await tester.pumpWidget(_appWithBackend(backend: backend));
      await tester.tap(find.text('时间表').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('outline-action-新番时光机')));
      await tester.pumpAndSettle();
      await _tapFilterOption(tester, '2025');
      await _tapFilterOption(tester, '4月');
      await _tapFilterOption(tester, '周日');
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      final requestedMonths = backend.browseRequests
          .map((request) => request.month)
          .toList(growable: false);
      expect(requestedMonths.skip(requestedMonths.length - 3), [4, 5, 6]);
      expect(find.text('归档周日'), findsOneWidget);
      expect(find.text('2025年4月新番'), findsOneWidget);
    },
  );

  testWidgets('home schedule time machine expands archive filters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.tap(find.text('时间表').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('outline-action-新番时光机')));
    await tester.pumpAndSettle();

    expect(find.text('新番时光机'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-random-button')), findsNothing);
    expect(find.byKey(const ValueKey('filter-option-全年')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-schedule-panel')), findsOneWidget);
  });

  testWidgets('home recommendation loading uses metallic shimmer cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final backend = _PendingHomeBackend();
    await tester.pumpWidget(_appWithBackend(backend: backend));
    await tester.pump();

    expect(find.byKey(const ValueKey('home-shimmer-grid')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-shimmer-grid-view')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-shimmer-card')), findsWidgets);
    expect(find.byKey(const ValueKey('home-shimmer-block')), findsWidgets);
    expect(find.text('正在同步 Bangumi 推荐'), findsNothing);

    backend.complete();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('home-cover-precache-shimmer-grid')),
      findsOneWidget,
    );
    expect(find.text('葬送的芙莉莲'), findsNothing);
  });

  testWidgets('home poster hover lifts card and zooms cover content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final cardText = find.text('葬送的芙莉莲').first;
    final card = find
        .ancestor(
          of: cardText,
          matching: find.byKey(const ValueKey('anime-poster-card-lift')),
        )
        .first;
    Matrix4 transformOf(Finder finder) =>
        tester.widget<AnimatedContainer>(finder).transform ??
        Matrix4.identity();
    expect(transformOf(card).getTranslation().y, 0);

    final scale = find
        .ancestor(of: cardText, matching: find.byType(Column))
        .first;
    expect(
      find.descendant(
        of: scale,
        matching: find.byKey(const ValueKey('anime-poster-cover-scale')),
      ),
      findsOneWidget,
    );
    final coverScaleFinder = find.descendant(
      of: scale,
      matching: find.byKey(const ValueKey('anime-poster-cover-scale')),
    );
    expect(tester.widget<AnimatedScale>(coverScaleFinder).scale, 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(cardText));
    await tester.pump();

    expect(transformOf(card).getTranslation().y, -3);
    expect(tester.widget<AnimatedScale>(coverScaleFinder).scale, 1.035);

    await mouse.removePointer();
  });

  testWidgets('home poster fallback only appears when cover url is missing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    final coveredCard = find
        .ancestor(of: find.text('葬送的芙莉莲').first, matching: find.byType(Column))
        .first;
    expect(
      find.descendant(
        of: coveredCard,
        matching: find.byKey(const ValueKey('anime-poster-cover-loading')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: coveredCard,
        matching: find.byKey(
          const ValueKey('anime-poster-cover-fallback-title'),
        ),
      ),
      findsNothing,
    );

    final fallbackCard = find
        .ancestor(of: find.text('mono女孩').first, matching: find.byType(Column))
        .first;
    expect(
      find.descendant(
        of: fallbackCard,
        matching: find.byKey(const ValueKey('anime-poster-cover-fallback')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: fallbackCard, matching: find.text('m')),
      findsOneWidget,
    );
  });

  testWidgets('home poster card click opens full-window watch route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());

    await tester.pumpAndSettle();
    await tester.tap(find.text('mono女孩').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('watch-page')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const ValueKey('rail-back-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('player-svg-${YnekoAssets.playerPause}')),
      findsWidgets,
    );
    expect(find.text('剧集'), findsOneWidget);
    expect(find.text('系列'), findsOneWidget);
    expect(find.text('规则'), findsOneWidget);
    expect(find.byKey(const ValueKey('episode-list-panel')), findsOneWidget);

    final route = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('watch-page'))),
    ).read(shellRouteProvider);
    expect(route, isA<WatchRoute>());
  });

  testWidgets('watch right panel matches compact original layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final backend = FakeYnekoBackend();
    await tester.pumpWidget(_appWithBackend(backend: backend));
    ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('watch-side-panel'))).width,
      384,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('watch-top-action-divider'))),
      const Size(1, 20),
    );
    for (final tooltip in ['最小化', '最大化', '关闭']) {
      expect(
        tester.getSize(find.byKey(ValueKey('window-button-$tooltip'))),
        const Size(44, 38),
      );
    }

    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('watch-summary-text')),
    );
    expect(summary.maxLines, 2);
    expect(summary.overflow, TextOverflow.ellipsis);
    expect(find.text('展开'), findsOneWidget);
    final summaryToggleDefault = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('展开'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(summaryToggleDefault.style.color, YnekoThemeTokens.light.muted);
    final summaryMouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await summaryMouse.addPointer();
    await summaryMouse.moveTo(tester.getCenter(find.text('展开')));
    await tester.pump();
    final summaryToggleHovered = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('展开'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(summaryToggleHovered.style.color, YnekoThemeTokens.light.primary);
    await summaryMouse.removePointer();
    await tester.tap(find.text('展开'));
    await tester.pumpAndSettle();
    expect(find.text('收起'), findsOneWidget);
    final expandedSummary = tester.widget<Text>(
      find.byKey(const ValueKey('watch-summary-text')),
    );
    expect(expandedSummary.maxLines, isNull);
    expect(expandedSummary.overflow, TextOverflow.visible);
    final bangumiId = tester.widget<Text>(find.text('Bangumi #400602'));
    expect(bangumiId.style?.color, YnekoThemeTokens.light.primary);
    expect(find.text('漫画改'), findsOneWidget);
    expect(find.text('奇幻'), findsOneWidget);
    expect(
      tester.getSize(find.text('漫画改')).width,
      lessThan(
        tester.getSize(find.byKey(const ValueKey('watch-side-panel'))).width /
            2,
      ),
    );

    await tester.tap(find.text('漫画改'));
    await tester.pumpAndSettle();
    final searchContainer = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('search-result-page'))),
    );
    expect(searchContainer.read(shellRouteProvider), isA<SearchRoute>());
    expect(searchContainer.read(searchInputProvider), '漫画改');
    expect(searchContainer.read(searchModeProvider), SearchMode.tag);
    expect(searchContainer.read(searchControllerProvider).query, '漫画改');
    expect(searchContainer.read(searchControllerProvider).mode, SearchMode.tag);
    expect(backend.tagSearchRequests.single, (tag: '漫画改', page: 1));

    searchContainer
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('episode-control-group')), findsOneWidget);
    expect(find.byKey(const ValueKey('watch-panel-tabs')), findsOneWidget);
    final episodeControlGroup = tester.widget<Container>(
      find.byKey(const ValueKey('episode-control-group')),
    );
    expect(episodeControlGroup.decoration, isNull);
    final panelTabs = tester.widget<Container>(
      find.byKey(const ValueKey('watch-panel-tabs')),
    );
    expect(panelTabs.decoration, isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('episode-reverse-toggle'))),
      const Size(30, 30),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('episode-layout-toggle'))),
      const Size(30, 30),
    );
    final episodeList = tester.widget<ListView>(
      find.byKey(const ValueKey('episode-list-panel')),
    );
    expect((episodeList.padding! as EdgeInsets).right, 14);
    var reverseIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('episode-reverse-toggle')),
        matching: find.byIcon(Icons.arrow_upward_rounded),
      ),
    );
    expect(reverseIcon.color, YnekoThemeTokens.light.muted);
    var layoutIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('episode-layout-toggle')),
        matching: find.byIcon(Icons.grid_view_rounded),
      ),
    );
    expect(layoutIcon.color, YnekoThemeTokens.light.muted);
    final layoutMouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await layoutMouse.addPointer();
    await layoutMouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('episode-layout-toggle'))),
    );
    await tester.pump();
    final hoveredLayoutFrame = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('episode-layout-toggle')),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(hoveredLayoutFrame.width, 30);
    expect(hoveredLayoutFrame.height, 30);
    final hoveredLayoutIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('episode-layout-toggle')),
        matching: find.byIcon(Icons.grid_view_rounded),
      ),
    );
    expect(hoveredLayoutIcon.color, YnekoThemeTokens.light.primary);
    await layoutMouse.removePointer();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('episode-layout-toggle')));
    await tester.pumpAndSettle();
    final episodeGrid = tester.widget<GridView>(
      find.byKey(const ValueKey('episode-grid-panel')),
    );
    expect((episodeGrid.padding! as EdgeInsets).right, 14);
    layoutIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('episode-layout-toggle')),
        matching: find.byIcon(Icons.view_list_rounded),
      ),
    );
    expect(layoutIcon.color, YnekoThemeTokens.light.muted);

    await tester.tap(find.byKey(const ValueKey('episode-reverse-toggle')));
    await tester.pumpAndSettle();
    reverseIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('episode-reverse-toggle')),
        matching: find.byIcon(Icons.arrow_downward_rounded),
      ),
    );
    expect(reverseIcon.color, YnekoThemeTokens.light.muted);

    await tester.tap(find.text('规则'));
    await tester.pumpAndSettle();
    final activeRuleTabFrame = tester.widget<Container>(
      find
          .ancestor(
            of: find.descendant(
              of: find.byKey(const ValueKey('watch-panel-tabs')),
              matching: find.text('规则'),
            ),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(activeRuleTabFrame.decoration, isNull);
    final activeRuleTab = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('watch-panel-tabs')),
        matching: find.text('规则'),
      ),
    );
    expect(activeRuleTab.style?.color, YnekoThemeTokens.light.primary);
    expect(find.text('喜欢这部动画的人也喜欢'), findsOneWidget);
    expect(find.text('暂无推荐'), findsOneWidget);
    expect(find.text('Bangumi 推荐模块暂时没有返回内容。'), findsOneWidget);

    expect(find.text('规则'), findsWidgets);
    expect(find.textContaining('选集 ('), findsNothing);
    expect(find.byKey(const ValueKey('episode-control-group')), findsNothing);
    expect(find.byKey(const ValueKey('episode-reverse-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('episode-layout-toggle')), findsNothing);
    expect(
      find.byKey(const ValueKey('source-current-group-card')),
      findsOneWidget,
    );
    expect(find.text('默认规则组'), findsWidgets);

    await tester.binding.setSurfaceSize(const Size(1800, 900));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('watch-side-panel'))).width,
      448,
    );
  });

  testWidgets('watch source panel keeps single empty state without packages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _appWithBackend(
        backend: FakeYnekoBackend(
          sourcePackages: const [],
          playbackContracts: const [],
        ),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    await tester.tap(find.text('规则'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('source-current-group-card')),
      findsOneWidget,
    );
    expect(find.text('默认规则组'), findsWidgets);
    expect(find.text('还没有规则源'), findsOneWidget);
    expect(find.text('没有可用播放源'), findsNothing);
  });

  testWidgets('watch summary prefers Chinese text in mixed summaries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ynekoBackendProvider.overrideWithValue(
            _SummaryBackend(summary: 'スーパーで働く女性店員の話。\n\n在超市后门吸烟的两人的故事。'),
          ),
          directoryPickerProvider.overrideWithValue(
            const _FakeDirectoryPickerService('E:\\Yneko\\Picked'),
          ),
          watchPlayerAdapterFactoryProvider.overrideWithValue(
            (_) => FakePlayerAdapter(),
          ),
        ],
        child: const YnekoApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    expect(find.textContaining('在超市后门吸烟的两人的故事'), findsOneWidget);
    expect(find.textContaining('スーパーで働く'), findsNothing);
  });

  testWidgets('watch summary keeps Japanese when no Chinese summary exists', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ynekoBackendProvider.overrideWithValue(
            _SummaryBackend(summary: 'スーパーで働く女性店員の話。'),
          ),
          directoryPickerProvider.overrideWithValue(
            const _FakeDirectoryPickerService('E:\\Yneko\\Picked'),
          ),
          watchPlayerAdapterFactoryProvider.overrideWithValue(
            (_) => FakePlayerAdapter(),
          ),
        ],
        child: const YnekoApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    expect(find.textContaining('スーパーで働く女性店員の話'), findsOneWidget);
    expect(find.text('Bangumi 暂无中文简介。'), findsNothing);
  });

  testWidgets('watch source loading replaces source empty state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _appWithBackend(
        backend: FakeYnekoBackend(
          sourcePackages: const [],
          sourceSearchDelay: const Duration(milliseconds: 400),
        ),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    await tester.tap(find.text('规则'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('source-current-group-card')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('source-current-group-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(
      find.byKey(const ValueKey('source-panel-loading-state')),
      findsOneWidget,
    );
    final loadingState = tester.widget<Container>(
      find.byKey(const ValueKey('source-panel-loading-state')),
    );
    expect(loadingState.decoration, isNull);
    expect(find.text('还没有规则源'), findsNothing);
    expect(find.text('没有可用播放源'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  testWidgets('watch episode hover switches directly to theme color', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_appWithBackend());
    ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    final episodeTile = find.text('第1话');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(episodeTile));
    await tester.pump();

    final hoveredTile = find
        .ancestor(of: episodeTile, matching: find.byType(Container))
        .first;
    final decoration =
        tester.widget<Container>(hoveredTile).decoration! as BoxDecoration;
    expect(decoration.color, YnekoThemeTokens.light.primaryContainer);

    await mouse.removePointer();
  });

  testWidgets('watch reverse keeps selected episode aligned to list top', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _appWithBackend(backend: _EpisodeListBackend(episodeCount: 12)),
    );
    ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
        .read(shellRouteProvider.notifier)
        .openWatch(subjectId: FakeYnekoBackend.subject.id);
    await tester.pumpAndSettle();

    await tester.tap(find.text('第3话'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('episode-reverse-toggle')));
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }

    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('episode-list-panel')),
    );
    expect(list.controller?.offset, 9 * 52);
  });

  testWidgets(
    'watch page switches panels and uses original player svg assets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_appWithBackend());
      ProviderScope.containerOf(tester.element(find.byType(YnekoApp)))
          .read(shellRouteProvider.notifier)
          .openWatch(subjectId: FakeYnekoBackend.subject.id);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('player-svg-${YnekoAssets.playerPause}')),
        findsWidgets,
      );
      expect(find.text('剧集'), findsOneWidget);
      expect(find.text('系列'), findsOneWidget);
      expect(find.text('规则'), findsOneWidget);
      expect(find.byKey(const ValueKey('episode-list-panel')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('episode-layout-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('episode-grid-panel')), findsOneWidget);

      expect(find.byKey(const ValueKey('watch-follow-button')), findsOneWidget);
      expect(find.text('追番'), findsWidgets);
      final followButton = find.byKey(const ValueKey('watch-follow-button'));
      final followSlide = find
          .ancestor(of: followButton, matching: find.byType(AnimatedSlide))
          .first;
      expect(tester.widget<AnimatedSlide>(followSlide).offset, Offset.zero);

      final followMouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await followMouse.addPointer();
      await followMouse.moveTo(tester.getCenter(followButton));
      await tester.pump();
      expect(
        tester.widget<AnimatedSlide>(followSlide).offset,
        const Offset(0, -0.03),
      );
      await followMouse.moveTo(const Offset(40, 40));
      await tester.pumpAndSettle();
      await followMouse.removePointer();

      await tester.tap(find.byKey(const ValueKey('watch-follow-button')));
      await tester.pumpAndSettle();
      expect(find.text('在看'), findsWidgets);
      expect(find.text('想看'), findsNothing);
      expect(find.text('取消标记'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('watch-follow-button')));
      await tester.pumpAndSettle();
      expect(find.text('想看'), findsOneWidget);
      expect(find.text('看过'), findsOneWidget);
      expect(find.text('搁置'), findsOneWidget);
      expect(find.text('抛弃'), findsOneWidget);
      expect(find.text('取消标记'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('watch-follow-panel'))).width,
        82,
      );
      final plannedOption = find.byKey(
        const ValueKey('watch-follow-option-planned'),
      );
      final plannedOptionFrame = find
          .descendant(
            of: plannedOption,
            matching: find.byType(AnimatedContainer),
          )
          .first;
      final plannedOptionContainer = tester.widget<AnimatedContainer>(
        plannedOptionFrame,
      );
      expect(plannedOptionContainer.duration, Duration.zero);
      expect(find.text('取消标记'), findsOneWidget);
      await tester.tapAt(const Offset(24, 24));
      await tester.pumpAndSettle();
      expect(find.text('取消标记'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('watch-follow-button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('watch-follow-option-planned')),
      );
      await tester.pumpAndSettle();
      expect(find.text('想看'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('watch-follow-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('watch-follow-option-cancel')),
      );
      await tester.pumpAndSettle();
      expect(find.text('追番'), findsWidgets);

      await tester.tap(find.text('规则'));
      await tester.pumpAndSettle();
      expect(find.text('默认规则组'), findsWidgets);
      expect(find.text('Demo'), findsWidgets);
      expect(find.text(FakeYnekoBackend.subject.displayTitle), findsWidgets);

      final svgPictures = tester.widgetList<SvgPicture>(
        find.byType(SvgPicture),
      );
      for (final asset in [
        YnekoAssets.playerPause,
        YnekoAssets.playerEpisodePrevious,
        YnekoAssets.playerEpisodeNext,
        YnekoAssets.playerDanmakuOn,
        YnekoAssets.playerSettings,
        YnekoAssets.playerVolume,
      ]) {
        expect(
          svgPictures.any(
            (picture) => picture.bytesLoader.toString().contains(asset),
          ),
          isTrue,
          reason: '$asset should be visible in the watch control bar',
        );
      }

      await tester.tap(find.byKey(const ValueKey('watch-back-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-anime-grid')), findsOneWidget);
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

  testWidgets('persisted dark cocoa appearance drives app theme', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _appWithBackend(
        backend: FakeYnekoBackend(
          appearanceSettings: const AppearanceSettings(
            themeMode: ThemeMode.dark,
            colorScheme: YnekoColorScheme.cocoa,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tokens = Theme.of(
      tester.element(find.byKey(const ValueKey('home-anime-grid'))),
    ).extension<YnekoThemeTokens>()!;
    expect(tokens.primary, const Color(0xFFD9B08A));
    expect(tokens.primaryContainer, const Color(0xFF3A2D24));
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

Widget _appWithBackend({FakeYnekoBackend? backend}) {
  return ProviderScope(
    overrides: [
      ynekoBackendProvider.overrideWithValue(backend ?? FakeYnekoBackend()),
      directoryPickerProvider.overrideWithValue(
        const _FakeDirectoryPickerService('E:\\Yneko\\Picked'),
      ),
      watchPlayerAdapterFactoryProvider.overrideWithValue(
        (_) => FakePlayerAdapter(),
      ),
    ],
    child: const YnekoApp(),
  );
}

Future<void> _tapFilterOption(WidgetTester tester, String label) async {
  final option = find.byKey(ValueKey('filter-option-$label')).hitTestable();
  expect(option, findsWidgets);
  await tester.ensureVisible(option);
  await tester.tap(option.first);
  await tester.pumpAndSettle();
}

Finder _topTabText(WidgetTester tester, String label) {
  final candidates = find.text(label);
  for (final element in candidates.evaluate()) {
    final textFinder = find.byWidget(element.widget);
    final topTabStyle = find.ancestor(
      of: textFinder,
      matching: find.byType(AnimatedDefaultTextStyle),
    );
    final styles = tester.widgetList<AnimatedDefaultTextStyle>(topTabStyle);
    if (styles.any((style) => style.style.fontSize == 16)) {
      return textFinder;
    }
  }
  throw TestFailure('No top tab text found for "$label".');
}

AnimatedDefaultTextStyle _topTabStyle(WidgetTester tester, String label) {
  final styles = find.ancestor(
    of: _topTabText(tester, label),
    matching: find.byType(AnimatedDefaultTextStyle),
  );
  return tester
      .widgetList<AnimatedDefaultTextStyle>(styles)
      .firstWhere((style) => style.style.fontSize == 16);
}

AnimeSubject _searchSubject(int id, String title) {
  return AnimeSubject(
    id: id,
    name: title,
    nameCn: title,
    coverUrl: 'https://example.test/$id.jpg',
    airDate: '2026-01-01',
    ratingScore: 7.0,
    tags: const ['测试'],
    totalEpisodes: 12,
  );
}

class _FakeDirectoryPickerService implements DirectoryPickerService {
  const _FakeDirectoryPickerService(this.path);

  final String? path;

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async => path;
}

class _SummaryBackend extends FakeYnekoBackend {
  _SummaryBackend({required this.summary});

  final String summary;

  @override
  Future<SubjectDetail> getSubjectDetail(int subjectId) async {
    final detail = await super.getSubjectDetail(subjectId);
    return SubjectDetail(
      subject: AnimeSubject(
        id: detail.subject.id,
        name: detail.subject.name,
        nameCn: detail.subject.nameCn,
        aliases: detail.subject.aliases,
        coverUrl: detail.subject.coverUrl,
        summary: summary,
        airDate: detail.subject.airDate,
        ratingScore: detail.subject.ratingScore,
        ratingRank: detail.subject.ratingRank,
        tags: detail.subject.tags,
        totalEpisodes: detail.subject.totalEpisodes,
      ),
      isFavorite: detail.isFavorite,
      episodes: detail.episodes,
      progress: detail.progress,
    );
  }
}

class _EpisodeListBackend extends FakeYnekoBackend {
  _EpisodeListBackend({required this.episodeCount});

  final int episodeCount;

  @override
  Future<SubjectDetail> getSubjectDetail(int subjectId) async {
    final detail = await super.getSubjectDetail(subjectId);
    return SubjectDetail(
      subject: detail.subject,
      isFavorite: detail.isFavorite,
      episodes: [
        for (var index = 1; index <= episodeCount; index++)
          AnimeEpisode(
            id: detail.subject.id * 100 + index,
            subjectId: detail.subject.id,
            sort: index,
            title: 'Episode $index',
            titleCn: '第 $index 集',
            airDate: '2023-09-${index.toString().padLeft(2, '0')}',
          ),
      ],
      progress: detail.progress,
    );
  }
}

class _PendingHomeBackend extends FakeYnekoBackend {
  final Completer<void> _completer = Completer<void>();

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  Future<AnimeRankingResponse> getAnimeRanking(
    AnimeRankingRequest request,
  ) async {
    await _completer.future;
    return super.getAnimeRanking(request);
  }
}
