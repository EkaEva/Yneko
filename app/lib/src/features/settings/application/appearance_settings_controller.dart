import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/bridge/yneko_backend.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/theme/index.dart';

final appearanceSettingsProvider =
    AsyncNotifierProvider<AppearanceSettingsController, AppearanceSettings>(
      AppearanceSettingsController.new,
    );

class AppearanceSettingsController extends AsyncNotifier<AppearanceSettings> {
  @override
  Future<AppearanceSettings> build() async {
    return ref.read(ynekoBackendProvider).getAppearanceSettings();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _save(current.copyWith(themeMode: themeMode));
  }

  Future<void> setColorScheme(YnekoColorScheme colorScheme) async {
    await _save(current.copyWith(colorScheme: colorScheme));
  }

  AppearanceSettings get current {
    return state.value ?? AppearanceSettings.defaults;
  }

  Future<void> _save(AppearanceSettings next) async {
    final previous = state;
    state = AsyncData(next);
    try {
      final saved = await ref
          .read(ynekoBackendProvider)
          .saveAppearanceSettings(next);
      state = AsyncData(saved);
    } catch (error, stackTrace) {
      state = previous;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
