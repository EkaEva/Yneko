import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../search/index.dart';
import '../../shell/index.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          _NavigationRail(
            onOpenHome: () => ref.read(shellRouteProvider.notifier).openHome(),
            onOpenSubjectDetail: () => ref.read(shellRouteProvider.notifier).openSubjectDetail(1001),
          ),
          const Expanded(child: SearchPage()),
        ],
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.onOpenHome,
    required this.onOpenSubjectDetail,
  });

  final VoidCallback onOpenHome;
  final VoidCallback onOpenSubjectDetail;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 0) onOpenHome();
        if (index == 1) onOpenSubjectDetail();
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text('搜索'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.movie_outlined),
          label: Text('详情'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history),
          label: Text('历史'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          label: Text('设置'),
        ),
      ],
    );
  }
}
