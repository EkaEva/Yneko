import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../episode_playback/index.dart';
import '../../home/index.dart';
import '../../search/index.dart';
import '../../subject_detail/index.dart';

class YnekoApp extends ConsumerWidget {
  const YnekoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(shellRouteProvider);

    return MaterialApp(
      title: 'Yneko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6F73),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: switch (route) {
        HomeRoute() => const HomePage(),
        SearchRoute() => const SearchPage(),
        SubjectDetailRoute(:final subjectId) => SubjectDetailPage(subjectId: subjectId),
        EpisodePlaybackRoute(:final subjectId, :final episodeId) => EpisodePlaybackPage(
          subjectId: subjectId,
          episodeId: episodeId,
        ),
      },
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
