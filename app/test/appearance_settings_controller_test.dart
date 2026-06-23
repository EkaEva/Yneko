import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yneko/src/features/settings/index.dart';
import 'package:yneko/src/infrastructure/bridge/yneko_backend.dart';
import 'package:yneko/src/shared/domain/index.dart';
import 'package:yneko/src/shared/theme/index.dart';

import 'support/fake_yneko_backend.dart';

void main() {
  test('appearance settings load from backend and save changes', () async {
    final backend = FakeYnekoBackend(
      appearanceSettings: const AppearanceSettings(
        themeMode: ThemeMode.dark,
        colorScheme: YnekoColorScheme.mint,
      ),
    );
    final container = ProviderContainer(
      overrides: [ynekoBackendProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);

    final loaded = await container.read(appearanceSettingsProvider.future);
    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.colorScheme, YnekoColorScheme.mint);

    final controller = container.read(appearanceSettingsProvider.notifier);
    await controller.setColorScheme(YnekoColorScheme.cocoa);
    await controller.setThemeMode(ThemeMode.light);

    final saved = await backend.getAppearanceSettings();
    expect(saved.themeMode, ThemeMode.light);
    expect(saved.colorScheme, YnekoColorScheme.cocoa);
  });
}
