import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/index.dart';
import '../../shell/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

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
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final episodes = mockEpisodesForSubject(subjectId);
    final subject = mockAnimeCards.firstWhere(
      (item) => item.id == subjectId,
      orElse: () => mockAnimeCards.first,
    );
    final activeEpisode = episodes.firstWhere(
      (episode) => episode.id == episodeId,
      orElse: () => episodes.first,
    );

    return ColoredBox(
      color: tokens.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        child: Column(
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => ref
                      .read(shellRouteProvider.notifier)
                      .openSubjectDetail(subjectId),
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('返回详情'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${subject.title} · ${activeEpisode.label}',
                    overflow: TextOverflow.ellipsis,
                    style: type.sectionTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: PlayerSurface(
                      subjectId: subjectId,
                      episodeId: episodeId,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 360,
                    child: _EpisodeSidePanel(
                      subjectId: subjectId,
                      activeEpisodeId: episodeId,
                      episodes: episodes,
                      activeEpisode: activeEpisode,
                    ),
                  ),
                ],
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
    required this.activeEpisode,
  });

  final int subjectId;
  final int activeEpisodeId;
  final List<UiEpisodeItem> episodes;
  final UiEpisodeItem activeEpisode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return YnekoPanel(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('剧集', style: type.cardTitle),
          const SizedBox(height: 3),
          Text(
            '${episodes.length} 集 · 当前 ${activeEpisode.label}',
            style: type.label.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 198,
            child: ListView.builder(
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _EpisodeRow(
                    episode: episode,
                    active: episode.id == activeEpisodeId,
                    onTap: () => ref
                        .read(shellRouteProvider.notifier)
                        .openEpisodePlayback(
                          subjectId: subjectId,
                          episodeId: episode.id,
                        ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text('播放源', style: type.cardTitle),
          const SizedBox(height: 10),
          for (final candidate in mockSourceCandidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SourceCandidateRow(
                candidate: candidate,
                active: candidate.matched,
              ),
            ),
          const SizedBox(height: 18),
          Text('进度', style: type.cardTitle),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: activeEpisode.progress == 0
                  ? 0.14
                  : activeEpisode.progress,
              backgroundColor: tokens.surfaceHigh,
              color: tokens.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '后续由 episode_playback 应用层保存并恢复。',
            style: type.meta.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.episode,
    required this.active,
    required this.onTap,
  });

  final UiEpisodeItem episode;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Material(
      color: active
          ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.32)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(
                Icons.smart_display_rounded,
                color: active ? tokens.primary : tokens.muted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(episode.label, style: type.controlTitle),
                    Text(
                      episode.title,
                      overflow: TextOverflow.ellipsis,
                      style: type.label.copyWith(color: tokens.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
