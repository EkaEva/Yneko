import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SubjectDetailPage extends ConsumerStatefulWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final int subjectId;

  @override
  ConsumerState<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends ConsumerState<SubjectDetailPage> {
  bool _summaryExpanded = false;
  bool _gridEpisodes = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final subject = mockAnimeCards.firstWhere(
      (item) => item.id == widget.subjectId,
      orElse: () => mockAnimeCards.first,
    );
    final episodes = mockEpisodesForSubject(widget.subjectId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => ref.read(shellRouteProvider.notifier).openHome(),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('返回'),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border_rounded),
              label: const Text('追番'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(colors: [subject.coverColor, subject.accent]),
                    boxShadow: tokens.shadow,
                  ),
                  child: Center(
                    child: Text(
                      subject.title.substring(0, 1),
                      style: const TextStyle(color: Colors.white, fontSize: 74, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(icon: Icons.star_rounded, label: '评分 ${subject.score}'),
                      const _MetaPill(icon: Icons.calendar_month_rounded, label: '2026-04'),
                      const _MetaPill(icon: Icons.live_tv_rounded, label: '12 话'),
                      const _MetaPill(icon: Icons.sell_rounded, label: '原创'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    subject.summary,
                    maxLines: _summaryExpanded ? null : 2,
                    overflow: _summaryExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.muted, height: 1.58, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _summaryExpanded = !_summaryExpanded),
                    icon: Icon(_summaryExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                    label: Text(_summaryExpanded ? '收起' : '展开'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: YnekoPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PanelHeader(
                      title: '剧集',
                      subtitle: '${episodes.length} 集 · 点击进入播放详情页',
                      trailing: IconButton(
                        tooltip: _gridEpisodes ? '列表' : '网格',
                        onPressed: () => setState(() => _gridEpisodes = !_gridEpisodes),
                        icon: Icon(_gridEpisodes ? Icons.view_list_rounded : Icons.grid_view_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _gridEpisodes ? _EpisodeGrid(subjectId: widget.subjectId, episodes: episodes) : _EpisodeList(subjectId: widget.subjectId, episodes: episodes),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 340,
              child: Column(
                children: [
                  YnekoPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PanelHeader(title: '规则源候选', subtitle: 'source_rules 静态预览'),
                        const SizedBox(height: 12),
                        for (final candidate in mockSourceCandidates)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SourceCandidateRow(candidate: candidate),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const YnekoPanel(
                    child: YnekoEmptyState(
                      icon: Icons.forum_rounded,
                      title: '评论源暂未接入',
                      description: '详情页先保留评论/更多内容的视觉槽位。',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EpisodeList extends ConsumerWidget {
  const _EpisodeList({required this.subjectId, required this.episodes});

  final int subjectId;
  final List<UiEpisodeItem> episodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final episode in episodes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _EpisodeButton(subjectId: subjectId, episode: episode, grid: false),
          ),
      ],
    );
  }
}

class _EpisodeGrid extends StatelessWidget {
  const _EpisodeGrid({required this.subjectId, required this.episodes});

  final int subjectId;
  final List<UiEpisodeItem> episodes;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 92,
        mainAxisExtent: 58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) => _EpisodeButton(
        subjectId: subjectId,
        episode: episodes[index],
        grid: true,
      ),
    );
  }
}

class _EpisodeButton extends ConsumerWidget {
  const _EpisodeButton({
    required this.subjectId,
    required this.episode,
    required this.grid,
  });

  final int subjectId;
  final UiEpisodeItem episode;
  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    return Material(
      color: grid ? tokens.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref.read(shellRouteProvider.notifier).openEpisodePlayback(
          subjectId: subjectId,
          episodeId: episode.id,
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: grid ? 58 : 44),
          padding: EdgeInsets.symmetric(horizontal: grid ? 8 : 12),
          decoration: BoxDecoration(
            border: grid ? Border.all(color: tokens.outline.withValues(alpha: 0.62)) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: grid
              ? Center(child: Text('${episode.order}', style: const TextStyle(fontWeight: FontWeight.w900)))
              : Row(
                  children: [
                    Text(episode.label, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(episode.title, overflow: TextOverflow.ellipsis)),
                    if (episode.progress > 0)
                      SizedBox(
                        width: 86,
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: episode.progress,
                          backgroundColor: tokens.surfaceHigh,
                          color: tokens.primary,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tokens.primary),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: tokens.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
