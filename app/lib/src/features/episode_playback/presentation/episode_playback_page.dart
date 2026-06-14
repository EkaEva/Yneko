import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/index.dart';
import '../../shell/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

enum _DetailPanelTab { episodes, series, sources }

class EpisodePlaybackPage extends ConsumerStatefulWidget {
  const EpisodePlaybackPage({
    super.key,
    required this.subjectId,
    required this.episodeId,
  });

  final int subjectId;
  final int episodeId;

  @override
  ConsumerState<EpisodePlaybackPage> createState() =>
      _EpisodePlaybackPageState();
}

class _EpisodePlaybackPageState extends ConsumerState<EpisodePlaybackPage> {
  _DetailPanelTab _tab = _DetailPanelTab.episodes;
  bool _gridEpisodes = false;
  bool _reverseEpisodes = false;
  bool _sourceGroupOpen = false;
  String _sourceGroup = '默认规则组';
  String _sourceMatrixStatus = '';

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final episodes = mockEpisodesForSubject(widget.subjectId);
    final displayedEpisodes = _reverseEpisodes
        ? episodes.reversed.toList()
        : episodes;
    final subject = mockAnimeCards.firstWhere(
      (item) => item.id == widget.subjectId,
      orElse: () => mockAnimeCards.first,
    );
    final activeEpisode = episodes.firstWhere(
      (episode) => episode.id == widget.episodeId,
      orElse: () => episodes.first,
    );
    final activeIndex = episodes.indexWhere(
      (item) => item.id == activeEpisode.id,
    );

    return ColoredBox(
      color: tokens.page,
      child: Row(
        key: const ValueKey('episode-playback-detail'),
        children: [
          Expanded(
            child: PlayerSurface(
              subjectId: widget.subjectId,
              episodeId: widget.episodeId,
              title:
                  '${subject.title} [第${activeEpisode.order.toString().padLeft(2, '0')}集]',
              episodes: episodes,
              hasPreviousEpisode: activeIndex > 0,
              hasNextEpisode:
                  activeIndex >= 0 && activeIndex < episodes.length - 1,
              onPreviousEpisode: activeIndex > 0
                  ? () => _openEpisode(episodes[activeIndex - 1])
                  : null,
              onNextEpisode:
                  activeIndex >= 0 && activeIndex < episodes.length - 1
                  ? () => _openEpisode(episodes[activeIndex + 1])
                  : null,
              onSelectEpisode: _openEpisode,
            ),
          ),
          SizedBox(
            width: 420,
            child: _RightDetailPanel(
              subject: subject,
              activeEpisode: activeEpisode,
              episodes: displayedEpisodes,
              activeEpisodeId: widget.episodeId,
              tab: _tab,
              gridEpisodes: _gridEpisodes,
              reverseEpisodes: _reverseEpisodes,
              sourceGroupOpen: _sourceGroupOpen,
              sourceGroup: _sourceGroup,
              sourceMatrixStatus: _sourceMatrixStatus,
              onBack: () => ref
                  .read(shellRouteProvider.notifier)
                  .openSubjectDetail(widget.subjectId),
              onTab: (tab) => setState(() => _tab = tab),
              onToggleGrid: () =>
                  setState(() => _gridEpisodes = !_gridEpisodes),
              onToggleReverse: () =>
                  setState(() => _reverseEpisodes = !_reverseEpisodes),
              onToggleSourceGroup: () =>
                  setState(() => _sourceGroupOpen = !_sourceGroupOpen),
              onSourceGroup: (group) => setState(() {
                _sourceGroup = group;
                _sourceGroupOpen = false;
              }),
              onExportMatrix: () =>
                  setState(() => _sourceMatrixStatus = '矩阵已复制'),
              onEpisode: _openEpisode,
            ),
          ),
        ],
      ),
    );
  }

  void _openEpisode(UiEpisodeItem episode) {
    ref
        .read(shellRouteProvider.notifier)
        .openEpisodePlayback(
          subjectId: widget.subjectId,
          episodeId: episode.id,
        );
  }
}

class _RightDetailPanel extends StatelessWidget {
  const _RightDetailPanel({
    required this.subject,
    required this.activeEpisode,
    required this.episodes,
    required this.activeEpisodeId,
    required this.tab,
    required this.gridEpisodes,
    required this.reverseEpisodes,
    required this.sourceGroupOpen,
    required this.sourceGroup,
    required this.sourceMatrixStatus,
    required this.onBack,
    required this.onTab,
    required this.onToggleGrid,
    required this.onToggleReverse,
    required this.onToggleSourceGroup,
    required this.onSourceGroup,
    required this.onExportMatrix,
    required this.onEpisode,
  });

