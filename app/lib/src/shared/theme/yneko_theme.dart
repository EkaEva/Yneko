import 'package:flutter/material.dart';

@immutable
class YnekoThemeTokens extends ThemeExtension<YnekoThemeTokens> {
  const YnekoThemeTokens({
    required this.background,
    required this.page,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.surfaceVariant,
    required this.railSurface,
    required this.railIcon,
    required this.railLabel,
    required this.ink,
    required this.muted,
    required this.soft,
    required this.outline,
    required this.dividerSoft,
    required this.dividerFaint,
    required this.primary,
    required this.primaryStrong,
    required this.primaryContainer,
    required this.brandY,
    required this.brandNekoText,
    required this.secondary,
    required this.secondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.yellow,
    required this.danger,
    required this.shadow,
    required this.shadowStrong,
  });

  final Color background;
  final Color page;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceHigh;
  final Color surfaceVariant;
  final Color railSurface;
  final Color railIcon;
  final Color railLabel;
  final Color ink;
  final Color muted;
  final Color soft;
  final Color outline;
  final Color dividerSoft;
  final Color dividerFaint;
  final Color primary;
  final Color primaryStrong;
  final Color primaryContainer;
  final Color brandY;
  final Color brandNekoText;
  final Color secondary;
  final Color secondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color yellow;
  final Color danger;
  final List<BoxShadow> shadow;
  final List<BoxShadow> shadowStrong;

  static const railWidth = 64.0;
  static const topbarHeight = 72.0;
  static const pagePadding = EdgeInsets.fromLTRB(28, 24, 28, 48);
  static const fastMotion = Duration(milliseconds: 180);
  static const mediumMotion = Duration(milliseconds: 260);
  static const springCurve = Cubic(0.22, 1, 0.36, 1);
  static const fontFamily = 'Aptos';
  static const fontFallback = ['Microsoft YaHei UI', 'Segoe UI', 'sans-serif'];

  static const light = YnekoThemeTokens(
    background: Color(0xFFFFFFFF),
    page: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLow: Color(0xFFF6F7F8),
    surfaceHigh: Color(0xFFF1F2F3),
    surfaceVariant: Color(0xFFF6F7F8),
    railSurface: Color(0xFFF2F3F5),
    railIcon: Color(0xFF6C727A),
    railLabel: Color(0xFF858B95),
    ink: Color(0xFF18191C),
    muted: Color(0xFF61666D),
    soft: Color(0xFF9499A0),
    outline: Color(0xFFE3E5E7),
    dividerSoft: Color(0x94E3E5E7),
    dividerFaint: Color(0x57E3E5E7),
    primary: Color(0xFFFF6699),
    primaryStrong: Color(0xFFFB7299),
    primaryContainer: Color(0xFFFFF0F5),
    brandY: Color(0xFF18191C),
    brandNekoText: Color(0xFFFF6699),
    secondary: Color(0xFF00A1D6),
    secondaryContainer: Color(0xFFE6F7FF),
    tertiary: Color(0xFF2F8AF5),
    tertiaryContainer: Color(0xFFEDF5FF),
    yellow: Color(0xFFF7D66E),
    danger: Color(0xFFB3261E),
    shadow: [
      BoxShadow(color: Color(0x1018191C), blurRadius: 20, offset: Offset(0, 8)),
    ],
    shadowStrong: [
      BoxShadow(
        color: Color(0x1F18191C),
        blurRadius: 36,
        offset: Offset(0, 16),
      ),
    ],
  );

