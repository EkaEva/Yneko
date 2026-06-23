import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final directoryPickerProvider = Provider<DirectoryPickerService>(
  (_) => const MethodChannelDirectoryPickerService(),
);

abstract interface class DirectoryPickerService {
  Future<String?> pickDirectory({String? initialDirectory});
}

class MethodChannelDirectoryPickerService implements DirectoryPickerService {
  const MethodChannelDirectoryPickerService();

  static const _channel = MethodChannel('yneko/platform');

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async {
    final selected = await _channel.invokeMethod<String>(
      'selectDirectory',
      <String, Object?>{'initialDirectory': initialDirectory},
    );
    if (selected == null || selected.trim().isEmpty) return null;
    return selected;
  }
}
