import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _panel = 0;
  bool _danmakuVisible = true;
  bool _mirror = false;
  double _opacity = 78;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 16, 48),
            children: [
              Text('设置', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              for (final entry in ['外观', '播放', '规则源', '弹幕实验室'].indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    selected: _panel == entry.$1,
                    selectedColor: tokens.primary,
                    selectedTileColor: tokens.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    title: Text(entry.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                    onTap: () => setState(() => _panel = entry.$1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 24, 28, 48),
            children: [
              YnekoSectionTitle(
                title: ['外观', '播放', '规则源', '弹幕实验室'][_panel],
                subtitle: '第一阶段为静态交互壳，后续接入持久化设置',
              ),
              const SizedBox(height: 18),
              if (_panel == 0) ...[
                YnekoPanel(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('深色主题'),
                        subtitle: const Text('使用 ThemeExtension token 切换浅色/深色'),
                        value: ref.watch(shellThemeModeProvider) == ThemeMode.dark,
                        onChanged: (_) => ref.read(shellThemeModeProvider.notifier).toggle(),
                      ),
                      const Divider(),
                      const _ColorSchemePreview(),
                    ],
                  ),
                ),
              ] else if (_panel == 1) ...[
                YnekoPanel(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('镜像画面'),
                        subtitle: const Text('播放器控件壳预留设置项'),
                        value: _mirror,
                        onChanged: (value) => setState(() => _mirror = value),
                      ),
                      SliderListTile(
                        title: '默认音量',
                        value: _opacity,
                        onChanged: (value) => setState(() => _opacity = value),
                      ),
                    ],
                  ),
                ),
              ] else if (_panel == 2) ...[
                YnekoPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('规则源仓库', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      const TextField(
                        decoration: InputDecoration(
                          hintText: 'https://github.com/example/source-rules',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(onPressed: null, icon: const Icon(Icons.download_rounded), label: const Text('导入仓库')),
                    ],
                  ),
                ),
              ] else ...[
                YnekoPanel(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('显示弹幕'),
                        subtitle: const Text('V1 只保留接口和播放器槽位'),
                        value: _danmakuVisible,
                        onChanged: (value) => setState(() => _danmakuVisible = value),
                      ),
                      SliderListTile(
                        title: '不透明度',
                        value: _opacity,
                        onChanged: (value) => setState(() => _opacity = value),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SliderListTile extends StatelessWidget {
  const SliderListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Slider(
        min: 0,
        max: 100,
        value: value,
        onChanged: onChanged,
      ),
      trailing: Text('${value.round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _ColorSchemePreview extends StatelessWidget {
  const _ColorSchemePreview();

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final colors = [tokens.primary, tokens.secondary, tokens.surfaceHigh, tokens.ink];
    return Row(
      children: [
        for (final color in colors)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: const SizedBox(width: 54, height: 34),
            ),
          ),
      ],
    );
  }
}
