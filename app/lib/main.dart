import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'src/presentation/shell/yneko_app.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: YnekoApp()));
}

