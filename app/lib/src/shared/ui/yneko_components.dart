import 'package:flutter/material.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tokens.ink,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
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
                      style: TextStyle(
                        color: highlighted ? tokens.primary : tokens.ink,
                        fontSize: 16,
                        fontWeight: widget.active
                            ? FontWeight.w800
                            : FontWeight.w700,
                        letterSpacing: 0,
                        height: 1,
                        leadingDistribution: TextLeadingDistribution.even,
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
              style: TextStyle(
                color: tokens.muted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
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
    final motion = _motionDuration(context, YnekoThemeTokens.fastMotion);
    final active = widget.active || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: motion,
        offset: _hovered ? const Offset(0, -0.04) : Offset.zero,
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            foregroundColor: active ? tokens.primary : tokens.ink,
            backgroundColor: active
                ? tokens.primaryContainer
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(widget.label),
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
                    children: [
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 16,
                        child: Text(
                          widget.item.title.substring(0, 1),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
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
                                    fontWeight: FontWeight.w900,
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
                style: TextStyle(
                  color: _hovered ? tokens.primary : tokens.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.32,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.item.subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _hovered ? tokens.primary : tokens.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tokens.primary, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: tokens.muted, fontWeight: FontWeight.w600),
          ),
        ],
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
                Text(
                  candidate.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  candidate.detail,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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

Duration _motionDuration(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
