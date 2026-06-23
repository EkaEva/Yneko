import 'package:flutter/material.dart';

import '../theme/index.dart';

@immutable
class AppearanceSettings {
  const AppearanceSettings({
    required this.themeMode,
    required this.colorScheme,
  });

  static const defaults = AppearanceSettings(
    themeMode: ThemeMode.light,
    colorScheme: YnekoColorScheme.yneko,
  );

  final ThemeMode themeMode;
  final YnekoColorScheme colorScheme;

  AppearanceSettings copyWith({
    ThemeMode? themeMode,
    YnekoColorScheme? colorScheme,
  }) {
    return AppearanceSettings(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}
