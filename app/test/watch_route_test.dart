import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/features/shell/index.dart';
import 'package:yneko/src/infrastructure/bridge/yneko_backend.dart';

import 'support/fake_yneko_backend.dart';

void main() {
  testWidgets('card click opens watch route directly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        ynekoBackendProvider.overrideWithValue(const FakeYnekoBackend()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YnekoApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('mono女孩').first);
    await tester.pumpAndSettle();

    final route = container.read(shellRouteProvider);
    expect(route, isA<WatchRoute>());
    final watchRoute = route as WatchRoute;
    expect(watchRoute.subjectId, FakeYnekoBackend.secondSubject.id);
    expect(watchRoute.episodeId, isNull);
    expect(find.byKey(const ValueKey('watch-page')), findsOneWidget);
  });
}
