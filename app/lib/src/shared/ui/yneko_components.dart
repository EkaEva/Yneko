import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets/index.dart';
import '../domain/index.dart';
import '../theme/index.dart';

class YnekoPanel extends StatelessWidget {
  const YnekoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.outline.withValues(alpha: 0.62)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: tokens.shadow,
      ),
      child: child,
    );
  }
}

class YnekoProfileAvatar extends StatelessWidget {
  const YnekoProfileAvatar({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      key: const ValueKey('yneko-profile-avatar'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: tokens.surface.withValues(alpha: 0.84),
          width: 4,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.19),
        child: SvgPicture.asset(
          YnekoAssets.logoSvg,
          key: const ValueKey('profile-avatar-logo'),
        ),
      ),
    );
  }
}

class YnekoSectionTitle extends StatelessWidget {
  const YnekoSectionTitle({
    super.key,
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: type.pageTitle),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: type.controlTitle.copyWith(color: tokens.muted),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

enum YnekoActionButtonTone { primary, outline, ghost, danger, player, chrome }

typedef YnekoPressableBuilder =
    Widget Function(BuildContext context, bool hovered, bool pressed);

class YnekoPressable extends StatefulWidget {
  const YnekoPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.borderRadius = 8,
    this.scaleOnPress = true,
    this.cursor = SystemMouseCursors.click,
  });

  final YnekoPressableBuilder builder;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool scaleOnPress;
  final MouseCursor cursor;

  @override
  State<YnekoPressable> createState() => _YnekoPressableState();
}

class _YnekoPressableState extends State<YnekoPressable> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, _hovered, _pressed);
    return MouseRegion(
      cursor: _enabled ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) {
        if (_enabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered || _pressed) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          duration: _motionDuration(context, YnekoThemeTokens.fastMotion),
          curve: Curves.easeOut,
          scale: widget.scaleOnPress && _pressed ? 0.985 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}

class YnekoActionButton extends StatefulWidget {
  const YnekoActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = YnekoActionButtonTone.outline,
    this.height = 34,
    this.minWidth = 72,
    this.borderRadius = 8,
    this.horizontalPadding = 14,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final YnekoActionButtonTone tone;
  final double height;
  final double minWidth;
  final double borderRadius;
  final double horizontalPadding;
  final TextStyle? textStyle;

  @override
  State<YnekoActionButton> createState() => _YnekoActionButtonState();
}

