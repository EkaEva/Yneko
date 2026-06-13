import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/features/episode_playback/index.dart';
import 'package:yneko/src/features/shell/index.dart';
import 'package:yneko/src/shared/theme/index.dart';

void main() {
  testWidgets('shell renders rail, top tabs, search box, and page content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: YnekoApp()));

    expect(find.bySemanticsLabel('Yneko'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('推荐'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('今天想看点什么'), findsOneWidget);
  });

  testWidgets('top search focus changes layout without hiding the input', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: YnekoApp()));

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索番剧、标签、角色'), findsOneWidget);
  });

  testWidgets('episode playback page has player, episodes, sources, and progress panels', (tester) async {
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
    expect(find.text('播放源'), findsOneWidget);
    expect(find.text('进度'), findsOneWidget);
  });

  testWidgets('theme tokens are available in light and dark themes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ynekoTheme(Brightness.light),
        darkTheme: ynekoTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            final tokens = YnekoThemeTokens.of(context);
            return Text('primary-${tokens.primary.toARGB32()}');
          },
        ),
      ),
    );

    expect(find.textContaining('primary-'), findsOneWidget);
  });
}
