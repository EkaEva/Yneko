import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SettingsPanel {
  root,
  appearance,
  download,
  rules,
  player,
  danmaku,
  backup,
  cache,
}

class SettingsPanelController extends Notifier<SettingsPanel> {
  @override
  SettingsPanel build() => SettingsPanel.root;

  void open(SettingsPanel panel) {
    state = panel;
  }

  void openRoot() {
    state = SettingsPanel.root;
  }
}

final settingsPanelProvider =
    NotifierProvider<SettingsPanelController, SettingsPanel>(
      SettingsPanelController.new,
    );
