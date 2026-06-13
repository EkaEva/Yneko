import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/index.dart';
import '../../shell/index.dart';

class EpisodePlaybackPage extends ConsumerWidget {
  const EpisodePlaybackPage({
    super.key,
    required this.subjectId,
    required this.episodeId,
  });

  final int subjectId;
  final int episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = List.generate(
      12,
      (index) => (id: subjectId * 100 + index + 1, label: '第 ${index + 1} 话'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('播放详情 #$episodeId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ref.read(shellRouteProvider.notifier).openSubjectDetail(subjectId),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: PlayerSurface(subjectId: subjectId, episodeId: episodeId),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 340,
              child: _EpisodeSidePanel(
                subjectId: subjectId,
                activeEpisodeId: episodeId,
                episodes: episodes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeSidePanel extends ConsumerWidget {
  const _EpisodeSidePanel({
    required this.subjectId,
    required this.activeEpisodeId,
    required this.episodes,
  });

  final int subjectId;
  final int activeEpisodeId;
  final List<({int id, String label})> episodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('剧集', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final episode in episodes)
            ListTile(
              selected: episode.id == activeEpisodeId,
              dense: true,
              leading: const Icon(Icons.smart_display_outlined),
              title: Text(episode.label),
              onTap: () => ref.read(shellRouteProvider.notifier).openEpisodePlayback(
                subjectId: subjectId,
                episodeId: episode.id,
              ),
            ),
          const Divider(height: 28),
          Text('播放源', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('等待 source_rules 插件解析候选播放源。'),
          const Divider(height: 28),
          Text('进度', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('后续由 episode_playback 应用层保存并恢复。'),
        ],
      ),
    );
  }
}