  final UiAnimeCard subject;
  final UiEpisodeItem activeEpisode;
  final List<UiEpisodeItem> episodes;
  final int activeEpisodeId;
  final _DetailPanelTab tab;
  final bool gridEpisodes;
  final bool reverseEpisodes;
  final bool sourceGroupOpen;
  final String sourceGroup;
  final String sourceMatrixStatus;
  final VoidCallback onBack;
  final ValueChanged<_DetailPanelTab> onTab;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleReverse;
  final VoidCallback onToggleSourceGroup;
  final ValueChanged<String> onSourceGroup;
  final VoidCallback onExportMatrix;
  final ValueChanged<UiEpisodeItem> onEpisode;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      color: tokens.page,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '返回详情',
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  subject.title,
                  overflow: TextOverflow.ellipsis,
                  style: type.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CompactSummary(subject: subject, activeEpisode: activeEpisode),
          const SizedBox(height: 12),
          _PanelTabs(tab: tab, onTab: onTab),
          const SizedBox(height: 12),
          Expanded(
            child: switch (tab) {
              _DetailPanelTab.episodes => _EpisodesPanel(
                episodes: episodes,
                activeEpisodeId: activeEpisodeId,
                grid: gridEpisodes,
                reversed: reverseEpisodes,
                onToggleGrid: onToggleGrid,
                onToggleReverse: onToggleReverse,
                onEpisode: onEpisode,
              ),
              _DetailPanelTab.series => _SeriesPanel(
                currentSubjectId: subject.id,
              ),
              _DetailPanelTab.sources => _SourcesPanel(
                sourceGroup: sourceGroup,
                open: sourceGroupOpen,
                matrixStatus: sourceMatrixStatus,
                onToggleGroup: onToggleSourceGroup,
                onSourceGroup: onSourceGroup,
                onExportMatrix: onExportMatrix,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.subject, required this.activeEpisode});

  final UiAnimeCard subject;
  final UiEpisodeItem activeEpisode;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return YnekoPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${activeEpisode.label} · ${activeEpisode.title}',
            overflow: TextOverflow.ellipsis,
            style: type.controlTitle,
          ),
          const SizedBox(height: 7),
          Text(
            subject.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: type.meta.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TinyPill(label: subject.score, icon: Icons.star_rounded),
              const _TinyPill(label: 'Bangumi'),
              const _TinyPill(label: '评论占位'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelTabs extends StatelessWidget {
  const _PanelTabs({required this.tab, required this.onTab});

  final _DetailPanelTab tab;
  final ValueChanged<_DetailPanelTab> onTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PanelTabButton(
          label: '剧集',
          icon: Icons.playlist_play_rounded,
          active: tab == _DetailPanelTab.episodes,
          onTap: () => onTab(_DetailPanelTab.episodes),
        ),
        _PanelTabButton(
          label: '系列',
          icon: Icons.auto_stories_rounded,
          active: tab == _DetailPanelTab.series,
          onTap: () => onTab(_DetailPanelTab.series),
        ),
        _PanelTabButton(
          label: '规则源',
          icon: Icons.tune_rounded,
          active: tab == _DetailPanelTab.sources,
          onTap: () => onTab(_DetailPanelTab.sources),
        ),
      ],
    );
  }
}

