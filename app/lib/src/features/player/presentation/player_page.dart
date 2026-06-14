import 'package:flutter/material.dart';

import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';

class PlayerSurface extends StatefulWidget {
  const PlayerSurface({
    super.key,
    required this.subjectId,
    required this.episodeId,
    this.state = mockPlaybackState,
    this.title,
    this.episodes = const [],
    this.onPreviousEpisode,
    this.onNextEpisode,
    this.onSelectEpisode,
    this.hasPreviousEpisode = true,
    this.hasNextEpisode = true,
    this.onProgress,
  });

  final int subjectId;
  final int episodeId;
  final UiPlaybackState state;
  final String? title;
  final List<UiEpisodeItem> episodes;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;
  final ValueChanged<UiEpisodeItem>? onSelectEpisode;
  final bool hasPreviousEpisode;
  final bool hasNextEpisode;
  final ValueChanged<double>? onProgress;

  @override
  State<PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends State<PlayerSurface> {
  bool _playing = false;
  bool _controlsVisible = true;
  String _activePanel = '';

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    final title = widget.title ?? widget.state.title;
    return MouseRegion(
      onEnter: (_) => setState(() => _controlsVisible = true),
      onHover: (_) => setState(() => _controlsVisible = true),
      onExit: (_) => setState(() => _controlsVisible = false),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _playing = !_playing),
                      child: Icon(
                        _playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: Colors.white.withValues(alpha: 0.74),
                        size: 88,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _playing ? '正在播放 UI 预览' : '等待播放源',
                      style: type.sectionTitle.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'subject=${widget.subjectId} episode=${widget.episodeId}',
                      style: type.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              right: 14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _controlsVisible ? 1 : 0,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '返回',
                      onPressed: () {},
                      color: Colors.white.withValues(alpha: 0.78),
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: type.controlTitle.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                          fontSize: 17,
                          shadows: const [Shadow(blurRadius: 12)],
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
                      activeEpisodeId: widget.episodeId,
                      onSelect: widget.onSelectEpisode,
                    ),
                    'volume' => const _VolumeOptions(),
                    'settings' => const _SettingsOptions(),
                    _ => const _DanmakuOptions(),
                  },
                ),
              ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _controlsVisible ? 1 : 0,
                  child: _CenterControls(
                    playing: _playing,
                    hasPrevious: widget.hasPreviousEpisode,
                    hasNext: widget.hasNextEpisode,
                    onPrevious: widget.onPreviousEpisode,
                    onTogglePlay: () => setState(() => _playing = !_playing),
                    onNext: widget.onNextEpisode,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              left: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _controlsVisible ? 1 : 0,
                child: _ControlBar(
                  playing: _playing,
                  progress: widget.state.progress,
                  positionLabel: widget.state.positionLabel,
                  durationLabel: widget.state.durationLabel,
                  activePanel: _activePanel,
                  onTogglePlay: () => setState(() => _playing = !_playing),
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

  double _panelRight() {
    return switch (_activePanel) {
      'volume' => 82,
      'settings' => 44,
      'episodes' => 142,
      _ => 132,
    };
  }
}

class _CenterControls extends StatelessWidget {
  const _CenterControls({
    required this.playing,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onTogglePlay,
    required this.onNext,
  });

  final bool playing;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback onTogglePlay;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingPlayerButton(
            icon: Icons.skip_previous_rounded,
            tooltip: '上一集',
            onPressed: hasPrevious ? onPrevious : null,
          ),
          const SizedBox(width: 18),
          _FloatingPlayerButton(
            large: true,
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            tooltip: playing ? '暂停' : '播放',
            onPressed: onTogglePlay,
          ),
          const SizedBox(width: 18),
          _FloatingPlayerButton(
            icon: Icons.skip_next_rounded,
            tooltip: '下一集',
            onPressed: hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _FloatingPlayerButton extends StatelessWidget {
  const _FloatingPlayerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.large = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.42),
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
          minimumSize: Size.square(large ? 58 : 48),
        ),
        icon: Icon(icon, size: large ? 36 : 30),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.playing,
    required this.progress,
    required this.positionLabel,
    required this.durationLabel,
    required this.activePanel,
    required this.onTogglePlay,
    required this.onTogglePanel,
  });

  final bool playing;
  final double progress;
  final String positionLabel;
  final String durationLabel;
  final String activePanel;
  final VoidCallback onTogglePlay;
  final ValueChanged<String> onTogglePanel;

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE6000000)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 58, 18, 13),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    color: const Color(0xFFFF6699),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PlayerIconButton(
                      icon: playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      tooltip: playing ? '暂停' : '播放',
                      onPressed: onTogglePlay,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '$positionLabel / $durationLabel',
                        overflow: TextOverflow.ellipsis,
                        style: type.label.copyWith(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    _PlayerIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      tooltip: '弹幕',
                      active: activePanel == 'danmaku',
                      onPressed: () => onTogglePanel('danmaku'),
                    ),
                    if (!compact)
                      _PlayerTextButton(
                        label: '倍速',
                        active: activePanel == 'speed',
                        onPressed: () => onTogglePanel('speed'),
                      ),
                    if (!compact)
                      _PlayerTextButton(
                        label: '选集',
                        active: activePanel == 'episodes',
                        onPressed: () => onTogglePanel('episodes'),
                      ),
                    _PlayerIconButton(
                      icon: Icons.volume_up_rounded,
                      tooltip: '音量',
                      active: activePanel == 'volume',
                      onPressed: () => onTogglePanel('volume'),
                    ),
                    if (!compact)
                      _PlayerIconButton(
                        icon: Icons.settings_rounded,
                        tooltip: '设置',
                        active: activePanel == 'settings',
                        onPressed: () => onTogglePanel('settings'),
                      ),
                    _PlayerIconButton(
                      icon: Icons.fullscreen_rounded,
                      tooltip: '全屏',
                      onPressed: () {},
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

class _PlayerIconButton extends StatelessWidget {
  const _PlayerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        color: active ? const Color(0xFFFF6699) : Colors.white,
        icon: Icon(icon),
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

  final List<UiEpisodeItem> episodes;
  final int activeEpisodeId;
  final ValueChanged<UiEpisodeItem>? onSelect;

  @override
  Widget build(BuildContext context) {
    final items = episodes.isEmpty
        ? List.generate(
            12,
            (index) => UiEpisodeItem(
              id: index + 1,
              order: index + 1,
              title: '占位',
              progress: 0,
            ),
          )
        : episodes;
    return SizedBox(
      width: 260,
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final episode in items)
            SizedBox(
              width: 44,
              height: 30,
              child: _PanelChoice(
                label: '${episode.order}',
                active: episode.id == activeEpisodeId,
                onTap: () => onSelect?.call(episode),
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