class _YnekoActionButtonState extends State<YnekoActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    final colors = _YnekoActionColors.resolve(
      tokens: tokens,
      tone: widget.tone,
      enabled: _enabled,
      hovered: _hovered,
      pressed: _pressed,
    );
    final type = YnekoTypography.of(context);
    final labelStyle = (widget.textStyle ?? type.label).copyWith(
      color: colors.foreground,
    );
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            IconTheme(
              data: IconThemeData(color: colors.foreground, size: 17),
              child: widget.icon!,
            ),
            const SizedBox(width: 7),
          ],
          Text(widget.label),
        ],
      ),
    );

    return TooltipVisibility(
      visible: false,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (_enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_hovered || _pressed) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: Semantics(
            button: true,
            enabled: _enabled,
            label: widget.label,
            child: AnimatedSlide(
              duration: motion,
              curve: Curves.easeOut,
              offset:
                  _hovered &&
                      _enabled &&
                      widget.tone == YnekoActionButtonTone.player
                  ? const Offset(0, -0.045)
                  : Offset.zero,
              child: AnimatedScale(
                duration: motion,
                curve: Curves.easeOut,
                scale: _pressed ? 0.985 : 1,
                child: AnimatedContainer(
                  duration: motion,
                  curve: Curves.easeOut,
                  constraints: BoxConstraints(
                    minWidth: widget.minWidth,
                    minHeight: widget.height,
                  ),
                  height: widget.height,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalPadding,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(color: colors.border),
                    boxShadow: colors.shadow,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: colors.foreground, size: 17),
                    child: DefaultTextStyle(
                      style: labelStyle.copyWith(
                        fontWeight: labelStyle.fontWeight ?? FontWeight.w800,
                        fontSize: labelStyle.fontSize ?? 13,
                        height: labelStyle.height ?? 1,
                      ),
                      child: content,
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

class YnekoIconActionButton extends StatefulWidget {
  const YnekoIconActionButton({
    super.key,
    this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.tone = YnekoActionButtonTone.outline,
    this.size = 32,
    this.width,
    this.height,
    this.iconSize = 17,
    this.transparent = false,
    this.close = false,
  });

  final Key? buttonKey;
  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;
  final YnekoActionButtonTone tone;
  final double size;
  final double? width;
  final double? height;
  final double iconSize;
  final bool transparent;
  final bool close;

  @override
  State<YnekoIconActionButton> createState() => _YnekoIconActionButtonState();
}

class _YnekoIconActionButtonState extends State<YnekoIconActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    final colors = widget.close
        ? _YnekoActionColors(
            background: (_hovered || _pressed) && _enabled
                ? const Color(0xFFFF5C7A)
                : const Color(0x00FF5C7A),
            border: const Color(0x00FF5C7A),
            foreground: (_hovered || _pressed) && _enabled
                ? Colors.white
                : tokens.muted,
          )
        : _YnekoActionColors.resolve(
            tokens: tokens,
            tone: widget.transparent ? widget.tone : widget.tone,
            enabled: _enabled,
            hovered: _hovered,
            pressed: _pressed,
          );

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (_enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_hovered || _pressed) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: Semantics(
            button: true,
            enabled: _enabled,
            label: widget.tooltip,
            child: AnimatedScale(
              duration: motion,
              curve: Curves.easeOut,
              scale: _pressed ? 0.96 : 1,
              child: AnimatedContainer(
                key: widget.buttonKey,
                duration: motion,
                curve: Curves.easeOut,
                width: widget.width ?? widget.size,
                height: widget.height ?? widget.size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.transparent
                        ? Colors.transparent
                        : colors.border,
                  ),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: colors.foreground,
                    size: widget.iconSize,
                  ),
                  child: widget.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YnekoActionColors {
  const _YnekoActionColors({
    required this.background,
    required this.border,
    required this.foreground,
    this.shadow,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final List<BoxShadow>? shadow;

  static _YnekoActionColors resolve({
    required YnekoThemeTokens tokens,
    required YnekoActionButtonTone tone,
    required bool enabled,
    required bool hovered,
    required bool pressed,
  }) {
    final danger = const Color(0xFFBD2D3A);
    final primaryBorder = Color.lerp(tokens.outline, tokens.primary, 0.38)!;
    if (!enabled) {
      final disabledForeground = tokens.muted.withValues(alpha: 0.56);
      return _YnekoActionColors(
        background: tone == YnekoActionButtonTone.ghost
            ? tokens.primaryContainer.withValues(alpha: 0)
            : tone == YnekoActionButtonTone.chrome
            ? tokens.surfaceHigh.withValues(alpha: 0)
            : tokens.surface,
        border:
            tone == YnekoActionButtonTone.ghost ||
                tone == YnekoActionButtonTone.chrome
            ? tokens.outline.withValues(alpha: 0)
            : tokens.outline.withValues(alpha: 0.48),
        foreground: disabledForeground,
      );
    }

    switch (tone) {
      case YnekoActionButtonTone.primary:
        return _YnekoActionColors(
          background: pressed
              ? tokens.primaryStrong
              : hovered
              ? Color.lerp(tokens.primary, Colors.black, 0.08)!
              : tokens.primary,
          border: Color.lerp(tokens.primary, Colors.transparent, 0.30)!,
          foreground: Colors.white,
          shadow: hovered || pressed
              ? [
                  BoxShadow(
                    color: tokens.primary.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
      case YnekoActionButtonTone.outline:
        return _YnekoActionColors(
          background: pressed
              ? tokens.primaryContainer.withValues(alpha: 0.86)
              : hovered
              ? tokens.primaryContainer
              : tokens.surface,
          border: hovered || pressed
              ? primaryBorder
              : tokens.outline.withValues(alpha: 0.66),
          foreground: hovered || pressed ? tokens.primary : tokens.ink,
        );
      case YnekoActionButtonTone.ghost:
        return _YnekoActionColors(
          background: pressed
              ? tokens.primaryContainer.withValues(alpha: 0.76)
              : hovered
              ? tokens.primaryContainer.withValues(alpha: 0.52)
              : tokens.primaryContainer.withValues(alpha: 0),
          border: tokens.primaryContainer.withValues(alpha: 0),
          foreground: hovered || pressed ? tokens.primary : tokens.muted,
        );
      case YnekoActionButtonTone.danger:
        return _YnekoActionColors(
          background: hovered || pressed
              ? Color.lerp(tokens.surfaceLow, danger, 0.10)!
              : tokens.surfaceLow,
          border: hovered || pressed
              ? Color.lerp(tokens.outline, danger, 0.46)!
              : tokens.outline.withValues(alpha: 0.56),
          foreground: danger,
        );
      case YnekoActionButtonTone.player:
        return _YnekoActionColors(
          background: pressed
              ? tokens.primaryContainer.withValues(alpha: 0.86)
              : hovered
              ? tokens.primaryContainer
              : tokens.surfaceHigh.withValues(alpha: 0.76),
          border: Color.lerp(tokens.outline, Colors.transparent, 0.56)!,
          foreground: tokens.primaryStrong,
        );
      case YnekoActionButtonTone.chrome:
        return _YnekoActionColors(
          background: pressed
              ? Color.lerp(tokens.surfaceHigh, tokens.ink, 0.04)!
              : hovered
              ? tokens.surfaceHigh
              : tokens.surfaceHigh.withValues(alpha: 0),
          border: tokens.surfaceHigh.withValues(alpha: 0),
          foreground: hovered || pressed ? tokens.ink : tokens.muted,
        );
    }
  }
}

class YnekoHoverMenuItem<T> {
  const YnekoHoverMenuItem({required this.value, required this.label});

  final T value;
  final String label;
}

class YnekoHoverMenu<T> extends StatefulWidget {
  const YnekoHoverMenu({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.height = 38,
    this.panelMaxWidth = 320,
    this.triggerKey,
    this.optionAlignment = Alignment.centerLeft,
    this.optionMinWidth = 160,
    this.triggerFontSize = 13,
    this.optionFontSize = 13,
    this.leadingPadding = 14,
    this.trailingPadding = 10,
    this.showOpenShadow = true,
    this.centerTriggerContent = false,
  });

  final List<YnekoHoverMenuItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final double panelMaxWidth;
  final Key? triggerKey;
  final AlignmentGeometry optionAlignment;
  final double optionMinWidth;
  final double triggerFontSize;
  final double optionFontSize;
  final double leadingPadding;
  final double trailingPadding;
  final bool showOpenShadow;
  final bool centerTriggerContent;

  @override
  State<YnekoHoverMenu<T>> createState() => _YnekoHoverMenuState<T>();
}

class _YnekoHoverMenuState<T> extends State<YnekoHoverMenu<T>> {
  final Object _tapRegionGroup = Object();
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
  Timer? _closeTimer;
  bool _open = false;
  bool _hovered = false;
  bool _panelHovered = false;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _show() {
    _closeTimer?.cancel();
    if (_open) return;
    setState(() => _open = true);
    _overlayController.show();
  }

  void _hide() {
    _closeTimer?.cancel();
    if (!_open) return;
    setState(() {
      _open = false;
      _panelHovered = false;
    });
    _overlayController.hide();
  }

  void _scheduleHide() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 90), () {
      if (!mounted || _hovered || _panelHovered) return;
      _hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    final selected = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => widget.items.isEmpty
          ? YnekoHoverMenuItem(value: widget.value, label: '')
          : widget.items.first,
    );
    final active = _open || _hovered || _panelHovered;
    final border = active
        ? Color.lerp(tokens.outline, tokens.primary, 0.36)!
        : tokens.outline.withValues(alpha: 0.64);
    final background = active ? tokens.primaryContainer : tokens.surface;

    final trigger = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _show();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _scheduleHide();
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _open ? _hide() : _show(),
          child: AnimatedContainer(
            key:
                widget.triggerKey ??
                const ValueKey('rule-repository-subscription-trigger'),
            duration: motion,
            height: widget.height,
            padding: EdgeInsets.only(
              left: widget.leadingPadding,
              right: widget.trailingPadding,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
              boxShadow: _open && widget.showOpenShadow
                  ? [
                      BoxShadow(
                        color: tokens.primary.withValues(alpha: 0.12),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: widget.centerTriggerContent
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _YnekoHoverMenuTriggerLabel(
                          label: selected.label,
                          active: active,
                          fontSize: widget.triggerFontSize,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _YnekoHoverMenuChevron(active: active),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _YnekoHoverMenuTriggerLabel(
                          label: selected.label,
                          active: active,
                          fontSize: widget.triggerFontSize,
                        ),
                      ),
                      _YnekoHoverMenuChevron(active: active),
                    ],
                  ),
          ),
        ),
      ),
    );

    final panel = TapRegion(
      groupId: _tapRegionGroup,
      child: CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8),
        showWhenUnlinked: false,
        child: UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() {
              _closeTimer?.cancel();
              _panelHovered = true;
            }),
            onExit: (_) {
              setState(() => _panelHovered = false);
              _scheduleHide();
            },
            child: AnimatedSlide(
              duration: motion,
              curve: Curves.easeOut,
              offset: _open ? Offset.zero : const Offset(0, -0.08),
              child: ConstrainedBox(
                key: const ValueKey('yneko-hover-menu-panel'),
                constraints: BoxConstraints(
                  minWidth: widget.optionMinWidth,
                  maxWidth: widget.panelMaxWidth,
                ),
                child: IntrinsicWidth(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.outline.withValues(alpha: 0.82),
                      ),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in widget.items)
                            _YnekoHoverMenuOption<T>(
                              item: item,
                              active: item.value == widget.value,
                              alignment: widget.optionAlignment,
                              minWidth: widget.optionMinWidth,
                              fontSize: widget.optionFontSize,
                              onTap: () {
                                widget.onChanged(item.value);
                                _hide();
                              },
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
      ),
    );

    return TapRegion(
      groupId: _tapRegionGroup,
      onTapOutside: (_) => _hide(),
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => panel,
        child: trigger,
      ),
    );
  }
}

class _YnekoHoverMenuTriggerLabel extends StatelessWidget {
  const _YnekoHoverMenuTriggerLabel({
    required this.label,
    required this.active,
    required this.fontSize,
  });

  final String label;
  final bool active;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: YnekoTypography.of(context).label.copyWith(
        color: active ? tokens.primary : tokens.ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _YnekoHoverMenuChevron extends StatelessWidget {
  const _YnekoHoverMenuChevron({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return AnimatedRotation(
      duration: _motionDuration(context, YnekoThemeTokens.fastMotion),
      turns: active ? -0.25 : 0.25,
      child: Icon(
        Icons.chevron_right_rounded,
        color: active ? tokens.primary : tokens.muted,
        size: 18,
      ),
    );
  }
}

class _YnekoHoverMenuOption<T> extends StatefulWidget {
  const _YnekoHoverMenuOption({
    required this.item,
    required this.active,
    required this.alignment,
    required this.minWidth,
    required this.fontSize,
    required this.onTap,
  });

  final YnekoHoverMenuItem<T> item;
  final bool active;
  final AlignmentGeometry alignment;
  final double minWidth;
  final double fontSize;
  final VoidCallback onTap;

  @override
  State<_YnekoHoverMenuOption<T>> createState() =>
      _YnekoHoverMenuOptionState<T>();
}

class _YnekoHoverMenuOptionState<T> extends State<_YnekoHoverMenuOption<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _motionDuration(context, const Duration(milliseconds: 160));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          key: ValueKey('yneko-hover-menu-option-${widget.item.label}'),
          duration: motion,
          constraints: BoxConstraints(minHeight: 42, minWidth: widget.minWidth),
          alignment: widget.alignment,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _hovered ? tokens.primaryContainer : tokens.surface,
          ),
          child: Text(
            widget.item.label,
            overflow: TextOverflow.ellipsis,
            style: type.label.copyWith(
              color: _hovered
                  ? tokens.primary
                  : widget.active
                  ? tokens.ink
                  : tokens.muted,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class YnekoSegmentedTabs extends StatelessWidget {
  const YnekoSegmentedTabs({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: YnekoThemeTokens.topbarHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < tabs.length; index++)
            _YnekoTabButton(
              label: tabs[index],
              active: index == activeIndex,
              onTap: () => onChanged(index),
            ),
        ],
      ),
    );
  }
}

class _YnekoTabButton extends StatefulWidget {
  const _YnekoTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_YnekoTabButton> createState() => _YnekoTabButtonState();
}

class _YnekoTabButtonState extends State<_YnekoTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    final highlighted = widget.active || _hovered;
    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox(
            width: _tabWidth(widget.label),
            height: YnekoThemeTokens.topbarHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(0, -0.05),
                    child: AnimatedDefaultTextStyle(
                      duration: motion,
                      curve: Curves.easeOut,
                      style: type.topTab.copyWith(
                        color: highlighted ? tokens.primary : tokens.ink,
                        fontWeight: widget.active
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                      child: Text(widget.label),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 10,
                  child: AnimatedScale(
                    duration: motion,
                    curve: Curves.easeOut,
                    scale: widget.active ? 1 : 0.35,
                    child: AnimatedOpacity(
                      duration: motion,
                      opacity: widget.active ? 1 : 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: tokens.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _tabWidth(String label) {
    return label.length >= 3 ? 82 : 66;
  }
}

class YnekoFilterChips extends StatelessWidget {
  const YnekoFilterChips({
    super.key,
    required this.label,
    required this.items,
    this.activeIndex = 0,
  });

  final String label;
  final List<String> items;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          height: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: type.label.copyWith(color: tokens.muted, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              for (var index = 0; index < items.length; index++)
                _YnekoFilterChip(
                  label: items[index],
                  active: index == activeIndex,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _YnekoFilterChip extends StatefulWidget {
  const _YnekoFilterChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  State<_YnekoFilterChip> createState() => _YnekoFilterChipState();
}

class _YnekoFilterChipState extends State<_YnekoFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    final active = widget.active || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: motion,
        offset: _hovered ? const Offset(0, -0.04) : Offset.zero,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: AnimatedContainer(
            duration: motion,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? tokens.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.label,
              style: type.controlTitle.copyWith(
                color: active ? tokens.primary : tokens.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimePosterCard extends StatefulWidget {
  const AnimePosterCard({super.key, required this.item, required this.onTap});

  final UiAnimeCard item;
  final VoidCallback onTap;

  @override
  State<AnimePosterCard> createState() => _AnimePosterCardState();
}

class _AnimePosterCardState extends State<AnimePosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _motionDuration(context, YnekoThemeTokens.mediumMotion);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSlide(
          duration: motion,
          curve: YnekoThemeTokens.springCurve,
          offset: _hovered ? const Offset(0, -0.014) : Offset.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: AnimatedContainer(
                  duration: motion,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.item.coverColor,
                        Color.lerp(
                          widget.item.coverColor,
                          tokens.surfaceHigh,
                          0.34,
                        )!,
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.item.coverUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.item.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      if (widget.item.coverUrl != null)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 16,
                        child: Visibility(
                          visible: widget.item.coverUrl == null,
                          child: Text(
                            widget.item.title.characters.first,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xB8141216),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.item.score,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.item.title,
                overflow: TextOverflow.ellipsis,
                style: type.cardTitle.copyWith(
                  color: _hovered ? tokens.primary : tokens.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.item.subtitle,
                overflow: TextOverflow.ellipsis,
                style: type.meta.copyWith(
                  color: _hovered ? tokens.primary : tokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YnekoEmptyState extends StatelessWidget {
  const YnekoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tokens.primary, size: 38),
          const SizedBox(height: 12),
          Text(title, style: type.cardTitle),
          const SizedBox(height: 4),
          Text(description, style: type.meta.copyWith(color: tokens.muted)),
        ],
      ),
    );
  }
}

class YnekoLoadingState extends StatelessWidget {
  const YnekoLoadingState({
    super.key,
    required this.title,
    this.size = 96,
    this.minHeight = 360,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
  });

  final String title;
  final double size;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Semantics(
      label: title,
      liveRegion: true,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: padding,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YnekoRingLoader(size: size),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: type.controlTitle.copyWith(
                color: tokens.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SourceCandidateRow extends StatelessWidget {
  const SourceCandidateRow({
    super.key,
    required this.candidate,
    this.active = false,
  });

  final UiSourceCandidate candidate;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final motion = _motionDuration(context, const Duration(milliseconds: 160));
    return AnimatedContainer(
      duration: motion,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active || candidate.matched
            ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.36)
            : tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active || candidate.matched
              ? Color.lerp(tokens.primary, tokens.outline, 0.58)!
              : tokens.outline.withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(candidate.name, style: type.controlTitle),
                const SizedBox(height: 3),
                Text(
                  candidate.detail,
                  overflow: TextOverflow.ellipsis,
                  style: type.label.copyWith(color: tokens.muted),
                ),
              ],
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: candidate.matched ? const Color(0xFF2DBF6F) : tokens.soft,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (candidate.matched
                              ? const Color(0xFF2DBF6F)
                              : tokens.soft)
                          .withValues(alpha: 0.18),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class YnekoRingLoader extends StatefulWidget {
  const YnekoRingLoader({super.key, this.size = 58});

  final double size;

  @override
  State<YnekoRingLoader> createState() => _YnekoRingLoaderState();
}

class _YnekoRingLoaderState extends State<YnekoRingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _YnekoRingLoaderPainter(
            progress: MediaQuery.disableAnimationsOf(context)
                ? 0
                : _controller.value,
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            colors: dark
                ? const [
                    Color(0xFFE7E9EE),
                    Color(0xFFA7ABB3),
                    Color(0xFFC0C4CC),
                    Color(0xFFE7E9EE),
                  ]
                : const [
                    Color(0xFF000000),
                    Color(0xFF7E7E7E),
                    Color(0xFF686868),
                    Color(0xFF000000),
                  ],
          ),
        ),
      ),
    );
  }
}

class _YnekoRingLoaderPainter extends CustomPainter {
  const _YnekoRingLoaderPainter({
    required this.progress,
    required this.reduceMotion,
    required this.colors,
  });

  final double progress;
  final bool reduceMotion;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 240;
    final translate = Offset(
      (size.width - 240 * scale) / 2,
      (size.height - 240 * scale) / 2,
    );
    const specs = [
      _YnekoRingSpec(
        center: Offset(120, 120),
        radius: 105,
        circumference: 660,
        frames: _ringAFrames,
      ),
      _YnekoRingSpec(
        center: Offset(120, 120),
        radius: 35,
        circumference: 220,
        frames: _ringBFrames,
      ),
      _YnekoRingSpec(
        center: Offset(85, 120),
        radius: 70,
        circumference: 440,
        frames: _ringCFrames,
      ),
      _YnekoRingSpec(
        center: Offset(155, 120),
        radius: 70,
        circumference: 440,
        frames: _ringDFrames,
      ),
    ];

    for (var index = 0; index < specs.length; index++) {
      final spec = specs[index];
      final state = reduceMotion
          ? const _YnekoRingFrame(0, 1, 0, 20)
          : _YnekoRingFrame.lerpFor(progress, spec.frames);
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = state.strokeWidth * scale
        ..strokeCap = StrokeCap.round;
      final center = translate + spec.center * scale;
      final radius = spec.radius * scale;

      if (reduceMotion) {
        canvas.drawCircle(center, radius, paint);
        continue;
      }

      if (state.visibleLength <= 0.2) {
        continue;
      }

      final visible = (state.visibleLength / spec.circumference).clamp(0, 1);
      final sweep = visible * 2 * 3.141592653589793;
      final start =
          -(state.dashOffset / spec.circumference) * 2 * 3.141592653589793;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _YnekoRingLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.reduceMotion != reduceMotion ||
        oldDelegate.colors != colors;
  }
}

class _YnekoRingSpec {
  const _YnekoRingSpec({
    required this.center,
    required this.radius,
    required this.circumference,
    required this.frames,
  });

  final Offset center;
  final double radius;
  final double circumference;
  final List<_YnekoRingFrame> frames;
}

class _YnekoRingFrame {
  const _YnekoRingFrame(
    this.stop,
    this.visibleLength,
    this.dashOffset,
    this.strokeWidth,
  );

  final double stop;
  final double visibleLength;
  final double dashOffset;
  final double strokeWidth;

  static _YnekoRingFrame lerpFor(
    double progress,
    List<_YnekoRingFrame> frames,
  ) {
    for (var index = 1; index < frames.length; index++) {
      final previous = frames[index - 1];
      final next = frames[index];
      if (progress <= next.stop) {
        final span = next.stop - previous.stop;
        final t = span <= 0 ? 0.0 : (progress - previous.stop) / span;
        return _YnekoRingFrame(
          progress,
          _lerpDouble(previous.visibleLength, next.visibleLength, t),
          _lerpDouble(previous.dashOffset, next.dashOffset, t),
          _lerpDouble(previous.strokeWidth, next.strokeWidth, t),
        );
      }
    }
    return frames.last;
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

const _ringAFrames = [
  _YnekoRingFrame(0, 0, -330, 20),
  _YnekoRingFrame(0.04, 0, -330, 20),
  _YnekoRingFrame(0.12, 60, -335, 30),
  _YnekoRingFrame(0.32, 60, -595, 30),
  _YnekoRingFrame(0.40, 0, -660, 20),
  _YnekoRingFrame(0.54, 0, -660, 20),
  _YnekoRingFrame(0.62, 60, -665, 30),
  _YnekoRingFrame(0.82, 60, -925, 30),
  _YnekoRingFrame(0.90, 0, -990, 20),
  _YnekoRingFrame(1, 0, -990, 20),
];

const _ringBFrames = [
  _YnekoRingFrame(0, 0, -110, 20),
  _YnekoRingFrame(0.12, 0, -110, 20),
  _YnekoRingFrame(0.20, 20, -115, 30),
  _YnekoRingFrame(0.40, 20, -195, 30),
  _YnekoRingFrame(0.48, 0, -220, 20),
  _YnekoRingFrame(0.62, 0, -220, 20),
  _YnekoRingFrame(0.70, 20, -225, 30),
  _YnekoRingFrame(0.90, 20, -305, 30),
  _YnekoRingFrame(0.98, 0, -330, 20),
  _YnekoRingFrame(1, 0, -330, 20),
];

const _ringCFrames = [
  _YnekoRingFrame(0, 0, 0, 20),
  _YnekoRingFrame(0.08, 40, -5, 30),
  _YnekoRingFrame(0.28, 40, -175, 30),
  _YnekoRingFrame(0.36, 0, -220, 20),
  _YnekoRingFrame(0.58, 0, -220, 20),
  _YnekoRingFrame(0.66, 40, -225, 30),
  _YnekoRingFrame(0.86, 40, -395, 30),
  _YnekoRingFrame(0.94, 0, -440, 20),
  _YnekoRingFrame(1, 0, -440, 20),
];

const _ringDFrames = [
  _YnekoRingFrame(0, 0, 0, 20),
  _YnekoRingFrame(0.08, 0, 0, 20),
  _YnekoRingFrame(0.16, 40, -5, 30),
  _YnekoRingFrame(0.36, 40, -175, 30),
  _YnekoRingFrame(0.44, 0, -220, 20),
  _YnekoRingFrame(0.50, 0, -220, 20),
  _YnekoRingFrame(0.58, 40, -225, 30),
  _YnekoRingFrame(0.78, 40, -395, 30),
  _YnekoRingFrame(0.86, 0, -440, 20),
  _YnekoRingFrame(1, 0, -440, 20),
];

Duration _motionDuration(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