class _PanelTabButton extends StatelessWidget {
  const _PanelTabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: active ? Colors.white : tokens.muted,
          backgroundColor: active ? tokens.primary : tokens.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _EpisodesPanel extends StatelessWidget {
  const _EpisodesPanel({
    required this.episodes,
    required this.activeEpisodeId,
    required this.grid,
    required this.reversed,
    required this.onToggleGrid,
    required this.onToggleReverse,
    required this.onEpisode,
  });

  final List<UiEpisodeItem> episodes;
  final int activeEpisodeId;
  final bool grid;
  final bool reversed;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleReverse;
  final ValueChanged<UiEpisodeItem> onEpisode;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.outline.withValues(alpha: 0.62)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: tokens.shadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '剧集  ${episodes.length} 集',
                    style: type.controlTitle.copyWith(fontSize: 16),
                  ),
                ),
                _SmallIconButton(
                  key: const ValueKey('episode-reverse-toggle'),
                  tooltip: reversed ? '正序' : '倒序',
                  icon: Icons.swap_vert_rounded,
                  onTap: onToggleReverse,
                  active: reversed,
                ),
                const SizedBox(width: 8),
                _SmallIconButton(
                  key: const ValueKey('episode-layout-toggle'),
                  tooltip: grid ? '列表' : '网格',
                  icon: grid
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  onTap: onToggleGrid,
                  active: grid,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: (constraints.maxHeight - 72).clamp(120.0, 1000.0),
              child: grid
                  ? GridView.builder(
                      key: const ValueKey('episode-grid-panel'),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 64,
                            mainAxisExtent: 58,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        return _EpisodeTile(
                          episode: episode,
                          active: episode.id == activeEpisodeId,
                          grid: true,
                          onTap: () => onEpisode(episode),
                        );
                      },
                    )
                  : ListView.builder(
                      key: const ValueKey('episode-list-panel'),
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _EpisodeTile(
                            episode: episode,
                            active: episode.id == activeEpisodeId,
                            grid: false,
                            onTap: () => onEpisode(episode),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.active,
    required this.grid,
    required this.onTap,
  });

  final UiEpisodeItem episode;
  final bool active;
  final bool grid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Material(
      color: active
          ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.3)
          : grid
          ? tokens.surface
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: grid ? Border.all(color: tokens.outline) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: grid ? 0 : 10),
          child: grid
              ? Center(
                  child: Text(
                    '${episode.order}',
                    style: type.controlTitle.copyWith(
                      color: active ? tokens.primaryStrong : tokens.ink,
                    ),
                  ),
                )
              : Row(
                  children: [
                    Text('第${episode.order}话', style: type.controlTitle),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        episode.title,
                        overflow: TextOverflow.ellipsis,
                        style: type.meta,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SeriesPanel extends StatelessWidget {
  const _SeriesPanel({required this.currentSubjectId});

  final int currentSubjectId;

  @override
  Widget build(BuildContext context) {
    final items = mockAnimeCards
        .where((item) => item.id != currentSubjectId)
        .toList();
    return YnekoPanel(
      padding: const EdgeInsets.all(14),
      child: ListView.builder(
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.only(top: 8),
              child: YnekoEmptyState(
                icon: Icons.forum_rounded,
                title: '评论源暂未接入',
                description: '更多内容会在后续模块接入。',
              ),
            );
          }
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SeriesRow(item: item),
          );
        },
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.item});

  final UiAnimeCard item;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.coverColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.title.characters.first,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  overflow: TextOverflow.ellipsis,
                  style: type.controlTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: type.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourcesPanel extends StatelessWidget {
  const _SourcesPanel({
    required this.sourceGroup,
    required this.open,
    required this.matrixStatus,
    required this.onToggleGroup,
    required this.onSourceGroup,
    required this.onExportMatrix,
  });

  final String sourceGroup;
  final bool open;
  final String matrixStatus;
  final VoidCallback onToggleGroup;
  final ValueChanged<String> onSourceGroup;
  final VoidCallback onExportMatrix;

  @override
  Widget build(BuildContext context) {
    final groups = const ['默认规则组', '备用规则组', '实验规则组'];
    return YnekoPanel(
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: [
          _SourceGroupCard(
            title: sourceGroup,
            open: open,
            onTap: onToggleGroup,
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Column(
                children: [
                  for (final group in groups)
                    _SourceGroupOption(
                      label: group,
                      active: group == sourceGroup,
                      onTap: () => onSourceGroup(group),
                    ),
                ],
              ),
            ),
          FilledButton.icon(
            onPressed: onExportMatrix,
            icon: const Icon(Icons.download_rounded),
            label: const Text('导出矩阵'),
          ),
          if (matrixStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(matrixStatus, style: YnekoTypography.of(context).meta),
          ],
          const SizedBox(height: 12),
          for (final candidate in mockSourceCandidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SourceCandidateRow(
                candidate: candidate,
                active: candidate.name == sourceGroup || candidate.matched,
              ),
            ),
          const SizedBox(height: 10),
          const YnekoEmptyState(
            icon: Icons.tune_rounded,
            title: '暂无更多候选',
            description: '可以重新搜索，或到设置里添加规则源。',
          ),
        ],
      ),
    );
  }
}

class _SourceGroupCard extends StatelessWidget {
  const _SourceGroupCard({
    required this.title,
    required this.open,
    required this.onTap,
  });

  final String title;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SourceCandidateRow(
        candidate: UiSourceCandidate(
          name: title,
          status: '已选择',
          detail: '点击切换规则组',
          matched: true,
        ),
        active: open,
      ),
    );
  }
}

class _SourceGroupOption extends StatelessWidget {
  const _SourceGroupOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: active
            ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.32)
            : tokens.surface,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          title: Text(label),
          trailing: active
              ? Icon(Icons.check_rounded, color: tokens.primary)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? tokens.primaryContainer : tokens.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.outline.withValues(alpha: 0.66)),
          ),
          child: Icon(
            icon,
            size: 15,
            color: active ? tokens.primary : tokens.muted,
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: tokens.primary),
              const SizedBox(width: 4),
            ],
            Text(label, style: YnekoTypography.of(context).label),
          ],
        ),
      ),
    );
  }
}
