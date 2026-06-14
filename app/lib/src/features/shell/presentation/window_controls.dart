import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../infrastructure/platform/window_chrome/index.dart';
import '../../../shared/theme/index.dart';

class YnekoWindowControls extends StatelessWidget {
  const YnekoWindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: _WindowControlGlyph.minimize,
          tooltip: '最小化',
          onTap: WindowChromeService.minimize,
        ),
        _MaximizeWindowButton(),
        _WindowButton(
          icon: _WindowControlGlyph.close,
          tooltip: '关闭',
          close: true,
          onTap: WindowChromeService.close,
        ),
      ],
    );
  }
}

class _MaximizeWindowButton extends StatefulWidget {
  const _MaximizeWindowButton();

  @override
  State<_MaximizeWindowButton> createState() => _MaximizeWindowButtonState();
}

class _MaximizeWindowButtonState extends State<_MaximizeWindowButton> {
  bool _maximized = false;

  @override
  Widget build(BuildContext context) {
    return _WindowButton(
      key: const ValueKey('window-maximize-button'),
      icon: _maximized
          ? _WindowControlGlyph.restore
          : _WindowControlGlyph.maximize,
      tooltip: _maximized ? '还原' : '最大化',
      onTap: () async {
        if (mounted) {
          setState(() => _maximized = !_maximized);
        }
        await WindowChromeService.toggleMaximize();
      },
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.close = false,
  });

  final _WindowControlGlyph icon;
  final String tooltip;
  final Future<void> Function() onTap;
  final bool close;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _motionDuration(context, const Duration(milliseconds: 160));
    final closeHover = widget.close && _hovered;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(),
          child: AnimatedContainer(
            key: ValueKey('window-button-${widget.tooltip}'),
            duration: motion,
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: closeHover
                  ? const Color(0xFFFF5C7A)
                  : _hovered
                  ? const Color(0xFFE3E5E7).withValues(alpha: 0.56)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _WindowControlSvgIcon(
              key: ValueKey('window-icon-${widget.icon.name}'),
              glyph: widget.icon,
              color: closeHover ? Colors.white : tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}

enum _WindowControlGlyph { minimize, maximize, restore, close }

class _WindowControlSvgIcon extends StatelessWidget {
  const _WindowControlSvgIcon({
    super.key,
    required this.glyph,
    required this.color,
  });

  final _WindowControlGlyph glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.string(
        _svg,
        width: 16,
        height: 16,
        allowDrawingOutsideViewBox: false,
      ),
    );
  }

  String get _svg {
    final stroke = _svgColor(color);
    final body = switch (glyph) {
      _WindowControlGlyph.minimize => '<path d="M5 12h14"/>',
      _WindowControlGlyph.maximize =>
        '<rect width="18" height="18" x="3" y="3" rx="2"/>',
      _WindowControlGlyph.restore =>
        '<rect width="14" height="14" x="8" y="8" rx="2" ry="2"/>'
            '<path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>',
      _WindowControlGlyph.close =>
        '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    };
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  $body
</svg>
''';
  }
}

String _svgColor(Color color) {
  final value = color.toARGB32() & 0xFFFFFFFF;
  return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

Duration _motionDuration(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
