import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';
import '../application/subject_detail_providers.dart';
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
    final detail = ref.watch(subjectDetailProvider(widget.subjectId));

    return detail.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _SubjectDetailError(subjectId: widget.subjectId, error: error),
      data: (detail) => _SubjectDetailContent(
        detail: detail,
        summaryExpanded: _summaryExpanded,
        gridEpisodes: _gridEpisodes,
        onToggleSummary: () =>
            setState(() => _summaryExpanded = !_summaryExpanded),
        onToggleEpisodeLayout: () =>
            setState(() => _gridEpisodes = !_gridEpisodes),
      ),
    );
  }
}

class _SubjectDetailError extends ConsumerWidget {
  const _SubjectDetailError({required this.subjectId, required this.error});

  final int subjectId;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
      children: [
        TextButton.icon(
          onPressed: () => ref.read(shellRouteProvider.notifier).openHome(),
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('返回'),
        ),
        const SizedBox(height: 24),
        YnekoPanel(
          child: Column(
            children: [
              YnekoEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Bangumi 详情加载失败',
                description: error.toString(),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.invalidate(subjectDetailProvider(subjectId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectDetailContent extends ConsumerWidget {
  const _SubjectDetailContent({
    required this.detail,
    required this.summaryExpanded,
    required this.gridEpisodes,
    required this.onToggleSummary,
    required this.onToggleEpisodeLayout,
  });

  final SubjectDetail detail;
  final bool summaryExpanded;
  final bool gridEpisodes;
  final VoidCallback onToggleSummary;
  final VoidCallback onToggleEpisodeLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final subject = detail.subject;
    final episodes = detail.episodes;
    final title = subjectTitle(subject);

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
            _SubjectCover(subject: subject, title: title),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: type.pageTitle.copyWith(fontSize: 32)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill(
                        icon: Icons.star_rounded,
                        label: subjectScoreLabel(subject),
                      ),
                      _MetaPill(
                        icon: Icons.calendar_month_rounded,
                        label: subjectAirDateLabel(subject),
                      ),
                      _MetaPill(
                        icon: Icons.live_tv_rounded,
                        label: subjectEpisodeCountLabel(subject, episodes),
                      ),
                      _MetaPill(
                        icon: Icons.sell_rounded,
                        label: subjectTagLabel(subject),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    subject.summary ?? 'Bangumi 暂无简介。',
                    maxLines: summaryExpanded ? null : 2,
                    overflow: summaryExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: type.body.copyWith(
                      color: tokens.muted,
                      height: 1.58,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onToggleSummary,
                    icon: Icon(
                      summaryExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    label: Text(summaryExpanded ? '收起' : '展开'),
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
                        tooltip: gridEpisodes ? '列表' : '网格',
                        onPressed: onToggleEpisodeLayout,
                        icon: Icon(
                          gridEpisodes
                              ? Icons.view_list_rounded
                              : Icons.grid_view_rounded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    gridEpisodes
                        ? _EpisodeGrid(
                            subjectId: subject.id,
                            episodes: episodes,
                          )
                        : _EpisodeList(
                            subjectId: subject.id,
                            episodes: episodes,
                          ),
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
                        const _PanelHeader(
                          title: '规则源候选',
                          subtitle: 'source_rules 静态预览',
                        ),
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

class _SubjectCover extends StatelessWidget {
  const _SubjectCover({required this.subject, required this.title});

  final AnimeSubject subject;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return SizedBox(
      width: 220,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                subjectCoverColor(subject.id),
                subjectAccentColor(subject.id),
              ],
            ),
            boxShadow: tokens.shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: subject.coverUrl == null
                ? _SubjectCoverFallback(title: title)
                : Image.network(
                    subject.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _SubjectCoverFallback(title: title),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SubjectCoverFallback extends StatelessWidget {
  const _SubjectCoverFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title.characters.first,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 74,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EpisodeList extends ConsumerWidget {
  const _EpisodeList({required this.subjectId, required this.episodes});

  final int subjectId;
  final List<AnimeEpisode> episodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final episode in episodes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _EpisodeButton(
              subjectId: subjectId,
              episode: episode,
              grid: false,
            ),
          ),
      ],
    );
  }
}

class _EpisodeGrid extends StatelessWidget {
  const _EpisodeGrid({required this.subjectId, required this.episodes});

  final int subjectId;
  final List<AnimeEpisode> episodes;

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
  final AnimeEpisode episode;
  final bool grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Material(
      color: grid ? tokens.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => ref
            .read(shellRouteProvider.notifier)
            .openEpisodePlayback(
              subjectId: subjectId,
              episodeId: _episodeRouteId,
            ),
        child: Container(
          constraints: BoxConstraints(minHeight: grid ? 58 : 44),
          padding: EdgeInsets.symmetric(horizontal: grid ? 8 : 12),
          decoration: BoxDecoration(
            border: grid
                ? Border.all(color: tokens.outline.withValues(alpha: 0.62))
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: grid
              ? Center(child: Text('${episode.sort}', style: type.controlTitle))
              : Row(
                  children: [
                    Text('第 ${episode.sort} 话', style: type.controlTitle),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        episode.displayTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  int get _episodeRouteId {
    if (episode.id > 0) return episode.id;
    return subjectId * 100 + episode.sort;
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
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
            Text(label, style: type.label.copyWith(color: tokens.ink)),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: type.controlTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 3),
              Text(subtitle, style: type.label.copyWith(color: tokens.muted)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
