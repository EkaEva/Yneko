import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../infrastructure/platform/window_chrome/index.dart';
import '../../../shared/ui/index.dart';

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
  @override
  Widget build(BuildContext context) {
    return YnekoIconActionButton(
      buttonKey: ValueKey('window-button-${widget.tooltip}'),
      tooltip: widget.tooltip,
      onPressed: () => widget.onTap(),
      tone: YnekoActionButtonTone.chrome,
      size: 44,
      width: 44,
      height: 38,
      iconSize: 16,
      transparent: true,
      close: widget.close,
      icon: _WindowControlSvgIcon(
        key: ValueKey('window-icon-${widget.icon.name}'),
        glyph: widget.icon,
      ),
    );
  }
}

enum _WindowControlGlyph { minimize, maximize, restore, close }

class _WindowControlSvgIcon extends StatelessWidget {
  const _WindowControlSvgIcon({super.key, required this.glyph});

  final _WindowControlGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? const Color(0xFF61666D);
    return Center(
      child: SvgPicture.string(
        _svg(color),
        width: 16,
        height: 16,
        allowDrawingOutsideViewBox: false,
      ),
    );
  }

  String _svg(Color color) {
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