  static const dark = YnekoThemeTokens(
    background: Color(0xFF0B0D10),
    page: Color(0xFF15161A),
    surface: Color(0xFF1D1F24),
    surfaceLow: Color(0xFF121318),
    surfaceHigh: Color(0xFF24262D),
    surfaceVariant: Color(0xFF2D3037),
    railSurface: Color(0xFF0B0D10),
    railIcon: Color(0xFF969CA5),
    railLabel: Color(0xFF858B95),
    ink: Color(0xFFF1F2F3),
    muted: Color(0xFFAEB3BB),
    soft: Color(0xFF858B95),
    outline: Color(0xFF32343C),
    dividerSoft: Color(0xD93A3D46),
    dividerFaint: Color(0x853A3D46),
    primary: Color(0xFFFF6699),
    primaryStrong: Color(0xFFFF8CB1),
    primaryContainer: Color(0xFF3A2430),
    brandY: Color(0xFFF1F2F3),
    brandNekoText: Color(0xFFFF6699),
    secondary: Color(0xFF32B5DD),
    secondaryContainer: Color(0xFF173241),
    tertiary: Color(0xFF73B4FF),
    tertiaryContainer: Color(0xFF1D314B),
    yellow: Color(0xFFDEC46A),
    danger: Color(0xFFFF7A7A),
    shadow: [
      BoxShadow(
        color: Color(0x52000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    shadowStrong: [
      BoxShadow(
        color: Color(0x52000000),
        blurRadius: 42,
        offset: Offset(0, 18),
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
    Color? surfaceVariant,
    Color? railSurface,
    Color? railIcon,
    Color? railLabel,
    Color? ink,
    Color? muted,
    Color? soft,
    Color? outline,
    Color? dividerSoft,
    Color? dividerFaint,
    Color? primary,
    Color? primaryStrong,
    Color? primaryContainer,
    Color? brandY,
    Color? brandNekoText,
    Color? secondary,
    Color? secondaryContainer,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? yellow,
    Color? danger,
    List<BoxShadow>? shadow,
    List<BoxShadow>? shadowStrong,
  }) {
    return YnekoThemeTokens(
      background: background ?? this.background,
      page: page ?? this.page,
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      railSurface: railSurface ?? this.railSurface,
      railIcon: railIcon ?? this.railIcon,
      railLabel: railLabel ?? this.railLabel,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      soft: soft ?? this.soft,
      outline: outline ?? this.outline,
      dividerSoft: dividerSoft ?? this.dividerSoft,
      dividerFaint: dividerFaint ?? this.dividerFaint,
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      brandY: brandY ?? this.brandY,
      brandNekoText: brandNekoText ?? this.brandNekoText,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      yellow: yellow ?? this.yellow,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
      shadowStrong: shadowStrong ?? this.shadowStrong,
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
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      railSurface: Color.lerp(railSurface, other.railSurface, t)!,
      railIcon: Color.lerp(railIcon, other.railIcon, t)!,
      railLabel: Color.lerp(railLabel, other.railLabel, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      dividerSoft: Color.lerp(dividerSoft, other.dividerSoft, t)!,
      dividerFaint: Color.lerp(dividerFaint, other.dividerFaint, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      brandY: Color.lerp(brandY, other.brandY, t)!,
      brandNekoText: Color.lerp(brandNekoText, other.brandNekoText, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      )!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      tertiaryContainer: Color.lerp(
        tertiaryContainer,
        other.tertiaryContainer,
        t,
      )!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: t < 0.5 ? shadow : other.shadow,
      shadowStrong: t < 0.5 ? shadowStrong : other.shadowStrong,
    );
  }
}

ThemeData ynekoTheme(Brightness brightness) {
  final tokens = brightness == Brightness.dark
      ? YnekoThemeTokens.dark
      : YnekoThemeTokens.light;
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
    fontFamily: YnekoThemeTokens.fontFamily,
    fontFamilyFallback: YnekoThemeTokens.fontFallback,
    extensions: [tokens],
    textTheme: Typography.material2021(platform: TargetPlatform.windows).black
        .apply(
          bodyColor: tokens.ink,
          displayColor: tokens.ink,
          fontFamily: YnekoThemeTokens.fontFamily,
          fontFamilyFallback: YnekoThemeTokens.fontFallback,
        ),
    dividerTheme: DividerThemeData(
      color: tokens.outline.withValues(alpha: 0.58),
    ),
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
