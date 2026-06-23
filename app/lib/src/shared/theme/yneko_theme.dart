import 'package:flutter/material.dart';

import 'yneko_color_scheme.dart';

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
  static const fontFamily = 'MiSansYneko';
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

@immutable
class YnekoTypography {
  const YnekoTypography._(this.tokens);

  final YnekoThemeTokens tokens;

  static YnekoTypography of(BuildContext context) {
    return YnekoTypography._(YnekoThemeTokens.of(context));
  }

  static const brand = TextStyle(
    fontFamily: YnekoThemeTokens.fontFamily,
    fontFamilyFallback: YnekoThemeTokens.fontFallback,
    fontSize: 25,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.08,
    leadingDistribution: TextLeadingDistribution.even,
  );

  TextStyle get topTab => _style(
    color: tokens.ink,
    size: 16,
    weight: FontWeight.w600,
    height: 1.22,
  );

  TextStyle get pageTitle => _style(
    color: tokens.ink,
    size: 28,
    weight: FontWeight.w700,
    height: 1.18,
  );

  TextStyle get sectionTitle =>
      _style(color: tokens.ink, size: 22, weight: FontWeight.w700, height: 1.2);

  TextStyle get cardTitle => _style(
    color: tokens.ink,
    size: 17,
    weight: FontWeight.w700,
    height: 1.32,
  );

  TextStyle get controlTitle =>
      _style(color: tokens.ink, size: 15, weight: FontWeight.w600, height: 1.3);

  TextStyle get body => _style(
    color: tokens.ink,
    size: 14,
    weight: FontWeight.w400,
    height: 1.45,
  );

  TextStyle get meta => _style(
    color: tokens.muted,
    size: 13,
    weight: FontWeight.w400,
    height: 1.35,
  );

  TextStyle get label => _style(
    color: tokens.muted,
    size: 12,
    weight: FontWeight.w600,
    height: 1.2,
  );

