import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/infrastructure/bridge/yneko_backend.dart';
import 'package:yneko/src/features/shell/index.dart';
import 'package:yneko/src/features/subject_detail/index.dart';

import 'support/fake_yneko_backend.dart';

void main() {
  testWidgets('episode tap opens playback detail route intent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        ynekoBackendProvider.overrideWithValue(const FakeYnekoBackend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SubjectDetailPage(subjectId: 1001)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 话'));
    await tester.pump();

    final route = container.read(shellRouteProvider);
    expect(route, isA<EpisodePlaybackRoute>());
    final playbackRoute = route as EpisodePlaybackRoute;
    expect(playbackRoute.subjectId, FakeYnekoBackend.subject.id);
    expect(playbackRoute.episodeId, FakeYnekoBackend.subject.id * 100 + 1);
  });
}
