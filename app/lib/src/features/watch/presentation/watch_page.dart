import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../infrastructure/platform/window_chrome/index.dart';
import '../../shell/index.dart';
import '../application/watch_providers.dart';
import '../../../shared/assets/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

enum _WatchPanelTab { episodes, series, sources }

class WatchPage extends ConsumerStatefulWidget {
  const WatchPage({super.key, required this.subjectId, this.initialEpisodeId});

  final int subjectId;
  final int? initialEpisodeId;

  @override
  ConsumerState<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends ConsumerState<WatchPage> {
  _WatchPanelTab _tab = _WatchPanelTab.episodes;
  bool _gridEpisodes = false;
  bool _reverseEpisodes = false;
  bool _sourceGroupOpen = false;
  String _sourceGroup = '默认规则组';
  String _sourceMatrixStatus = '';
  int? _selectedEpisodeId;

  @override
  void didUpdateWidget(covariant WatchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId ||
        oldWidget.initialEpisodeId != widget.initialEpisodeId) {
      _selectedEpisodeId = widget.initialEpisodeId;
      _tab = _WatchPanelTab.episodes;
      _sourceGroupOpen = false;
      _sourceMatrixStatus = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(watchSubjectDetailProvider(widget.subjectId));
    final tokens = YnekoThemeTokens.of(context);

    return Material(
      key: const ValueKey('watch-page'),
      color: tokens.page,
      child: DefaultTextStyle.merge(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(decoration: TextDecoration.none),
        child: detail.when(
          loading: () => const _WatchLoading(),
          error: (error, stackTrace) =>
              _WatchError(subjectId: widget.subjectId, error: error),
          data: _buildContent,
        ),
      ),
    );
  }

  Widget _buildContent(SubjectDetail detail) {
    final episodes = detail.episodes;
    final activeEpisode = _activeEpisode(episodes);
    final displayedEpisodes = _reverseEpisodes
        ? episodes.reversed.toList()
        : episodes;
    final activeIndex = episodes.indexWhere(
      (item) => item.id == activeEpisode?.id,
    );

    return Row(
      children: [
        Expanded(
          child: _WatchPlaybackStage(
            subject: detail.subject,
            episode: activeEpisode,
            episodes: episodes,
            hasPreviousEpisode: activeIndex > 0,
            hasNextEpisode:
                activeIndex >= 0 && activeIndex < episodes.length - 1,
            onBack: () => ref.read(shellRouteProvider.notifier).openHome(),
            onPreviousEpisode: activeIndex > 0
                ? () => _selectEpisode(episodes[activeIndex - 1])
                : null,
            onNextEpisode: activeIndex >= 0 && activeIndex < episodes.length - 1
                ? () => _selectEpisode(episodes[activeIndex + 1])
                : null,
            onSelectEpisode: _selectEpisode,
          ),
        ),
        SizedBox(
          width: 448,
          child: _WatchSidePanel(
            detail: detail,
            activeEpisode: activeEpisode,
            episodes: displayedEpisodes,
            activeEpisodeId: activeEpisode?.id,
            tab: _tab,
            gridEpisodes: _gridEpisodes,
            reverseEpisodes: _reverseEpisodes,
            sourceGroupOpen: _sourceGroupOpen,
            sourceGroup: _sourceGroup,
            sourceMatrixStatus: _sourceMatrixStatus,
            onTab: (tab) => setState(() => _tab = tab),
            onToggleGrid: () => setState(() => _gridEpisodes = !_gridEpisodes),
            onToggleReverse: () =>
                setState(() => _reverseEpisodes = !_reverseEpisodes),
            onToggleSourceGroup: () =>
                setState(() => _sourceGroupOpen = !_sourceGroupOpen),
            onSourceGroup: (group) => setState(() {
              _sourceGroup = group;
              _sourceGroupOpen = false;
            }),
            onExportMatrix: () => setState(() => _sourceMatrixStatus = '矩阵已复制'),
            onEpisode: _selectEpisode,
          ),
        ),
      ],
    );
  }

  AnimeEpisode? _activeEpisode(List<AnimeEpisode> episodes) {
    if (episodes.isEmpty) return null;
    final targetId = _selectedEpisodeId ?? widget.initialEpisodeId;
    if (targetId != null) {
      for (final episode in episodes) {
        if (episode.id == targetId) return episode;
      }
    }
    return episodes.first;
  }

  void _selectEpisode(AnimeEpisode episode) {
    setState(() => _selectedEpisodeId = episode.id);
  }
}

class _WatchLoading extends StatelessWidget {
  const _WatchLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _WatchError extends ConsumerWidget {
  const _WatchError({required this.subjectId, required this.error});

  final int subjectId;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SizedBox(
        width: 520,
        child: YnekoPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              YnekoEmptyState(
                icon: Icons.cloud_off_rounded,
                title: '播放页加载失败',
                description: error.toString(),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.invalidate(watchSubjectDetailProvider(subjectId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchPlaybackStage extends StatefulWidget {
  const _WatchPlaybackStage({
    required this.subject,
    required this.episode,
    required this.episodes,
    required this.hasPreviousEpisode,
    required this.hasNextEpisode,
    required this.onBack,
    required this.onPreviousEpisode,
    required this.onNextEpisode,
    required this.onSelectEpisode,
  });

  final AnimeSubject subject;
  final AnimeEpisode? episode;
  final List<AnimeEpisode> episodes;
  final bool hasPreviousEpisode;
  final bool hasNextEpisode;
  final VoidCallback onBack;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;
  final ValueChanged<AnimeEpisode> onSelectEpisode;

  @override
  State<_WatchPlaybackStage> createState() => _WatchPlaybackStageState();
}

class _WatchPlaybackStageState extends State<_WatchPlaybackStage> {
  bool _playing = false;
  bool _controlsVisible = true;
  String _activePanel = '';
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    final title = _title;

    return MouseRegion(
      onEnter: (_) => setState(() => _controlsVisible = true),
      onHover: (_) => setState(() => _controlsVisible = true),
      onExit: (_) => setState(() => _controlsVisible = true),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PlayerCenterPlayGlyph(
                      playing: _playing,
                      onTap: () => setState(() => _playing = !_playing),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _playing ? '正在播放 UI 预览' : '等待播放源',
                      style: type.sectionTitle.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.episode == null
                          ? 'subject=${widget.subject.id}'
                          : 'subject=${widget.subject.id} episode=${widget.episode!.id}',
                      style: type.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 18,
              right: 14,
              child: _PlayerChromeOpacity(
                visible: _controlsVisible,
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('watch-back-button'),
                      tooltip: '返回',
                      onPressed: widget.onBack,
                      color: Colors.white.withValues(alpha: 0.78),
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: type.controlTitle.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_activePanel.isNotEmpty)
              Positioned(
                right: _panelRight(),
                bottom: 78,
                child: _PlayerPopupPanel(
                  title: switch (_activePanel) {
                    'speed' => '倍速',
                    'episodes' => '选集',
                    'volume' => '音量',
                    'settings' => '设置',
                    _ => '弹幕',
                  },
                  child: switch (_activePanel) {
                    'speed' => const _SpeedOptions(),
                    'episodes' => _EpisodeOptions(
                      episodes: widget.episodes,
                      activeEpisodeId: widget.episode?.id,
                      onSelect: widget.onSelectEpisode,
                    ),
                    'volume' => const _VolumeOptions(),
                    'settings' => const _SettingsOptions(),
                    _ => const _DanmakuOptions(),
                  },
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              left: 0,
              child: _PlayerChromeOpacity(
                visible: _controlsVisible,
                child: _ControlBar(
                  playing: _playing,
                  muted: _muted,
                  progress: mockPlaybackState.progress,
                  positionLabel: mockPlaybackState.positionLabel,
                  durationLabel: mockPlaybackState.durationLabel,
                  activePanel: _activePanel,
                  onTogglePlay: () => setState(() => _playing = !_playing),
                  onToggleMute: () => setState(() => _muted = !_muted),
                  onPreviousEpisode: widget.onPreviousEpisode,
                  onNextEpisode: widget.onNextEpisode,
                  onTogglePanel: (panel) => setState(
                    () => _activePanel = _activePanel == panel ? '' : panel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title {
    final subject = watchSubjectTitle(widget.subject);
    final episode = widget.episode;
    if (episode == null) return subject;
    return '$subject [第${episode.sort.toString().padLeft(2, '0')}集]';
  }

  double _panelRight() {
    return switch (_activePanel) {
      'volume' => 82,
      'settings' => 44,
      'episodes' => 142,
      _ => 132,
    };
  }
}

class _PlayerChromeOpacity extends StatelessWidget {
  const _PlayerChromeOpacity({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: visible ? 1 : 0,
      child: child,
    );
  }
}

class _PlayerCenterPlayGlyph extends StatelessWidget {
  const _PlayerCenterPlayGlyph({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: playing
          ? const _PlayerSvgIcon(asset: YnekoAssets.playerPause, size: 34)
          : const Icon(
              Icons.play_arrow_rounded,
              size: 42,
              color: Color(0xFFFF5F99),
            ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.playing,
    required this.muted,
    required this.progress,
    required this.positionLabel,
    required this.durationLabel,
    required this.activePanel,
    required this.onTogglePlay,
    required this.onToggleMute,
    required this.onPreviousEpisode,
    required this.onNextEpisode,
    required this.onTogglePanel,
  });

  final bool playing;
  final bool muted;
  final double progress;
  final String positionLabel;
  final String durationLabel;
  final String activePanel;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;
  final ValueChanged<String> onTogglePanel;

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE6000000)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 56, 22, 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    color: const Color(0xFFFF6699),
                  ),
                ),
                const SizedBox(height: 13),
                if (compact)
                  Column(
                    children: [
                      Row(
                        children: [
                          _PlaybackCluster(
                            playing: playing,
                            onTogglePlay: onTogglePlay,
                            onPreviousEpisode: onPreviousEpisode,
                            onNextEpisode: onNextEpisode,
                          ),
                          const SizedBox(width: 10),
                          _TimeLabel(
                            type: type,
                            positionLabel: positionLabel,
                            durationLabel: durationLabel,
                          ),
                          const Spacer(),
                          _PlayerIconButton(
                            asset: YnekoAssets.playerDanmakuOn,
                            tooltip: '弹幕',
                            active: activePanel == 'danmaku',
                            onPressed: () => onTogglePanel('danmaku'),
                          ),
                          _PlayerTextButton(
                            label: '倍速',
                            active: activePanel == 'speed',
                            onPressed: () => onTogglePanel('speed'),
                          ),
                          _PlayerTextButton(
                            label: '选集',
                            active: activePanel == 'episodes',
                            onPressed: () => onTogglePanel('episodes'),
                          ),
                          _PlayerIconButton(
                            asset: YnekoAssets.playerSettings,
                            tooltip: '设置',
                            active: activePanel == 'settings',
                            onPressed: () => onTogglePanel('settings'),
                          ),
                          _PlayerIconButton(
                            asset: muted
                                ? YnekoAssets.playerMute
                                : YnekoAssets.playerVolume,
                            tooltip: muted ? '取消静音' : '音量',
                            active: activePanel == 'volume',
                            onPressed: () {
                              onToggleMute();
                              onTogglePanel('volume');
                            },
                          ),
                          _PlayerInlineIconButton(
                            tooltip: '全屏',
                            active: false,
                            onPressed: () {},
                            child: const _FullscreenIcon(),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      _PlaybackCluster(
                        playing: playing,
                        onTogglePlay: onTogglePlay,
                        onPreviousEpisode: onPreviousEpisode,
                        onNextEpisode: onNextEpisode,
                      ),
                      const SizedBox(width: 10),
                      _TimeLabel(
                        type: type,
                        positionLabel: positionLabel,
                        durationLabel: durationLabel,
                      ),
                      const SizedBox(width: 22),
                      _PlayerIconButton(
                        asset: YnekoAssets.playerDanmakuOn,
                        tooltip: '弹幕',
                        active: activePanel == 'danmaku',
                        onPressed: () => onTogglePanel('danmaku'),
                      ),
                      const SizedBox(width: 8),
                      const _DanmakuInput(),
                      const Spacer(),
                      _PlayerTextButton(
                        label: '超分',
                        active: false,
                        onPressed: () {},
                      ),
                      _PlayerIconButton(
                        asset: YnekoAssets.playerSettings,
                        tooltip: '设置',
                        active: activePanel == 'settings',
                        onPressed: () => onTogglePanel('settings'),
                      ),
                      _PlayerTextButton(
                        label: '倍速',
                        active: activePanel == 'speed',
                        onPressed: () => onTogglePanel('speed'),
                      ),
                      _PlayerTextButton(
                        label: '选集',
                        active: activePanel == 'episodes',
                        onPressed: () => onTogglePanel('episodes'),
                      ),
                      _PlayerIconButton(
                        asset: muted
                            ? YnekoAssets.playerMute
                            : YnekoAssets.playerVolume,
                        tooltip: muted ? '取消静音' : '音量',
                        active: activePanel == 'volume',
                        onPressed: () {
                          onToggleMute();
                          onTogglePanel('volume');
                        },
                      ),
                      _PlayerInlineIconButton(
                        tooltip: '全屏',
                        active: false,
                        onPressed: () {},
                        child: const _FullscreenIcon(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaybackCluster extends StatelessWidget {
  const _PlaybackCluster({
    required this.playing,
    required this.onTogglePlay,
    required this.onPreviousEpisode,
    required this.onNextEpisode,
  });

  final bool playing;
  final VoidCallback onTogglePlay;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlayerIconButton(
          asset: YnekoAssets.playerEpisodePrevious,
          tooltip: '上一集',
          onPressed: onPreviousEpisode,
        ),
        const SizedBox(width: 4),
        _PlayerIconButton(
          asset: playing ? YnekoAssets.playerPause : YnekoAssets.playerPlay,
          tooltip: playing ? '暂停' : '播放',
          onPressed: onTogglePlay,
        ),
        const SizedBox(width: 4),
        _PlayerIconButton(
          asset: YnekoAssets.playerEpisodeNext,
          tooltip: '下一集',
          onPressed: onNextEpisode,
        ),
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.type,
    required this.positionLabel,
    required this.durationLabel,
  });

  final YnekoTypography type;
  final String positionLabel;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$positionLabel / $durationLabel',
      overflow: TextOverflow.ellipsis,
      style: type.label.copyWith(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DanmakuInput extends StatelessWidget {
  const _DanmakuInput();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 332,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2F3032),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '发个友善的弹幕见证当下',
                overflow: TextOverflow.ellipsis,
                style: YnekoTypography.of(context).label.copyWith(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 58,
              height: 32,
              margin: const EdgeInsets.only(right: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5F99),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                '发送',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    required this.asset,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final String asset;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return _PlayerInlineIconButton(
      tooltip: tooltip,
      active: active,
      onPressed: onPressed,
      child: _PlayerSvgIcon(asset: asset, size: 22),
    );
  }
}

class _PlayerInlineIconButton extends StatelessWidget {
  const _PlayerInlineIconButton({
    required this.tooltip,
    required this.active,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final bool active;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        color: active
            ? const Color(0xFFFF6699)
            : onPressed == null
            ? Colors.white.withValues(alpha: 0.34)
            : Colors.white,
        icon: child,
      ),
    );
  }
}

class _PlayerTextButton extends StatelessWidget {
  const _PlayerTextButton({
    required this.label,
    required this.onPressed,
    required this.active,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: active ? const Color(0xFFFF6699) : Colors.white,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _PlayerSvgIcon extends StatelessWidget {
  const _PlayerSvgIcon({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      key: ValueKey('player-svg-$asset'),
      width: size,
      height: size,
    );
  }
}

class _FullscreenIcon extends StatelessWidget {
  const _FullscreenIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <path fill="currentColor" d="M298.425 191.023c-56.075 37.617-102.832 91.055-132.539 151.348-23.203 46.934-38.848 109.336-38.848 153.984v15.645h134.473c74.004 0 134.473-0.352 134.473-0.703 0-7.207 4.747-30.762 7.911-39.023 7.911-21.094 24.083-42.188 41.309-53.789 4.395-2.989 8.262-5.801 8.614-5.977 0.703-0.703-133.945-234.492-135.176-234.492-0.528 0-9.668 5.977-20.215 13.008z"/>
  <path fill="currentColor" d="M702.195 183.641c-14.59 24.434-130.43 226.406-130.43 227.636 0 0.879 4.922 5.098 10.898 9.317 12.832 9.492 25.664 24.786 33.047 39.727 6.153 12.481 12.305 34.98 12.305 45v6.68h270.703v-8.614c0-42.364-13.008-100.547-32.344-144.844-31.465-72.246-88.418-137.637-153.457-176.133l-7.207-4.395-3.516 5.625z"/>
  <path fill="currentColor" d="M501.453 435.886c-42.715 7.207-72.422 47.637-65.039 88.77 5.273 29.531 24.258 51.503 53.086 61.348 21.445 7.208 50.45 2.286 68.906-11.778 19.161-14.59 29.18-33.926 30.41-58.711 1.406-23.379-6.328-42.364-23.73-59.063-16.523-15.997-42.188-24.258-63.633-20.567z"/>
  <path fill="currentColor" d="M452.761 616.063c-4.747 6.153-131.133 226.934-131.309 229.395-0.176 3.691 29.707 18.984 57.832 29.355 82.266 30.234 171.563 31.641 255.411 3.692 19.688-6.504 60.645-24.609 68.555-30.234 1.582-1.23-15.117-31.465-64.688-117.422-36.739-63.633-67.148-116.191-67.676-116.543-0.352-0.527-5.45 1.231-11.075 3.692-26.367 11.953-57.481 13.183-84.727 3.516-8.262-2.989-16.172-5.801-17.754-6.504-1.582-0.703-3.516-0.176-4.57 1.055z"/>
</svg>
''',
      width: 22,
      height: 22,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }
}

class _PlayerPopupPanel extends StatelessWidget {
  const _PlayerPopupPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF21F2024),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
              child: Text(
                title,
                style: type.label.copyWith(color: Colors.white70),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _SpeedOptions extends StatelessWidget {
  const _SpeedOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final speed in ['2.0x', '1.5x', '1.25x', '1.0x', '0.75x'])
          _PanelChoice(label: speed, active: speed == '1.0x'),
      ],
    );
  }
}

class _EpisodeOptions extends StatelessWidget {
  const _EpisodeOptions({
    required this.episodes,
    required this.activeEpisodeId,
    required this.onSelect,
  });

  final List<AnimeEpisode> episodes;
  final int? activeEpisodeId;
  final ValueChanged<AnimeEpisode> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: episodes.isEmpty
          ? const Text('暂无剧集', style: TextStyle(color: Colors.white70))
          : Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final episode in episodes)
                  SizedBox(
                    width: 44,
                    height: 30,
                    child: _PanelChoice(
                      label: '${episode.sort}',
                      active: episode.id == activeEpisodeId,
                      onTap: () => onSelect(episode),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _VolumeOptions extends StatelessWidget {
  const _VolumeOptions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 140,
      child: RotatedBox(
        quarterTurns: -1,
        child: Slider(value: 0.72, onChanged: (_) {}),
      ),
    );
  }
}

class _SettingsOptions extends StatelessWidget {
  const _SettingsOptions();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 220,
      child: Column(
        children: [
          _PanelChoice(label: '画面比例 · 自适应', active: true),
          _PanelChoice(label: '超分辨率 · 关闭'),
          _PanelChoice(label: '镜像画面 · 关闭'),
        ],
      ),
    );
  }
}

class _DanmakuOptions extends StatelessWidget {
  const _DanmakuOptions();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 220,
      child: Column(
        children: [
          _PanelChoice(label: '显示弹幕', active: true),
          _PanelChoice(label: '弹幕设置'),
          _PanelChoice(label: '透明度 78%'),
        ],
      ),
    );
  }
}

class _PanelChoice extends StatelessWidget {
  const _PanelChoice({required this.label, this.active = false, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap ?? () {},
      style: TextButton.styleFrom(
        foregroundColor: active ? const Color(0xFFFF6699) : Colors.white70,
        backgroundColor: active
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _WatchSidePanel extends StatelessWidget {
  const _WatchSidePanel({
    required this.detail,
    required this.activeEpisode,
    required this.episodes,
    required this.activeEpisodeId,
    required this.tab,
    required this.gridEpisodes,
    required this.reverseEpisodes,
    required this.sourceGroupOpen,
    required this.sourceGroup,
    required this.sourceMatrixStatus,
    required this.onTab,
    required this.onToggleGrid,
    required this.onToggleReverse,
    required this.onToggleSourceGroup,
    required this.onSourceGroup,
    required this.onExportMatrix,
    required this.onEpisode,
  });

  final SubjectDetail detail;
  final AnimeEpisode? activeEpisode;
  final List<AnimeEpisode> episodes;
  final int? activeEpisodeId;
  final _WatchPanelTab tab;
  final bool gridEpisodes;
  final bool reverseEpisodes;
  final bool sourceGroupOpen;
  final String sourceGroup;
  final String sourceMatrixStatus;
  final ValueChanged<_WatchPanelTab> onTab;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleReverse;
  final VoidCallback onToggleSourceGroup;
  final ValueChanged<String> onSourceGroup;
  final VoidCallback onExportMatrix;
  final ValueChanged<AnimeEpisode> onEpisode;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      color: const Color(0xFFF7F7F8),
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.fromLTRB(28, 0, 24, 0),
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border(bottom: BorderSide(color: tokens.dividerFaint)),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => WindowChromeService.startDragging(),
              child: Row(
                children: [
                  _TopPanelTab(label: '概览', active: true, onTap: () {}),
                  const SizedBox(width: 28),
                  _TopPanelTab(label: '评论', active: false, onTap: () {}),
                  const SizedBox(width: 28),
                  _TopPanelTab(label: '更多', active: false, onTap: () {}),
                  const Spacer(),
                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: tokens.dividerSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const YnekoWindowControls(),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              children: [
                _OverviewCard(detail: detail, activeEpisode: activeEpisode),
                const SizedBox(height: 16),
                _EpisodeSwitchCard(
                  tab: tab,
                  episodes: episodes,
                  activeEpisodeId: activeEpisodeId,
                  gridEpisodes: gridEpisodes,
                  reverseEpisodes: reverseEpisodes,
                  sourceGroupOpen: sourceGroupOpen,
                  sourceGroup: sourceGroup,
                  sourceMatrixStatus: sourceMatrixStatus,
                  onTab: onTab,
                  onToggleGrid: onToggleGrid,
                  onToggleReverse: onToggleReverse,
                  onToggleSourceGroup: onToggleSourceGroup,
                  onSourceGroup: onSourceGroup,
                  onExportMatrix: onExportMatrix,
                  onEpisode: onEpisode,
                ),
                const SizedBox(height: 16),
                const _RecommendationCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPanelTab extends StatelessWidget {
  const _TopPanelTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFFFF5F99) : Colors.black,
                fontSize: 16,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
            if (active)
              Positioned(
                bottom: 10,
                child: Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5F99),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.detail, required this.activeEpisode});

  final SubjectDetail detail;
  final AnimeEpisode? activeEpisode;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final subject = detail.subject;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.outline.withValues(alpha: 0.66)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  watchSubjectTitle(subject),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.cardTitle.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border_rounded, size: 17),
                label: const Text('追番'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5F99),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(102, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activeEpisode == null
                ? '连载中，等待剧集同步'
                : '连载中，更新至第 ${activeEpisode!.sort} 话',
            style: type.label.copyWith(
              color: const Color(0xFF5F6672),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: tokens.dividerFaint, height: 1),
          const SizedBox(height: 12),
          Text(
            '简介',
            style: type.controlTitle.copyWith(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: [
              _InlineMeta(label: watchSubjectAirDateLabel(subject)),
              _InlineMeta(label: watchSubjectScoreLabel(subject)),
              _InlineMeta(
                label: watchSubjectEpisodeCountLabel(subject, detail.episodes),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subject.summary ?? 'Bangumi 暂无简介。',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: type.body.copyWith(
              color: const Color(0xFF536171),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF00A1D6),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EpisodeSwitchCard extends StatelessWidget {
  const _EpisodeSwitchCard({
    required this.tab,
    required this.episodes,
    required this.activeEpisodeId,
    required this.gridEpisodes,
    required this.reverseEpisodes,
    required this.sourceGroupOpen,
    required this.sourceGroup,
    required this.sourceMatrixStatus,
    required this.onTab,
    required this.onToggleGrid,
    required this.onToggleReverse,
    required this.onToggleSourceGroup,
    required this.onSourceGroup,
    required this.onExportMatrix,
    required this.onEpisode,
  });

  final _WatchPanelTab tab;
  final List<AnimeEpisode> episodes;
  final int? activeEpisodeId;
  final bool gridEpisodes;
  final bool reverseEpisodes;
  final bool sourceGroupOpen;
  final String sourceGroup;
  final String sourceMatrixStatus;
  final ValueChanged<_WatchPanelTab> onTab;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleReverse;
  final VoidCallback onToggleSourceGroup;
  final ValueChanged<String> onSourceGroup;
  final VoidCallback onExportMatrix;
  final ValueChanged<AnimeEpisode> onEpisode;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.outline.withValues(alpha: 0.66)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '选集 (${activeEpisodeId == null ? 0 : 1}/${episodes.length})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              _SmallIconButton(
                key: const ValueKey('episode-reverse-toggle'),
                tooltip: reverseEpisodes ? '正序' : '倒序',
                icon: Icons.format_line_spacing_rounded,
                onTap: onToggleReverse,
                active: reverseEpisodes,
              ),
              const SizedBox(width: 8),
              _SmallIconButton(
                key: const ValueKey('episode-layout-toggle'),
                tooltip: gridEpisodes ? '列表' : '网格',
                icon: gridEpisodes
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                onTap: onToggleGrid,
                active: gridEpisodes,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 146,
                child: _PanelTabs(tab: tab, onTab: onTab),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: tab == _WatchPanelTab.episodes ? 330 : 282,
            child: switch (tab) {
              _WatchPanelTab.episodes => _EpisodesPanel(
                episodes: episodes,
                activeEpisodeId: activeEpisodeId,
                grid: gridEpisodes,
                reversed: reverseEpisodes,
                onToggleGrid: onToggleGrid,
                onToggleReverse: onToggleReverse,
                onEpisode: onEpisode,
                embedded: true,
              ),
              _WatchPanelTab.series => const _SeriesPanel(currentSubjectId: -1),
              _WatchPanelTab.sources => _SourcesPanel(
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

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final item = mockAnimeCards.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.outline.withValues(alpha: 0.66)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '相关推荐',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '喜欢这部动画的人也喜欢',
                style: YnekoTypography.of(context).label.copyWith(
                  color: const Color(0xFF5F6672),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: tokens.outline.withValues(alpha: 0.62)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.coverColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.title.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.subtitle} · 评分 ${item.score}',
                        overflow: TextOverflow.ellipsis,
                        style: YnekoTypography.of(context).meta,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTabs extends StatelessWidget {
  const _PanelTabs({required this.tab, required this.onTab});

  final _WatchPanelTab tab;
  final ValueChanged<_WatchPanelTab> onTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PanelTabButton(
          label: '剧集',
          icon: Icons.playlist_play_rounded,
          active: tab == _WatchPanelTab.episodes,
          onTap: () => onTab(_WatchPanelTab.episodes),
        ),
        _PanelTabButton(
          label: '系列',
          icon: Icons.auto_stories_rounded,
          active: tab == _WatchPanelTab.series,
          onTap: () => onTab(_WatchPanelTab.series),
        ),
        _PanelTabButton(
          label: '规则源',
          icon: Icons.tune_rounded,
          active: tab == _WatchPanelTab.sources,
          onTap: () => onTab(_WatchPanelTab.sources),
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
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: active ? Colors.white : tokens.muted,
          backgroundColor: active ? tokens.primary : tokens.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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
    this.embedded = false,
  });

  final List<AnimeEpisode> episodes;
  final int? activeEpisodeId;
  final bool grid;
  final bool reversed;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleReverse;
  final ValueChanged<AnimeEpisode> onEpisode;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final list = episodes.isEmpty
            ? const YnekoEmptyState(
                icon: Icons.live_tv_rounded,
                title: '暂无剧集',
                description: 'Bangumi 暂未返回可播放剧集。',
              )
            : grid
            ? GridView.builder(
                key: const ValueKey('episode-grid-panel'),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EpisodeTile(
                      episode: episode,
                      active: episode.id == activeEpisodeId,
                      grid: false,
                      onTap: () => onEpisode(episode),
                    ),
                  );
                },
              );

        if (embedded) return list;

        return Container(
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
                child: list,
              ),
            ],
          ),
        );
      },
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

  final AnimeEpisode episode;
  final bool active;
  final bool grid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Material(
      color: active
          ? const Color(0xFFFFF0F6)
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
          constraints: BoxConstraints(minHeight: grid ? 58 : 44),
          padding: EdgeInsets.symmetric(horizontal: grid ? 0 : 12),
          child: grid
              ? Center(
                  child: Text(
                    '${episode.sort}',
                    style: type.controlTitle.copyWith(
                      color: active ? tokens.primaryStrong : tokens.ink,
                    ),
                  ),
                )
              : Row(
                  children: [
                    Text(
                      '第${episode.sort}话',
                      style: type.controlTitle.copyWith(
                        color: active ? const Color(0xFFFF5F99) : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        episode.displayTitle,
                        overflow: TextOverflow.ellipsis,
                        style: type.meta.copyWith(
                          color: active
                              ? const Color(0xFFFF5F99)
                              : const Color(0xFF1D2229),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
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
