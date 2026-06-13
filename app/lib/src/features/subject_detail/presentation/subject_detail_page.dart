import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';

class SubjectDetailPage extends ConsumerWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = List.generate(
      12,
      (index) => (id: subjectId * 100 + index + 1, label: '第 ${index + 1} 话'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('番剧详情 #$subjectId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(shellRouteProvider.notifier).openHome(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(episode.label),
            subtitle: const Text('点击进入播放详情页'),
            onTap: () => ref.read(shellRouteProvider.notifier).openEpisodePlayback(
              subjectId: subjectId,
              episodeId: episode.id,
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemCount: episodes.length,
      ),
    );
  }
}