  TextStyle _style({
    required Color color,
    required double size,
    required FontWeight weight,
    required double height,
  }) {
    return TextStyle(
      fontFamily: YnekoThemeTokens.fontFamily,
      fontFamilyFallback: YnekoThemeTokens.fontFallback,
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }
}

ThemeData ynekoTheme(
  Brightness brightness, {
  YnekoColorScheme colorScheme = YnekoColorScheme.yneko,
}) {
  final tokens = _tokensFor(brightness, colorScheme);
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
    textTheme: _ynekoTextTheme(tokens),
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

YnekoThemeTokens _tokensFor(
  Brightness brightness,
  YnekoColorScheme colorScheme,
) {
  final base = brightness == Brightness.dark
      ? YnekoThemeTokens.dark
      : YnekoThemeTokens.light;
  if (colorScheme == YnekoColorScheme.yneko) return base;
  return brightness == Brightness.dark
      ? _darkSchemeTokens(base, colorScheme)
      : _lightSchemeTokens(base, colorScheme);
}

YnekoThemeTokens _lightSchemeTokens(
  YnekoThemeTokens base,
  YnekoColorScheme colorScheme,
) {
  return switch (colorScheme) {
    YnekoColorScheme.yneko => base,
    YnekoColorScheme.blue => base.copyWith(
      background: const Color(0xFFF4F9FF),
      page: const Color(0xFFF8FBFF),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFEEF6FF),
      surfaceHigh: const Color(0xFFE6F1FF),
      surfaceVariant: const Color(0xFFEDF5FF),
      railSurface: const Color(0xFFEDF6FF),
      railIcon: const Color(0xFF5F7894),
      railLabel: const Color(0xFF7E94AB),
      outline: const Color(0xFFD7E5F4),
      dividerSoft: const Color(0xA8C2D6EB),
      dividerFaint: const Color(0x61C2D6EB),
      primary: const Color(0xFF2F8AF5),
      primaryStrong: const Color(0xFF1677E8),
      primaryContainer: const Color(0xFFEDF5FF),
      brandNekoText: const Color(0xFF2F8AF5),
      secondary: const Color(0xFF00A1D6),
      secondaryContainer: const Color(0xFFE6F7FF),
      shadow: [
        const BoxShadow(
          color: Color(0x142F8AF5),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x212F8AF5),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.gray => base.copyWith(
      background: const Color(0xFFF6F7F8),
      page: const Color(0xFFFBFBFC),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFF1F2F3),
      surfaceHigh: const Color(0xFFE8EAED),
      surfaceVariant: const Color(0xFFF1F2F3),
      railSurface: const Color(0xFFEDEFF2),
      railIcon: const Color(0xFF6C727A),
      railLabel: const Color(0xFF858B95),
      outline: const Color(0xFFDCE0E5),
      dividerSoft: const Color(0xB8CFD4DB),
      dividerFaint: const Color(0x6BCFD4DB),
      primary: const Color(0xFF6C727A),
      primaryStrong: const Color(0xFF18191C),
      primaryContainer: const Color(0xFFF1F2F3),
      brandNekoText: const Color(0xFF61666D),
      secondary: const Color(0xFF00A1D6),
      secondaryContainer: const Color(0xFFE6F7FF),
      shadow: [
        const BoxShadow(
          color: Color(0x1218191C),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x1F18191C),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.mint => base.copyWith(
      background: const Color(0xFFF4FBF8),
      page: const Color(0xFFFBFFFD),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFEDF9F5),
      surfaceHigh: const Color(0xFFE2F3EE),
      surfaceVariant: const Color(0xFFEDF9F5),
      railSurface: const Color(0xFFEAF7F2),
      railIcon: const Color(0xFF5B8176),
      railLabel: const Color(0xFF7F9C93),
      outline: const Color(0xFFD4E8E1),
      dividerSoft: const Color(0xADBEDBD2),
      dividerFaint: const Color(0x66BEDBD2),
      primary: const Color(0xFF16A085),
      primaryStrong: const Color(0xFF0E806C),
      primaryContainer: const Color(0xFFE9F8F3),
      brandNekoText: const Color(0xFF16A085),
      secondary: const Color(0xFF2BA7BD),
      secondaryContainer: const Color(0xFFE8F7FA),
      shadow: [
        const BoxShadow(
          color: Color(0x1416A085),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x2116A085),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.spruce => base.copyWith(
      background: const Color(0xFFF3FAFB),
      page: const Color(0xFFF9FDFD),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFEDF8F8),
      surfaceHigh: const Color(0xFFE2F1F2),
      surfaceVariant: const Color(0xFFEEF8F8),
      railSurface: const Color(0xFFEAF5F6),
      railIcon: const Color(0xFF587B80),
      railLabel: const Color(0xFF7B989D),
      outline: const Color(0xFFD1E5E7),
      dividerSoft: const Color(0xADBCD8DC),
      dividerFaint: const Color(0x66BCD8DC),
      primary: const Color(0xFF0F8B8D),
      primaryStrong: const Color(0xFF087173),
      primaryContainer: const Color(0xFFE9F7F7),
      brandNekoText: const Color(0xFF0F8B8D),
      secondary: const Color(0xFF3D87C7),
      secondaryContainer: const Color(0xFFEEF6FF),
      shadow: [
        const BoxShadow(
          color: Color(0x140F8B8D),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x210F8B8D),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.lavender => base.copyWith(
      background: const Color(0xFFF8F7FF),
      page: const Color(0xFFFCFBFF),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFF2F0FF),
      surfaceHigh: const Color(0xFFE9E6FB),
      surfaceVariant: const Color(0xFFF2F0FF),
      railSurface: const Color(0xFFF0EFFB),
      railIcon: const Color(0xFF746E96),
      railLabel: const Color(0xFF918CAE),
      outline: const Color(0xFFDEDAF1),
      dividerSoft: const Color(0xADCEC8E8),
      dividerFaint: const Color(0x66CEC8E8),
      primary: const Color(0xFF7C6BD8),
      primaryStrong: const Color(0xFF6655C7),
      primaryContainer: const Color(0xFFF0EEFF),
      brandNekoText: const Color(0xFF7C6BD8),
      secondary: const Color(0xFF4DA3C7),
      secondaryContainer: const Color(0xFFEAF7FB),
      shadow: [
        const BoxShadow(
          color: Color(0x147C6BD8),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x217C6BD8),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.apricot => base.copyWith(
      background: const Color(0xFFFFF9F2),
      page: const Color(0xFFFFFDF9),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFFFF4EB),
      surfaceHigh: const Color(0xFFFEE9D8),
      surfaceVariant: const Color(0xFFFFF4EB),
      railSurface: const Color(0xFFFFF1E6),
      railIcon: const Color(0xFF8B7464),
      railLabel: const Color(0xFFA28C7D),
      outline: const Color(0xFFEAD7C8),
      dividerSoft: const Color(0xADE2CBB9),
      dividerFaint: const Color(0x66E2CBB9),
      primary: const Color(0xFFD9824B),
      primaryStrong: const Color(0xFFBD6833),
      primaryContainer: const Color(0xFFFFF2E8),
      brandNekoText: const Color(0xFFD9824B),
      secondary: const Color(0xFF4AA3A1),
      secondaryContainer: const Color(0xFFEAF7F5),
      shadow: [
        const BoxShadow(
          color: Color(0x14D9824B),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x21D9824B),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.coral => base.copyWith(
      background: const Color(0xFFFFF7F5),
      page: const Color(0xFFFFFCFA),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFFFF0EC),
      surfaceHigh: const Color(0xFFFFE4DD),
      surfaceVariant: const Color(0xFFFFF0EC),
      railSurface: const Color(0xFFFFEEE9),
      railIcon: const Color(0xFF8C6A64),
      railLabel: const Color(0xFFA48983),
      outline: const Color(0xFFEBD0C9),
      dividerSoft: const Color(0xADDDBDB5),
      dividerFaint: const Color(0x66DDBDB5),
      primary: const Color(0xFFE56B5D),
      primaryStrong: const Color(0xFFC94F42),
      primaryContainer: const Color(0xFFFFEFEA),
      brandNekoText: const Color(0xFFE56B5D),
      secondary: const Color(0xFF4AA3A1),
      secondaryContainer: const Color(0xFFEAF7F5),
      shadow: [
        const BoxShadow(
          color: Color(0x14E56B5D),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x21E56B5D),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.amber => base.copyWith(
      background: const Color(0xFFFFFAEF),
      page: const Color(0xFFFFFDF8),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFFFF7E6),
      surfaceHigh: const Color(0xFFFCECC9),
      surfaceVariant: const Color(0xFFFFF7E6),
      railSurface: const Color(0xFFFFF3DC),
      railIcon: const Color(0xFF857056),
      railLabel: const Color(0xFF9F8A6E),
      outline: const Color(0xFFE8D6B5),
      dividerSoft: const Color(0xADDCC79F),
      dividerFaint: const Color(0x66DCC79F),
      primary: const Color(0xFFC98914),
      primaryStrong: const Color(0xFFA96F08),
      primaryContainer: const Color(0xFFFFF4D9),
      brandNekoText: const Color(0xFFC98914),
      secondary: const Color(0xFF3D96A0),
      secondaryContainer: const Color(0xFFEAF8FA),
      shadow: [
        const BoxShadow(
          color: Color(0x14C98914),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x21C98914),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.cyan => base.copyWith(
      background: const Color(0xFFF4FCFD),
      page: const Color(0xFFFAFEFF),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFECFAFC),
      surfaceHigh: const Color(0xFFDFF3F7),
      surfaceVariant: const Color(0xFFECFAFC),
      railSurface: const Color(0xFFE9F8FA),
      railIcon: const Color(0xFF577D84),
      railLabel: const Color(0xFF78979E),
      outline: const Color(0xFFD0E6EA),
      dividerSoft: const Color(0xADBBD9DE),
      dividerFaint: const Color(0x66BBD9DE),
      primary: const Color(0xFF2BA7B8),
      primaryStrong: const Color(0xFF16899B),
      primaryContainer: const Color(0xFFE8F8FB),
      brandNekoText: const Color(0xFF2BA7B8),
      secondary: const Color(0xFF3D87C7),
      secondaryContainer: const Color(0xFFEEF6FF),
      shadow: [
        const BoxShadow(
          color: Color(0x142BA7B8),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x212BA7B8),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.rose => base.copyWith(
      background: const Color(0xFFFFF7FA),
      page: const Color(0xFFFFFBFD),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFFFF0F6),
      surfaceHigh: const Color(0xFFFFE3EE),
      surfaceVariant: const Color(0xFFFFF0F6),
      railSurface: const Color(0xFFFFEEF5),
      railIcon: const Color(0xFF8D6677),
      railLabel: const Color(0xFFA38493),
      outline: const Color(0xFFEAD0DA),
      dividerSoft: const Color(0xADDEBCCB),
      dividerFaint: const Color(0x66DEBCCB),
      primary: const Color(0xFFE85D8F),
      primaryStrong: const Color(0xFFC94678),
      primaryContainer: const Color(0xFFFFEEF5),
      brandNekoText: const Color(0xFFE85D8F),
      secondary: const Color(0xFF4BA6C7),
      secondaryContainer: const Color(0xFFEAF7FB),
      shadow: [
        const BoxShadow(
          color: Color(0x14E85D8F),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x21E85D8F),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.peach => base.copyWith(
      background: const Color(0xFFFFF7F4),
      page: const Color(0xFFFFFCFA),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFFFF1EC),
      surfaceHigh: const Color(0xFFFFE3D9),
      surfaceVariant: const Color(0xFFFFF1EC),
      railSurface: const Color(0xFFFFEFE8),
      railIcon: const Color(0xFF8D6E65),
      railLabel: const Color(0xFFA48B82),
      outline: const Color(0xFFEBD2C8),
      dividerSoft: const Color(0xADDEBFB5),
      dividerFaint: const Color(0x66DEBFB5),
      primary: const Color(0xFFE88772),
      primaryStrong: const Color(0xFFC96D58),
      primaryContainer: const Color(0xFFFFF0EA),
      brandNekoText: const Color(0xFFE88772),
      secondary: const Color(0xFF4FA49B),
      secondaryContainer: const Color(0xFFEAF7F5),
      shadow: [
        const BoxShadow(
          color: Color(0x14E88772),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x21E88772),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.lilac => base.copyWith(
      background: const Color(0xFFFBF7FF),
      page: const Color(0xFFFEFBFF),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFF8F0FF),
      surfaceHigh: const Color(0xFFF0E4FB),
      surfaceVariant: const Color(0xFFF8F0FF),
      railSurface: const Color(0xFFF6EEFB),
      railIcon: const Color(0xFF806C91),
      railLabel: const Color(0xFF9A86A9),
      outline: const Color(0xFFE3D4ED),
      dividerSoft: const Color(0xADD5C1E4),
      dividerFaint: const Color(0x66D5C1E4),
      primary: const Color(0xFFB77BE8),
      primaryStrong: const Color(0xFF9C62D0),
      primaryContainer: const Color(0xFFF6ECFF),
      brandNekoText: const Color(0xFFB77BE8),
      secondary: const Color(0xFF4CA5C3),
      secondaryContainer: const Color(0xFFEAF7FB),
      shadow: [
        const BoxShadow(
          color: Color(0x14B77BE8),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x21B77BE8),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.sage => base.copyWith(
      background: const Color(0xFFF6FCF4),
      page: const Color(0xFFFBFFFA),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFF0F8EF),
      surfaceHigh: const Color(0xFFE6F0E4),
      surfaceVariant: const Color(0xFFF0F8EF),
      railSurface: const Color(0xFFEDF6EC),
      railIcon: const Color(0xFF667D64),
      railLabel: const Color(0xFF839B81),
      outline: const Color(0xFFD9E7D6),
      dividerSoft: const Color(0xADC7DBC4),
      dividerFaint: const Color(0x66C7DBC4),
      primary: const Color(0xFF6FA36F),
      primaryStrong: const Color(0xFF568A56),
      primaryContainer: const Color(0xFFECF7EA),
      brandNekoText: const Color(0xFF6FA36F),
      secondary: const Color(0xFF4C9DAB),
      secondaryContainer: const Color(0xFFEAF8FA),
      shadow: [
        const BoxShadow(
          color: Color(0x146FA36F),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x216FA36F),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.indigo => base.copyWith(
      background: const Color(0xFFF7F9FF),
      page: const Color(0xFFFBFCFF),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFF0F3FF),
      surfaceHigh: const Color(0xFFE7EBFB),
      surfaceVariant: const Color(0xFFF0F3FF),
      railSurface: const Color(0xFFEEF2FB),
      railIcon: const Color(0xFF687291),
      railLabel: const Color(0xFF858EAB),
      outline: const Color(0xFFD7DDEC),
      dividerSoft: const Color(0xADC4CCDF),
      dividerFaint: const Color(0x66C4CCDF),
      primary: const Color(0xFF5D73D8),
      primaryStrong: const Color(0xFF485EC2),
      primaryContainer: const Color(0xFFEEF2FF),
      brandNekoText: const Color(0xFF5D73D8),
      secondary: const Color(0xFF4BA3BC),
      secondaryContainer: const Color(0xFFEAF7FA),
      shadow: [
        const BoxShadow(
          color: Color(0x145D73D8),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x215D73D8),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
    YnekoColorScheme.cocoa => base.copyWith(
      background: const Color(0xFFFBF7F3),
      page: const Color(0xFFFFFCFA),
      surface: const Color(0xFFFFFFFF),
      surfaceLow: const Color(0xFFF8F1EC),
      surfaceHigh: const Color(0xFFEFE3DA),
      surfaceVariant: const Color(0xFFF8F1EC),
      railSurface: const Color(0xFFF5ECE5),
      railIcon: const Color(0xFF7F6D61),
      railLabel: const Color(0xFF9A887B),
      outline: const Color(0xFFE2D4C9),
      dividerSoft: const Color(0xADD5C4B7),
      dividerFaint: const Color(0x66D5C4B7),
      primary: const Color(0xFFA1704B),
      primaryStrong: const Color(0xFF85583A),
      primaryContainer: const Color(0xFFF6ECE4),
      brandNekoText: const Color(0xFFA1704B),
      secondary: const Color(0xFF4B9A9A),
      secondaryContainer: const Color(0xFFEAF7F5),
      shadow: [
        const BoxShadow(
          color: Color(0x14A1704B),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
      shadowStrong: [
        const BoxShadow(
          color: Color(0x21A1704B),
          blurRadius: 36,
          offset: Offset(0, 16),
        ),
      ],
    ),
  };
}

YnekoThemeTokens _darkSchemeTokens(
  YnekoThemeTokens base,
  YnekoColorScheme colorScheme,
) {
  return switch (colorScheme) {
    YnekoColorScheme.yneko => base,
    YnekoColorScheme.blue => base.copyWith(
      primary: const Color(0xFF73B4FF),
      primaryStrong: const Color(0xFF9FCAFF),
      primaryContainer: const Color(0xFF1D314B),
      brandNekoText: const Color(0xFF73B4FF),
      secondary: const Color(0xFF32B5DD),
      secondaryContainer: const Color(0xFF173241),
    ),
    YnekoColorScheme.gray => base.copyWith(
      primary: const Color(0xFFAEB3BB),
      primaryStrong: const Color(0xFFF1F2F3),
      primaryContainer: const Color(0xFF30323A),
      brandNekoText: const Color(0xFFAEB3BB),
      secondary: const Color(0xFF73B4FF),
      secondaryContainer: const Color(0xFF1D314B),
    ),
    YnekoColorScheme.mint => base.copyWith(
      primary: const Color(0xFF5FD6BD),
      primaryStrong: const Color(0xFF8BE5D1),
      primaryContainer: const Color(0xFF193A34),
      brandNekoText: const Color(0xFF5FD6BD),
      secondary: const Color(0xFF6DCBE0),
      secondaryContainer: const Color(0xFF173841),
    ),
    YnekoColorScheme.spruce => base.copyWith(
      primary: const Color(0xFF5ECED0),
      primaryStrong: const Color(0xFF86E0E2),
      primaryContainer: const Color(0xFF18393B),
      brandNekoText: const Color(0xFF5ECED0),
      secondary: const Color(0xFF73B4FF),
      secondaryContainer: const Color(0xFF1D314B),
    ),
    YnekoColorScheme.lavender => base.copyWith(
      primary: const Color(0xFFAEA3FF),
      primaryStrong: const Color(0xFFC8C1FF),
      primaryContainer: const Color(0xFF302B50),
      brandNekoText: const Color(0xFFAEA3FF),
      secondary: const Color(0xFF73C4DF),
      secondaryContainer: const Color(0xFF173841),
    ),
    YnekoColorScheme.apricot => base.copyWith(
      primary: const Color(0xFFEFB07C),
      primaryStrong: const Color(0xFFFFC89B),
      primaryContainer: const Color(0xFF402D20),
      brandNekoText: const Color(0xFFEFB07C),
      secondary: const Color(0xFF79CBC8),
      secondaryContainer: const Color(0xFF193A38),
    ),
    YnekoColorScheme.coral => base.copyWith(
      primary: const Color(0xFFFF9D91),
      primaryStrong: const Color(0xFFFFBAB1),
      primaryContainer: const Color(0xFF442822),
      brandNekoText: const Color(0xFFFF9D91),
      secondary: const Color(0xFF79CBC8),
      secondaryContainer: const Color(0xFF193A38),
    ),
    YnekoColorScheme.amber => base.copyWith(
      primary: const Color(0xFFF3C15F),
      primaryStrong: const Color(0xFFFFD98B),
      primaryContainer: const Color(0xFF3F3218),
      brandNekoText: const Color(0xFFF3C15F),
      secondary: const Color(0xFF73C9D5),
      secondaryContainer: const Color(0xFF173841),
    ),
    YnekoColorScheme.cyan => base.copyWith(
      primary: const Color(0xFF73D5E2),
      primaryStrong: const Color(0xFF99E5EE),
      primaryContainer: const Color(0xFF173A41),
      brandNekoText: const Color(0xFF73D5E2),
      secondary: const Color(0xFF73B4FF),
      secondaryContainer: const Color(0xFF1D314B),
    ),
    YnekoColorScheme.rose => base.copyWith(
      primary: const Color(0xFFFF9ABE),
      primaryStrong: const Color(0xFFFFBAD2),
      primaryContainer: const Color(0xFF442635),
      brandNekoText: const Color(0xFFFF9ABE),
      secondary: const Color(0xFF73C4DF),
      secondaryContainer: const Color(0xFF173841),
    ),
    YnekoColorScheme.peach => base.copyWith(
      primary: const Color(0xFFFFB39F),
      primaryStrong: const Color(0xFFFFCCBF),
      primaryContainer: const Color(0xFF432C25),
      brandNekoText: const Color(0xFFFFB39F),
      secondary: const Color(0xFF7CCBC2),
      secondaryContainer: const Color(0xFF193A38),
    ),
    YnekoColorScheme.lilac => base.copyWith(
      primary: const Color(0xFFDDB6FF),
      primaryStrong: const Color(0xFFECCFFF),
      primaryContainer: const Color(0xFF3C2B4D),
      brandNekoText: const Color(0xFFDDB6FF),
      secondary: const Color(0xFF73C4DF),
      secondaryContainer: const Color(0xFF173841),
    ),
    YnekoColorScheme.sage => base.copyWith(
      primary: const Color(0xFFA5D6A2),
      primaryStrong: const Color(0xFFC2E8BF),
      primaryContainer: const Color(0xFF253B25),
      brandNekoText: const Color(0xFFA5D6A2),
      secondary: const Color(0xFF78CAD4),
      secondaryContainer: const Color(0xFF173841),
    ),
    YnekoColorScheme.indigo => base.copyWith(
      primary: const Color(0xFFA6B4FF),
      primaryStrong: const Color(0xFFC4CDFF),
      primaryContainer: const Color(0xFF2A3153),
      brandNekoText: const Color(0xFFA6B4FF),
      secondary: const Color(0xFF73C4DF),
      secondaryContainer: const Color(0xFF173841),
    ),
    YnekoColorScheme.cocoa => base.copyWith(
      primary: const Color(0xFFD9B08A),
      primaryStrong: const Color(0xFFEFC9A5),
      primaryContainer: const Color(0xFF3A2D24),
      brandNekoText: const Color(0xFFD9B08A),
      secondary: const Color(0xFF78C6C4),
      secondaryContainer: const Color(0xFF193A38),
    ),
  };
}

TextTheme _ynekoTextTheme(YnekoThemeTokens tokens) {
  const family = YnekoThemeTokens.fontFamily;
  const fallback = YnekoThemeTokens.fontFallback;

  TextStyle style({
    required double size,
    required FontWeight weight,
    required double height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      color: color ?? tokens.ink,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  return TextTheme(
    displayLarge: style(size: 42, weight: FontWeight.w700, height: 1.12),
    displayMedium: style(size: 36, weight: FontWeight.w700, height: 1.14),
    displaySmall: style(size: 32, weight: FontWeight.w700, height: 1.16),
    headlineLarge: style(size: 30, weight: FontWeight.w700, height: 1.16),
    headlineMedium: style(size: 28, weight: FontWeight.w700, height: 1.18),
    headlineSmall: style(size: 28, weight: FontWeight.w700, height: 1.18),
    titleLarge: style(size: 22, weight: FontWeight.w700, height: 1.2),
    titleMedium: style(size: 17, weight: FontWeight.w700, height: 1.28),
    titleSmall: style(size: 15, weight: FontWeight.w600, height: 1.3),
    bodyLarge: style(size: 15, weight: FontWeight.w400, height: 1.45),
    bodyMedium: style(size: 14, weight: FontWeight.w400, height: 1.45),
    bodySmall: style(
      size: 13,
      weight: FontWeight.w400,
      height: 1.35,
      color: tokens.muted,
    ),
    labelLarge: style(size: 14, weight: FontWeight.w600, height: 1.2),
    labelMedium: style(size: 12, weight: FontWeight.w600, height: 1.2),
    labelSmall: style(size: 11, weight: FontWeight.w600, height: 1.2),
  );
}
