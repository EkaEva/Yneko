import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../infrastructure/player/player_adapter.dart';
import '../../../infrastructure/platform/window_chrome/index.dart';
import '../../shell/index.dart';
import '../../sources/index.dart';
import '../application/watch_providers.dart';
import '../../../shared/assets/index.dart';
import '../../../shared/domain/index.dart';
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
  int? _selectedEpisodeId;

  @override
  void didUpdateWidget(covariant WatchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId ||
        oldWidget.initialEpisodeId != widget.initialEpisodeId) {
      _selectedEpisodeId = widget.initialEpisodeId;
      _tab = _WatchPanelTab.episodes;
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
            playbackKey: activeEpisode == null
                ? null
                : WatchPlaybackKey(
                    subjectId: detail.subject.id,
                    episodeId: activeEpisode.id,
                  ),
            onTab: (tab) => setState(() => _tab = tab),
            onToggleGrid: () => setState(() => _gridEpisodes = !_gridEpisodes),
            onToggleReverse: () =>
                setState(() => _reverseEpisodes = !_reverseEpisodes),
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
    return const YnekoLoadingState(title: '正在打开播放页', minHeight: 520);
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
              YnekoActionButton(
                onPressed: () =>
                    ref.invalidate(watchSubjectDetailProvider(subjectId)),
                icon: const Icon(Icons.refresh_rounded),
                label: '重试',
                tone: YnekoActionButtonTone.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchPlaybackStage extends ConsumerStatefulWidget {
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
  ConsumerState<_WatchPlaybackStage> createState() =>
      _WatchPlaybackStageState();
}

class _WatchPlaybackStageState extends ConsumerState<_WatchPlaybackStage> {
  bool _controlsVisible = true;
  String _activePanel = '';
  VideoController? _videoController;
  Object? _videoPlayerIdentity;

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    final title = _title;
    final playbackKey = widget.episode == null
        ? null
        : WatchPlaybackKey(
            subjectId: widget.subject.id,
            episodeId: widget.episode!.id,
          );
    final playback = playbackKey == null
        ? null
        : ref.watch(watchPlayerControllerProvider(playbackKey));
    final playbackController = playbackKey == null
        ? null
        : ref.read(watchPlayerControllerProvider(playbackKey).notifier);
    final snapshot = playback?.playerSnapshot ?? const PlayerSnapshot();
    final video = playback == null ? null : _videoFor(playback);

    return MouseRegion(
      onEnter: (_) => setState(() => _controlsVisible = true),
      onHover: (_) => setState(() => _controlsVisible = true),
      onExit: (_) => setState(() => _controlsVisible = true),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ?video,
                  if (playback == null ||
                      playback.selectedCandidate == null ||
                      playback.searching ||
                      playback.binding ||
                      playback.opening ||
                      playback.error != null)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (playback?.searching == true ||
                              playback?.binding == true ||
                              playback?.opening == true)
                            const YnekoRingLoader(size: 64)
                          else
                            _PlayerCenterPlayGlyph(
                              playing: snapshot.playing,
                              onTap: playbackController?.togglePlay,
                            ),
                          const SizedBox(height: 10),
                          Text(
                            _stageMessage(playback),
                            style: type.sectionTitle.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            playback?.error ??
                                playback?.selectedCandidate?.title ??
                                (widget.episode == null
                                    ? '请选择剧集'
                                    : '等待规则源返回播放候选'),
                            textAlign: TextAlign.center,
                            style: type.label.copyWith(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                    YnekoIconActionButton(
                      key: const ValueKey('watch-back-button'),
                      tooltip: '返回',
                      onPressed: widget.onBack,
                      tone: YnekoActionButtonTone.ghost,
                      transparent: true,
                      size: 40,
                      iconSize: 28,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white.withValues(alpha: 0.82),
                        size: 28,
                      ),
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
                    'speed' => _SpeedOptions(
                      value: snapshot.rate,
                      onChanged: playbackController?.setRate,
                    ),
                    'episodes' => _EpisodeOptions(
                      episodes: widget.episodes,
                      activeEpisodeId: widget.episode?.id,
                      onSelect: widget.onSelectEpisode,
                    ),
                    'volume' => _VolumeOptions(
                      value: snapshot.muted ? 0 : snapshot.volume,
                      onChanged: playbackController?.setVolume,
                    ),
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
                  playing: snapshot.playing,
                  muted: snapshot.muted,
                  progress: snapshot.progress,
                  positionLabel: _formatDuration(snapshot.position),
                  durationLabel: _formatDuration(snapshot.duration),
                  activePanel: _activePanel,
                  onTogglePlay: playbackController?.togglePlay,
                  onSeek: playbackController?.seekFraction,
                  onToggleMute: playbackController?.toggleMute,
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

  Widget _videoFor(WatchPlaybackState playback) {
    final player = playback.player.player;
    if (player == null) return const SizedBox.shrink();
    final identity = player;
    if (_videoController == null || _videoPlayerIdentity != identity) {
      _videoPlayerIdentity = identity;
      _videoController = VideoController(player);
    }
    return Video(
      key: const ValueKey('watch-video-surface'),
      controller: _videoController!,
      controls: NoVideoControls,
      fit: BoxFit.contain,
      fill: Colors.black,
    );
  }

  String _stageMessage(WatchPlaybackState? playback) {
    if (playback == null) return '暂无剧集';
    if (playback.searching) return '正在搜索候选源';
    if (playback.binding) return '正在匹配剧集';
    if (playback.opening) return '正在打开播放器';
    if (playback.error != null) return '播放源不可用';
    if (playback.selectedCandidate != null) return '播放准备就绪';
    if (playback.candidates.isEmpty) return '没有可用播放源';
    return '请选择播放候选';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
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
  final VoidCallback? onTap;

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
    required this.onSeek,
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
  final VoidCallback? onTogglePlay;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onToggleMute;
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
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: const Color(0xFFFF6699),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                    thumbColor: Colors.white,
                    overlayColor: const Color(0x33FF6699),
                  ),
                  child: Slider(
                    value: progress.clamp(0, 1).toDouble(),
                    onChanged: onSeek,
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
                            onPressed: onToggleMute == null
                                ? null
                                : () {
                                    onToggleMute!();
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
                        onPressed: onToggleMute == null
                            ? null
                            : () {
                                onToggleMute!();
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
  final VoidCallback? onTogglePlay;
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
    final color = active
        ? const Color(0xFFFF6699)
        : onPressed == null
        ? Colors.white.withValues(alpha: 0.34)
        : Colors.white;
    return YnekoIconActionButton(
      tooltip: tooltip,
      onPressed: onPressed,
      tone: YnekoActionButtonTone.ghost,
      transparent: true,
      size: 38,
      iconSize: 22,
      icon: IconTheme(
        data: IconThemeData(color: color, size: 22),
        child: child,
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
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return YnekoActionButton(
      label: label,
      onPressed: onPressed,
      tone: YnekoActionButtonTone.ghost,
      height: 32,
      minWidth: 42,
      horizontalPadding: 8,
      textStyle: TextStyle(
        color: active ? const Color(0xFFFF6699) : Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        height: 1,
      ),
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
      colorFilter: ColorFilter.mode(
        IconTheme.of(context).color ?? Colors.white,
        BlendMode.srcIn,
      ),
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
  const _SpeedOptions({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final speeds = const [2.0, 1.5, 1.25, 1.0, 0.75];
    return Column(
      children: [
        for (final speed in speeds)
          _PanelChoice(
            label: '${speed}x',
            active: (value - speed).abs() < 0.01,
            onTap: onChanged == null ? null : () => onChanged!(speed),
          ),
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
  const _VolumeOptions({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 140,
      child: RotatedBox(
        quarterTurns: -1,
        child: Slider(
          value: (value / 100).clamp(0, 1).toDouble(),
          onChanged: onChanged == null
              ? null
              : (next) => onChanged!(next * 100),
        ),
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
    return YnekoPressable(
      onTap: onTap,
      borderRadius: 4,
      builder: (context, hovered, pressed) {
        final highlighted = active || hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          constraints: const BoxConstraints(minHeight: 32),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.white.withValues(alpha: active ? 0.08 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? const Color(0xFFFF6699) : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
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
    required this.playbackKey,
    required this.onTab,
    required this.onToggleGrid,
    required this.onToggleReverse,
    required this.onEpisode,
  });

  final SubjectDetail detail;
  final AnimeEpisode? activeEpisode;
  final List<AnimeEpisode> episodes;
  final int? activeEpisodeId;
  final _WatchPanelTab tab;
  final bool gridEpisodes;
  final bool reverseEpisodes;
  final WatchPlaybackKey? playbackKey;
  final ValueChanged<_WatchPanelTab> onTab;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleReverse;
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
                  playbackKey: playbackKey,
                  onTab: onTab,
                  onToggleGrid: onToggleGrid,
                  onToggleReverse: onToggleReverse,
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
              _FollowMenu(subject: subject),
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

const _followStatusOptions = [
  CollectionStatus.watching,
  CollectionStatus.wish,
  CollectionStatus.watched,
  CollectionStatus.paused,
  CollectionStatus.dropped,
];

class _FollowMenu extends ConsumerStatefulWidget {
  const _FollowMenu({required this.subject});

  final AnimeSubject subject;

  @override
  ConsumerState<_FollowMenu> createState() => _FollowMenuState();
}

class _FollowMenuState extends ConsumerState<_FollowMenu> {
  final Object _tapRegionGroup = Object();
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
  final _buttonBoundsKey = GlobalKey();
  final _panelBoundsKey = GlobalKey();
  Timer? _closeTimer;
  bool _open = false;
  bool _hovered = false;
  bool _outsidePointerRouteActive = false;

  @override
  void dispose() {
    _stopOutsidePointerRoute();
    _closeTimer?.cancel();
    super.dispose();
  }

  void _clearCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _setOpen(bool open) {
    _clearCloseTimer();
    setState(() => _open = open);
    if (open) {
      _overlayController.show();
      _startOutsidePointerRoute();
    } else {
      _overlayController.hide();
      _stopOutsidePointerRoute();
    }
  }

  void _queueClose() {
    _clearCloseTimer();
    _closeTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _setOpen(false);
      _closeTimer = null;
    });
  }

  Future<void> _setStatus(CollectionStatus status) {
    return ref
        .read(watchFavoriteProvider(widget.subject.id).notifier)
        .setStatus(widget.subject, status);
  }

  Future<void> _cancelFollow() {
    return ref.read(watchFavoriteProvider(widget.subject.id).notifier).cancel();
  }

  bool _containsGlobalPoint(GlobalKey key, Offset point) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return (topLeft & renderObject.size).contains(point);
  }

  void _startOutsidePointerRoute() {
    if (_outsidePointerRouteActive) return;
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _handleGlobalPointerEvent,
    );
    _outsidePointerRouteActive = true;
  }

  void _stopOutsidePointerRoute() {
    if (!_outsidePointerRouteActive) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointerEvent,
    );
    _outsidePointerRouteActive = false;
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) return;
    if (!_open) return;
    final position = event.position;
    if (_containsGlobalPoint(_panelBoundsKey, position)) return;
    if (_containsGlobalPoint(_buttonBoundsKey, position)) return;
    _setOpen(false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : YnekoThemeTokens.fastMotion;
    final favorite = ref.watch(watchFavoriteProvider(widget.subject.id));
    final status = favorite.maybeWhen(
      data: (item) => item?.status,
      orElse: () => null,
    );
    final marked = status != null;
    final label = marked ? collectionStatusLabel(status) : '追番';
    return TapRegion(
      groupId: _tapRegionGroup,
      onTapOutside: (_) {
        if (_open) _setOpen(false);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() {
          _clearCloseTimer();
          _hovered = true;
          if (marked) {
            _open = true;
            _overlayController.show();
          }
        }),
        onExit: (_) {
          setState(() => _hovered = false);
          if (marked) _queueClose();
        },
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) => TapRegion(
            groupId: _tapRegionGroup,
            child: MouseRegion(
              onEnter: (_) => _clearCloseTimer(),
              onExit: (_) => _queueClose(),
              child: CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 8),
                showWhenUnlinked: false,
                child: UnconstrainedBox(
                  alignment: Alignment.topRight,
                  child: AnimatedOpacity(
                    duration: motion,
                    opacity: _open ? 1 : 0,
                    child: AnimatedSlide(
                      duration: motion,
                      curve: Curves.easeOut,
                      offset: _open ? Offset.zero : const Offset(0, -0.16),
                      child: KeyedSubtree(
                        key: _panelBoundsKey,
                        child: _FollowMenuPanel(
                          status: status,
                          onStatus: (nextStatus) {
                            _setStatus(nextStatus);
                            _setOpen(false);
                          },
                          onCancel: () {
                            _cancelFollow();
                            _setOpen(false);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: SizedBox(
            key: _buttonBoundsKey,
            width: 82,
            height: 34,
            child: CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!marked) {
                    _setStatus(CollectionStatus.watching);
                  } else {
                    _setOpen(!_open);
                  }
                },
                child: AnimatedSlide(
                  duration: motion,
                  curve: Curves.easeOut,
                  offset:
                      (_hovered || _open) &&
                          !MediaQuery.disableAnimationsOf(context)
                      ? const Offset(0, -0.03)
                      : Offset.zero,
                  child: AnimatedContainer(
                    key: const ValueKey('watch-follow-button'),
                    duration: motion,
                    curve: Curves.easeOut,
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: marked
                          ? (_hovered || _open
                                ? Color.lerp(
                                    tokens.ink,
                                    tokens.surfaceHigh,
                                    0.86,
                                  )
                                : Color.lerp(
                                    tokens.ink,
                                    tokens.surfaceHigh,
                                    0.91,
                                  ))
                          : (_hovered || _open
                                ? Color.lerp(tokens.primary, Colors.white, 0.16)
                                : tokens.primary),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: marked
                            ? tokens.outline.withValues(alpha: 0.50)
                            : Colors.transparent,
                      ),
                      boxShadow: marked
                          ? null
                          : (_hovered || _open)
                          ? [
                              BoxShadow(
                                color: tokens.primary.withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          marked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: marked
                              ? (_hovered || _open ? tokens.ink : tokens.muted)
                              : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: type.label.copyWith(
                              color: marked
                                  ? (_hovered || _open
                                        ? tokens.ink
                                        : tokens.muted)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowMenuPanel extends StatelessWidget {
  const _FollowMenuPanel({
    required this.status,
    required this.onStatus,
    required this.onCancel,
  });

  final CollectionStatus? status;
  final ValueChanged<CollectionStatus> onStatus;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return ConstrainedBox(
      key: const ValueKey('watch-follow-panel'),
      constraints: const BoxConstraints.tightFor(width: 82),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.82)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in _followStatusOptions)
                _FollowMenuOption(
                  key: ValueKey(
                    'watch-follow-option-${_followStatusKey(item)}',
                  ),
                  label: collectionStatusLabel(item),
                  active: item == status,
                  onTap: () => onStatus(item),
                ),
              _FollowMenuOption(
                key: const ValueKey('watch-follow-option-cancel'),
                label: '取消标记',
                danger: true,
                onTap: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowMenuOption extends StatefulWidget {
  const _FollowMenuOption({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  State<_FollowMenuOption> createState() => _FollowMenuOptionState();
}

class _FollowMenuOptionState extends State<_FollowMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final dangerColor = const Color(0xFFBD2D3A);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration.zero,
          constraints: const BoxConstraints(minWidth: 82, minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: _hovered ? tokens.primaryContainer : Colors.transparent,
          child: Text(
            widget.label,
            style: type.label.copyWith(
              color: widget.danger
                  ? dangerColor
                  : _hovered
                  ? tokens.primary
                  : widget.active
                  ? tokens.ink
                  : tokens.muted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

String _followStatusKey(CollectionStatus status) {
  return switch (status) {
    CollectionStatus.watching => 'watching',
    CollectionStatus.wish => 'planned',
    CollectionStatus.watched => 'completed',
    CollectionStatus.paused => 'paused',
    CollectionStatus.dropped => 'dropped',
  };
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
    required this.playbackKey,
    required this.onTab,
    required this.onToggleGrid,
    required this.onToggleReverse,
    required this.onEpisode,
  });

  final _WatchPanelTab tab;
  final List<AnimeEpisode> episodes;
  final int? activeEpisodeId;
  final bool gridEpisodes;
  final bool reverseEpisodes;
  final WatchPlaybackKey? playbackKey;
  final ValueChanged<_WatchPanelTab> onTab;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleReverse;
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
              _WatchPanelTab.sources => _SourcesPanel(playbackKey: playbackKey),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.outline.withValues(alpha: 0.66)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '相关推荐',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          YnekoEmptyState(
            icon: Icons.auto_awesome_rounded,
            title: '推荐暂未接入',
            description: '后续会基于真实 Bangumi 关联与本地历史展示。',
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: YnekoActionButton(
          label: label,
          onPressed: onTap,
          tone: active
              ? YnekoActionButtonTone.primary
              : YnekoActionButtonTone.outline,
          height: 34,
          minWidth: 0,
          horizontalPadding: 8,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
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
    return YnekoPressable(
      onTap: onTap,
      builder: (context, hovered, pressed) {
        final highlighted = active || hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFFFF0F6)
                : highlighted
                ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.64)
                : grid
                ? tokens.surface
                : Colors.transparent,
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
        );
      },
    );
  }
}

class _SeriesPanel extends StatelessWidget {
  const _SeriesPanel({required this.currentSubjectId});

  final int currentSubjectId;

  @override
  Widget build(BuildContext context) {
    return const YnekoPanel(
      padding: EdgeInsets.all(14),
      child: YnekoEmptyState(
        icon: Icons.auto_stories_rounded,
        title: '系列信息暂未接入',
        description: '这里不会再展示假数据，后续接真实关联条目。',
      ),
    );
  }
}

class _SourcesPanel extends ConsumerWidget {
  const _SourcesPanel({required this.playbackKey});

  final WatchPlaybackKey? playbackKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(sourceLibraryControllerProvider);
    final playback = playbackKey == null
        ? null
        : ref.watch(watchPlayerControllerProvider(playbackKey!));
    final playbackController = playbackKey == null
        ? null
        : ref.read(watchPlayerControllerProvider(playbackKey!).notifier);
    return YnekoPanel(
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '规则源',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              YnekoActionButton(
                label: '搜索',
                onPressed: () => playbackController?.searchSources(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                tone: YnekoActionButtonTone.outline,
                height: 32,
                minWidth: 70,
              ),
            ],
          ),
          const SizedBox(height: 8),
          library.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: YnekoRingLoader(size: 42)),
            ),
            error: (error, stackTrace) => YnekoEmptyState(
              icon: Icons.error_outline_rounded,
              title: '规则源加载失败',
              description: error.toString(),
            ),
            data: (state) => _RuleGroupSummaryCard(
              state: state,
              onSearchGroup: (group) => playbackController?.searchSources(
                ruleIds: state.enabledRuleIdsForGroup(group.id),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (playback?.searching == true ||
              playback?.binding == true ||
              playback?.opening == true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: YnekoRingLoader()),
            )
          else if (playback?.error != null)
            YnekoEmptyState(
              icon: Icons.error_outline_rounded,
              title: '解析失败',
              description: playback!.error!,
            )
          else if (playback == null)
            const YnekoEmptyState(
              icon: Icons.live_tv_rounded,
              title: '暂无剧集',
              description: '选择剧集后会显示播放候选。',
            )
          else if (playback.candidates.isEmpty)
            const YnekoEmptyState(
              icon: Icons.tune_rounded,
              title: '没有可用播放源',
              description: '启用规则组后可重新搜索当前番剧。',
            )
          else
            _RuleSourceResultList(
              playback: playback,
              onCandidate: playbackController?.openCandidate,
            ),
          if (playback != null &&
              (playback.bindingAttempts.isNotEmpty ||
                  playback.streamAttempts.isNotEmpty)) ...[
            const SizedBox(height: 10),
            _AttemptList(
              attempts: [
                ...playback.bindingAttempts,
                ...playback.streamAttempts,
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RuleGroupSummaryCard extends StatelessWidget {
  const _RuleGroupSummaryCard({
    required this.state,
    required this.onSearchGroup,
  });

  final SourceLibraryState state;
  final ValueChanged<RuleGroupSummary> onSearchGroup;

  @override
  Widget build(BuildContext context) {
    if (state.packages.isEmpty) {
      return const YnekoEmptyState(
        icon: Icons.tune_rounded,
        title: '还没有规则源',
        description: '请到设置或规则源页面导入声明式规则包。',
      );
    }
    final group = state.defaultGroup;
    final enabled = group.enabledRuleCount(state.packages);
    return Column(
      children: [
        _SourceCurrentCard(
          title: group.name,
          subtitle: '${group.ruleIds.length} 个规则源，$enabled 个可用',
          onTap: () => onSearchGroup(group),
        ),
        const SizedBox(height: 8),
        for (final item in state.groups)
          _SourceGroupOption(
            group: item,
            enabledCount: item.enabledRuleCount(state.packages),
            onTap: () => onSearchGroup(item),
          ),
      ],
    );
  }
}

class _SourceCurrentCard extends StatelessWidget {
  const _SourceCurrentCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPressable(
      onTap: onTap,
      builder: (context, hovered, pressed) {
        final highlighted = hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlighted
                ? tokens.primaryContainer
                : Color.lerp(tokens.primaryContainer, tokens.surface, 0.45),
            border: Border.all(
              color: tokens.primary.withValues(
                alpha: highlighted ? 0.46 : 0.28,
              ),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: YnekoTypography.of(context).controlTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: YnekoTypography.of(context).meta),
                  ],
                ),
              ),
              Icon(Icons.search_rounded, size: 18, color: tokens.primary),
            ],
          ),
        );
      },
    );
  }
}

class _SourceGroupOption extends StatelessWidget {
  const _SourceGroupOption({
    required this.group,
    required this.enabledCount,
    required this.onTap,
  });

  final RuleGroupSummary group;
  final int enabledCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPressable(
      onTap: onTap,
      builder: (context, hovered, pressed) {
        final highlighted = hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: highlighted ? tokens.primaryContainer : tokens.surface,
            border: Border.all(
              color: highlighted
                  ? Color.lerp(tokens.outline, tokens.primary, 0.38)!
                  : tokens.outline.withValues(alpha: 0.58),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  overflow: TextOverflow.ellipsis,
                  style: YnekoTypography.of(context).label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                  ),
                ),
              ),
              Text('$enabledCount 可用', style: YnekoTypography.of(context).meta),
            ],
          ),
        );
      },
    );
  }
}

class _RuleSourceResultList extends StatelessWidget {
  const _RuleSourceResultList({
    required this.playback,
    required this.onCandidate,
  });

  final WatchPlaybackState playback;
  final ValueChanged<SourceCandidate>? onCandidate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final result in playback.sourceResults)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RuleSourceResultCard(
              result: result,
              selected: playback.selectedCandidate,
              onCandidate: onCandidate,
            ),
          ),
      ],
    );
  }
}

class _RuleSourceResultCard extends StatelessWidget {
  const _RuleSourceResultCard({
    required this.result,
    required this.selected,
    required this.onCandidate,
  });

  final RuleSourceSearchResult result;
  final SourceCandidate? selected;
  final ValueChanged<SourceCandidate>? onCandidate;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final matched = result.status == 'match';
    final danger = result.status == 'error';
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.62)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RuleStatusDot(status: result.status),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.ruleName,
                      overflow: TextOverflow.ellipsis,
                      style: YnekoTypography.of(context).label.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.error ??
                          (matched
                              ? '${result.candidates.length} 个候选 · ${result.elapsedMs}ms'
                              : '没有匹配候选'),
                      overflow: TextOverflow.ellipsis,
                      style: YnekoTypography.of(context).meta.copyWith(
                        color: danger ? const Color(0xFFBD2D3A) : tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.candidates.isNotEmpty) ...[
            const SizedBox(height: 7),
            for (final candidate in result.candidates)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: _PlaybackCandidateRow(
                  candidate: candidate,
                  active: candidate.detailUrl == selected?.detailUrl,
                  onTap: () => onCandidate?.call(candidate),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RuleStatusDot extends StatelessWidget {
  const _RuleStatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'match' => const Color(0xFF2DBF6F),
      'error' => const Color(0xFFFF5F87),
      'pending' => YnekoThemeTokens.of(context).muted,
      _ => YnekoThemeTokens.of(context).soft,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), spreadRadius: 3),
        ],
      ),
    );
  }
}

class _PlaybackCandidateRow extends StatelessWidget {
  const _PlaybackCandidateRow({
    required this.candidate,
    required this.active,
    required this.onTap,
  });

  final SourceCandidate candidate;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPressable(
      onTap: onTap,
      borderRadius: 7,
      builder: (context, hovered, pressed) {
        final highlighted = active || hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: active
                ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.35)
                : highlighted
                ? tokens.primaryContainer
                : tokens.surfaceLow,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: highlighted
                  ? tokens.primary.withValues(alpha: 0.62)
                  : tokens.outline.withValues(alpha: 0.50),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  candidate.title,
                  overflow: TextOverflow.ellipsis,
                  style: YnekoTypography.of(context).label.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (candidate.score != null)
                Text(
                  '${(candidate.score! * 100).round()}%',
                  style: YnekoTypography.of(context).meta,
                ),
              const SizedBox(width: 7),
              Icon(
                active
                    ? Icons.play_circle_fill_rounded
                    : Icons.play_arrow_rounded,
                size: 17,
                color: active ? tokens.primary : tokens.muted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttemptList extends StatelessWidget {
  const _AttemptList({required this.attempts});

  final List<RuleResolveAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final attempt in attempts.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                _RuleStatusDot(
                  status: attempt.status == 'success' ? 'match' : 'error',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attempt.message,
                    overflow: TextOverflow.ellipsis,
                    style: YnekoTypography.of(context).meta,
                  ),
                ),
              ],
            ),
          ),
      ],
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
    return YnekoIconActionButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 15),
      onPressed: onTap,
      tone: active
          ? YnekoActionButtonTone.ghost
          : YnekoActionButtonTone.outline,
      size: 30,
      iconSize: 15,
    );
  }
}
