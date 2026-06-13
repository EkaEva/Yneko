import 'package:flutter/material.dart';

@immutable
class YnekoThemeTokens extends ThemeExtension<YnekoThemeTokens> {
  const YnekoThemeTokens({
    required this.background,
    required this.page,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.railSurface,
    required this.ink,
    required this.muted,
    required this.soft,
    required this.outline,
    required this.primary,
    required this.primaryStrong,
    required this.primaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.danger,
    required this.shadow,
  });

  final Color background;
  final Color page;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceHigh;
  final Color railSurface;
  final Color ink;
  final Color muted;
  final Color soft;
  final Color outline;
  final Color primary;
  final Color primaryStrong;
  final Color primaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color danger;
  final List<BoxShadow> shadow;

  static const light = YnekoThemeTokens(
    background: Color(0xFFFFFFFF),
    page: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLow: Color(0xFFF6F7F8),
    surfaceHigh: Color(0xFFF1F2F3),
    railSurface: Color(0xFFF2F3F5),
    ink: Color(0xFF18191C),
    muted: Color(0xFF61666D),
    soft: Color(0xFF9499A0),
    outline: Color(0xFFE3E5E7),
    primary: Color(0xFFFF6699),
    primaryStrong: Color(0xFFFB7299),
    primaryContainer: Color(0xFFFFF0F5),
    secondary: Color(0xFF00A1D6),
    secondaryContainer: Color(0xFFE6F7FF),
    danger: Color(0xFFB3261E),
    shadow: [
      BoxShadow(
        color: Color(0x1018191C),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  );

  static const dark = YnekoThemeTokens(
    background: Color(0xFF111214),
    page: Color(0xFF18191C),
    surface: Color(0xFF1F2024),
    surfaceLow: Color(0xFF17181B),
    surfaceHigh: Color(0xFF24262B),
    railSurface: Color(0xFF17181B),
    ink: Color(0xFFF1F2F3),
    muted: Color(0xFFAEB3BB),
    soft: Color(0xFF858B95),
    outline: Color(0xFF30323A),
    primary: Color(0xFFFF6699),
    primaryStrong: Color(0xFFFF8CB1),
    primaryContainer: Color(0xFF3A2430),
    secondary: Color(0xFF32B5DD),
    secondaryContainer: Color(0xFF173241),
    danger: Color(0xFFFF7A7A),
    shadow: [
      BoxShadow(
        color: Color(0x52000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );

  static YnekoThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<YnekoThemeTokens>() ?? light;
  }

  @override
  YnekoThemeTokens copyWith({
    Color? background,
    Color? page,
    Color? surface,
    Color? surfaceLow,
    Color? surfaceHigh,
    Color? railSurface,
    Color? ink,
    Color? muted,
    Color? soft,
    Color? outline,
    Color? primary,
    Color? primaryStrong,
    Color? primaryContainer,
    Color? secondary,
    Color? secondaryContainer,
    Color? danger,
    List<BoxShadow>? shadow,
  }) {
    return YnekoThemeTokens(
      background: background ?? this.background,
      page: page ?? this.page,
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      railSurface: railSurface ?? this.railSurface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      soft: soft ?? this.soft,
      outline: outline ?? this.outline,
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  YnekoThemeTokens lerp(ThemeExtension<YnekoThemeTokens>? other, double t) {
    if (other is! YnekoThemeTokens) return this;
    return YnekoThemeTokens(
      background: Color.lerp(background, other.background, t)!,
      page: Color.lerp(page, other.page, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      railSurface: Color.lerp(railSurface, other.railSurface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: t < 0.5 ? shadow : other.shadow,
    );
  }
}

ThemeData ynekoTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark ? YnekoThemeTokens.dark : YnekoThemeTokens.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: tokens.primary,
    brightness: brightness,
    primary: tokens.primary,
    secondary: tokens.secondary,
    surface: tokens.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.page,
    fontFamily: 'Microsoft YaHei UI',
    extensions: [tokens],
    textTheme: Typography.material2021(platform: TargetPlatform.windows).black.apply(
      bodyColor: tokens.ink,
      displayColor: tokens.ink,
      fontFamily: 'Microsoft YaHei UI',
    ),
    dividerTheme: DividerThemeData(color: tokens.outline.withValues(alpha: 0.58)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.primary, width: 1.2),
      ),
    ),
  );
}
