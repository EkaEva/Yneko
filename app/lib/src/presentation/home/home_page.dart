import 'package:flutter/material.dart';

import '../search/search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Row(
        children: [
          _NavigationRail(),
          Expanded(child: SearchPage()),
        ],
      ),
    );
  }
}

class _NavigationRail extends StatelessWidget {
  const _NavigationRail();

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: 0,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.search),
          label: Text('搜索'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.video_library_outlined),
          label: Text('片库'),
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

