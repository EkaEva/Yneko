import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

class WindowChromeService {
  const WindowChromeService._();

  static Future<void> initialize() async {
    if (!_supportsWindowManager) return;
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1360, 820),
      minimumSize: Size(1120, 700),
      center: true,
      title: 'Yneko',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Color(0xFFFFFFFF),
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  static Future<void> startDragging() async {
    if (!_supportsWindowManager) return;
    await windowManager.startDragging();
  }

  static Future<void> minimize() async {
    if (!_supportsWindowManager) return;
    await windowManager.minimize();
  }

  static Future<void> toggleMaximize() async {
    if (!_supportsWindowManager) return;
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  static Future<void> close() async {
    if (!_supportsWindowManager) return;
    await windowManager.close();
  }

  static bool get _supportsWindowManager {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}
