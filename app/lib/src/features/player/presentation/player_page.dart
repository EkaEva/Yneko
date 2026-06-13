import 'package:flutter/material.dart';

import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';

class PlayerSurface extends StatefulWidget {
  const PlayerSurface({
    super.key,
    required this.subjectId,
    required this.episodeId,
    this.state = mockPlaybackState,
    this.onProgress,
  });

  final int subjectId;
  final int episodeId;
  final UiPlaybackState state;
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
    return MouseRegion(
      onEnter: (_) => setState(() => _controlsVisible = true),
      onHover: (_) => setState(() => _controlsVisible = true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111214), Color(0xFF24262B)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: Colors.white.withValues(alpha: 0.74),
                        size: 76,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _playing ? '正在播放 UI 预览' : '等待播放源',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'subject=${widget.subjectId} episode=${widget.episodeId}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.62), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 18,
                right: 20,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _controlsVisible ? 1 : 0,
                  child: Text(
                    widget.state.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 12)]),
                  ),
                ),
              ),
              if (_activePanel.isNotEmpty)
                Positioned(
                  right: _activePanel == 'volume' ? 82 : 132,
                  bottom: 78,
                  child: _PlayerPopupPanel(
                    title: _activePanel == 'speed' ? '倍速' : _activePanel == 'episodes' ? '选集' : '音量',
                    child: _activePanel == 'speed'
                        ? const _SpeedOptions()
                        : _activePanel == 'episodes'
                            ? const _EpisodeOptions()
                            : const _VolumeOptions(),
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
                    onTogglePanel: (panel) => setState(() => _activePanel = _activePanel == panel ? '' : panel),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE6000000)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
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
                      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      tooltip: playing ? '暂停' : '播放',
                      onPressed: onTogglePlay,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '$positionLabel / $durationLabel',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    _PlayerIconButton(
                      icon: Icons.subtitles_rounded,
                      tooltip: '弹幕',
                      active: true,
                      onPressed: () {},
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
                        onPressed: () {},
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
      style: TextButton.styleFrom(foregroundColor: active ? const Color(0xFFFF6699) : Colors.white),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _PlayerPopupPanel extends StatelessWidget {
  const _PlayerPopupPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF21F2024),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
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
          TextButton(onPressed: () {}, child: Text(speed)),
      ],
    );
  }
}

class _EpisodeOptions extends StatelessWidget {
  const _EpisodeOptions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 1; index <= 12; index++)
            OutlinedButton(onPressed: () {}, child: Text('$index')),
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
