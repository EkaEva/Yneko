import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'src/features/shell/index.dart';
import 'src/infrastructure/platform/window_chrome/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await WindowChromeService.initialize();
  runApp(const ProviderScope(child: YnekoApp()));
}
