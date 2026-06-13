import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/features/shell/index.dart';
import 'package:yneko/src/features/subject_detail/index.dart';

void main() {
  testWidgets('episode tap opens playback detail route intent', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SubjectDetailPage(subjectId: 1001),
        ),
      ),
    );

    await tester.tap(find.text('第 1 话'));
    await tester.pump();

    final route = container.read(shellRouteProvider);
    expect(route, isA<EpisodePlaybackRoute>());
    final playbackRoute = route as EpisodePlaybackRoute;
    expect(playbackRoute.subjectId, 1001);
    expect(playbackRoute.episodeId, 100101);
  });
}
