import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_navigation_controller.dart';
import '../../shell/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _colorScheme = 'Yneko 粉';
  String _startupPage = '首页';
  String _downloadPath = 'D:\\Yneko\\Downloads';
  int _downloadConcurrency = 3;
  String _downloadStrategy = '优先清晰度';
  String _playerEngine = 'media_kit';
  String _superResolution = '关闭';
  String _aspectRatio = '自适应';
  String _danmakuSource = '接口占位';
  String _danmakuBlockRule = '默认';
  bool _useSystemFont = false;
  bool _mirror = false;
  bool _subtitleRendering = true;

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(settingsPanelProvider);
    if (panel == SettingsPanel.root) {
      return _SettingsRootPage(
        colorScheme: _colorScheme,
        onPanel: (panel) =>
            ref.read(settingsPanelProvider.notifier).open(panel),
      );
    }

    return _SettingsDetailPage(panel: panel, child: _panelContent(panel));
  }

  Widget _panelContent(SettingsPanel panel) {
    return switch (panel) {
      SettingsPanel.appearance => _AppearancePanel(
        colorScheme: _colorScheme,
        startupPage: _startupPage,
        useSystemFont: _useSystemFont,
        onColorScheme: (value) => setState(() => _colorScheme = value),
        onStartupPage: (value) => setState(() => _startupPage = value),
        onSystemFont: () => setState(() => _useSystemFont = !_useSystemFont),
      ),
      SettingsPanel.download => _DownloadPanel(
        path: _downloadPath,
        concurrency: _downloadConcurrency,
        strategy: _downloadStrategy,
        onPath: (value) => setState(() => _downloadPath = value),
        onConcurrency: (value) =>
            setState(() => _downloadConcurrency = value.clamp(1, 8)),
        onStrategy: (value) => setState(() => _downloadStrategy = value),
      ),
      SettingsPanel.rules => const _RulesPanel(),
      SettingsPanel.player => _PlayerPanel(
        engine: _playerEngine,
        superResolution: _superResolution,
        aspectRatio: _aspectRatio,
        mirror: _mirror,
        onEngine: (value) => setState(() => _playerEngine = value),
        onSuperResolution: (value) => setState(() => _superResolution = value),
        onAspectRatio: (value) => setState(() => _aspectRatio = value),
        onMirror: () => setState(() => _mirror = !_mirror),
      ),
      SettingsPanel.danmaku => _DanmakuPanel(
        source: _danmakuSource,
        blockRule: _danmakuBlockRule,
        subtitleRendering: _subtitleRendering,
        onSource: (value) => setState(() => _danmakuSource = value),
        onBlockRule: (value) => setState(() => _danmakuBlockRule = value),
        onSubtitleRendering: () =>
            setState(() => _subtitleRendering = !_subtitleRendering),
      ),
      SettingsPanel.backup => const _BackupPanel(),
      SettingsPanel.cache => const _CachePanel(),
      SettingsPanel.root => const SizedBox.shrink(),
    };
  }
}

class _SettingsRootPage extends StatelessWidget {
  const _SettingsRootPage({required this.colorScheme, required this.onPanel});

  final String colorScheme;
  final ValueChanged<SettingsPanel> onPanel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('settings-root-page'),
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 48),
      children: [
        const _SettingsProfileCard(),
        const SizedBox(height: 28),
        _SettingsGroup(
          title: '常规',
          children: [
            _SettingsEntry(
              icon: Icons.palette_outlined,
              title: '外观',
              description: '主题配色、字体与启动页，当前配色方案 $colorScheme。',
              onTap: () => onPanel(SettingsPanel.appearance),
            ),
            _SettingsEntry(
              icon: Icons.download_rounded,
              title: '下载设置',
              description: '下载路径、并发任务、下载策略与命名规范。',
              onTap: () => onPanel(SettingsPanel.download),
            ),
            _SettingsEntry(
              icon: Icons.tune_rounded,
              title: '规则管理',
              description: '规则源导入、启停、测试与维护。',
              onTap: () => onPanel(SettingsPanel.rules),
            ),
          ],
        ),
        _SettingsGroup(
          title: '播放设置',
          children: [
            _SettingsEntry(
              icon: Icons.monitor_rounded,
              title: '播放器设置',
              description: '解码引擎、超分辨率与视频比例。',
              onTap: () => onPanel(SettingsPanel.player),
            ),
            _SettingsEntry(
              icon: Icons.forum_outlined,
              title: '弹幕实验室',
              description: '弹幕源、屏蔽规则与字幕渲染。',
              onTap: () => onPanel(SettingsPanel.danmaku),
            ),
          ],
        ),
        _SettingsGroup(
          title: '数据与备份',
          children: [
            const _SettingsEntry(
              icon: Icons.cloud_queue_rounded,
              title: '云端同步',
              description: '同步追番、历史、设置与规则数据。',
            ),
            _SettingsEntry(
              icon: Icons.archive_outlined,
              title: '本地备份',
              description: '导出追番、历史与规则源的本地备份。',
              onTap: () => onPanel(SettingsPanel.backup),
            ),
            _SettingsEntry(
              icon: Icons.storage_rounded,
              title: '缓存清理',
              description: '查看离线缓存体积并清理临时数据。',
              onTap: () => onPanel(SettingsPanel.cache),
            ),
          ],
        ),
        const _SettingsGroup(
          title: '关于',
          children: [
            _SettingsEntry(
              icon: Icons.info_outline_rounded,
              title: 'Yneko',
              description: '版本 0.1.0 · 桌面 · Flutter + Rust',
            ),
            _SettingsEntry(
              icon: Icons.menu_book_rounded,
              title: '项目说明',
              description: '番剧检索、追番、播放与规则源管理的本地桌面体验。',
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard();

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      key: const ValueKey('settings-profile-card'),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.dividerSoft)),
      ),
      child: Row(
        children: [
          const YnekoProfileAvatar(),
          const SizedBox(width: 24),
          Text('喵', style: type.sectionTitle.copyWith(fontSize: 21)),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: type.controlTitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _SettingsEntryList(children: children),
        ],
      ),
    );
  }
}

class _SettingsEntryList extends StatelessWidget {
  const _SettingsEntryList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.54)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: tokens.dividerFaint)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: tokens.ink),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: type.controlTitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      overflow: TextOverflow.ellipsis,
                      style: type.label.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 14), trailing!],
              if (onTap != null) ...[
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded, color: tokens.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({required this.panel, required this.child});

  final SettingsPanel panel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: ValueKey('settings-detail-${panel.name}'),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
      children: [
        Text(_panelTitle(panel), style: YnekoTypography.of(context).pageTitle),
        const SizedBox(height: 20),
        child,
      ],
    );
  }

  String _panelTitle(SettingsPanel panel) {
    return switch (panel) {
      SettingsPanel.appearance => '外观',
      SettingsPanel.download => '下载设置',
      SettingsPanel.rules => '规则管理',
      SettingsPanel.player => '播放器设置',
      SettingsPanel.danmaku => '弹幕实验室',
      SettingsPanel.backup => '本地备份',
      SettingsPanel.cache => '缓存清理',
      SettingsPanel.root => '设置',
    };
  }
}

class _AppearancePanel extends ConsumerWidget {
  const _AppearancePanel({
    required this.colorScheme,
    required this.startupPage,
    required this.useSystemFont,
    required this.onColorScheme,
    required this.onStartupPage,
    required this.onSystemFont,
  });

  final String colorScheme;
  final String startupPage;
  final bool useSystemFont;
  final ValueChanged<String> onColorScheme;
  final ValueChanged<String> onStartupPage;
  final VoidCallback onSystemFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsEntryList(
      children: [
        _SettingsEntry(
          icon: Icons.dark_mode_outlined,
          title: '主题模式',
          description: '浅色 / 深色外观会立即作用于界面。',
          trailing: _SegmentedControl(
            options: const ['浅色', '深色'],
            value: ref.watch(shellThemeModeProvider) == ThemeMode.dark
                ? '深色'
                : '浅色',
            onChanged: (_) =>
                ref.read(shellThemeModeProvider.notifier).toggle(),
          ),
        ),
        _SettingsEntry(
          icon: Icons.color_lens_outlined,
          title: '配色方案',
          description: colorScheme,
          trailing: _ColorSwatches(
            value: colorScheme,
            onChanged: onColorScheme,
          ),
        ),
        _SettingsEntry(
          icon: Icons.font_download_outlined,
          title: '使用系统字体',
          description: '关闭时优先使用项目内置 MiSansYneko。',
          trailing: _SettingsSwitch(
            checked: useSystemFont,
            onTap: onSystemFont,
          ),
        ),
        _SettingsEntry(
          icon: Icons.home_outlined,
          title: '启动页',
          description: startupPage,
          trailing: _SegmentedControl(
            options: const ['首页', '我的', '设置'],
            value: startupPage,
            onChanged: onStartupPage,
          ),
        ),
      ],
    );
  }
}

class _DownloadPanel extends StatelessWidget {
  const _DownloadPanel({
    required this.path,
    required this.concurrency,
    required this.strategy,
    required this.onPath,
    required this.onConcurrency,
    required this.onStrategy,
  });

  final String path;
  final int concurrency;
  final String strategy;
  final ValueChanged<String> onPath;
  final ValueChanged<int> onConcurrency;
  final ValueChanged<String> onStrategy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsEntryList(
          children: [
            _SettingsEntry(
              icon: Icons.folder_open_rounded,
              title: '下载路径',
              description: path,
              trailing: SizedBox(
                width: 260,
                child: TextField(
                  controller: TextEditingController(text: path),
                  onSubmitted: onPath,
                  decoration: const InputDecoration(hintText: '下载路径'),
                ),
              ),
            ),
            _SettingsEntry(
              icon: Icons.format_list_numbered_rounded,
              title: '并发任务',
              description: '限制同时下载的任务数量。',
              trailing: _Stepper(value: concurrency, onChanged: onConcurrency),
            ),
            _SettingsEntry(
              icon: Icons.rule_rounded,
              title: '下载策略',
              description: strategy,
              trailing: _SegmentedControl(
                options: const ['优先清晰度', '节省空间', '手动选择'],
                value: strategy,
                onChanged: onStrategy,
              ),
            ),
            const _SettingsEntry(
              icon: Icons.text_snippet_outlined,
              title: '命名模板',
              description: '{title}/S01E{episode} - {episodeTitle}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _HintPanel(text: '下载与离线缓存不在 V1 范围内，本页先保留完整设置入口。'),
      ],
    );
  }
}

class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsEntryList(
          children: [
            const _SettingsEntry(
              icon: Icons.account_tree_outlined,
              title: '默认规则组',
              description: '3 个规则源 · 自动匹配候选',
              trailing: _RuleStatusDot(active: true),
            ),
            const _SettingsEntry(
              icon: Icons.account_tree_outlined,
              title: '备用规则组',
              description: '2 个规则源 · 手动选择',
              trailing: _RuleStatusDot(active: true),
            ),
            _SettingsEntry(
              icon: Icons.add_rounded,
              title: '导入规则源',
              description: '支持粘贴仓库地址或本地规则包路径。',
              trailing: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.download_rounded),
                label: const Text('导入'),
              ),
            ),
            _SettingsEntry(
              icon: Icons.edit_note_rounded,
              title: '规则编辑器',
              description: '配置测试、候选矩阵与规则分组维护入口。',
              trailing: FilledButton.tonalIcon(
                onPressed: null,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('打开'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _HintPanel(
          text: '规则源仍遵守 declarative source package 边界；这里不会执行脚本或保存凭据。',
        ),
      ],
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.engine,
    required this.superResolution,
    required this.aspectRatio,
    required this.mirror,
    required this.onEngine,
    required this.onSuperResolution,
    required this.onAspectRatio,
    required this.onMirror,
  });

  final String engine;
  final String superResolution;
  final String aspectRatio;
  final bool mirror;
  final ValueChanged<String> onEngine;
  final ValueChanged<String> onSuperResolution;
  final ValueChanged<String> onAspectRatio;
  final VoidCallback onMirror;

  @override
  Widget build(BuildContext context) {
    return _SettingsEntryList(
      children: [
        _SettingsEntry(
          icon: Icons.memory_rounded,
          title: '播放引擎',
          description: engine,
          trailing: _SegmentedControl(
            options: const ['media_kit', '占位'],
            value: engine,
            onChanged: onEngine,
          ),
        ),
        _SettingsEntry(
          icon: Icons.auto_awesome_rounded,
          title: '超分辨率',
          description: superResolution,
          trailing: _SegmentedControl(
            options: const ['关闭', '2x', '4x'],
            value: superResolution,
            onChanged: onSuperResolution,
          ),
        ),
        _SettingsEntry(
          icon: Icons.aspect_ratio_rounded,
          title: '视频比例',
          description: aspectRatio,
          trailing: _SegmentedControl(
            options: const ['自适应', '16:9', '4:3'],
            value: aspectRatio,
            onChanged: onAspectRatio,
          ),
        ),
        _SettingsEntry(
          icon: Icons.flip_rounded,
          title: '镜像画面',
          description: '播放器控件壳预留设置项。',
          trailing: _SettingsSwitch(checked: mirror, onTap: onMirror),
        ),
      ],
    );
  }
}

class _DanmakuPanel extends StatelessWidget {
  const _DanmakuPanel({
    required this.source,
    required this.blockRule,
    required this.subtitleRendering,
    required this.onSource,
    required this.onBlockRule,
    required this.onSubtitleRendering,
  });

  final String source;
  final String blockRule;
  final bool subtitleRendering;
  final ValueChanged<String> onSource;
  final ValueChanged<String> onBlockRule;
  final VoidCallback onSubtitleRendering;

  @override
  Widget build(BuildContext context) {
    return _SettingsEntryList(
      children: [
        _SettingsEntry(
          icon: Icons.forum_outlined,
          title: '弹幕源',
          description: source,
          trailing: _SegmentedControl(
            options: const ['接口占位', '本地测试'],
            value: source,
            onChanged: onSource,
          ),
        ),
        _SettingsEntry(
          icon: Icons.block_rounded,
          title: '屏蔽规则',
          description: blockRule,
          trailing: _SegmentedControl(
            options: const ['默认', '严格', '关闭'],
            value: blockRule,
            onChanged: onBlockRule,
          ),
        ),
        _SettingsEntry(
          icon: Icons.subtitles_rounded,
          title: '字幕渲染',
          description: '保留播放器字幕/弹幕组合入口。',
          trailing: _SettingsSwitch(
            checked: subtitleRendering,
            onTap: onSubtitleRendering,
          ),
        ),
      ],
    );
  }
}

class _BackupPanel extends StatelessWidget {
  const _BackupPanel();

  @override
  Widget build(BuildContext context) {
    return const _SettingsEntryList(
      children: [
        _SettingsEntry(
          icon: Icons.file_upload_outlined,
          title: '导出本地备份',
          description: '导出追番、历史、规则源和设置。',
        ),
        _SettingsEntry(
          icon: Icons.file_download_outlined,
          title: '导入本地备份',
          description: '从本地备份恢复应用数据。',
        ),
      ],
    );
  }
}

class _CachePanel extends StatelessWidget {
  const _CachePanel();

  @override
  Widget build(BuildContext context) {
    return const _SettingsEntryList(
      children: [
        _SettingsEntry(
          icon: Icons.storage_rounded,
          title: '离线缓存',
          description: '约 1.6 GB · V1 暂不启用下载。',
        ),
        _SettingsEntry(
          icon: Icons.cleaning_services_outlined,
          title: '清理临时数据',
          description: '清理封面缓存、日志与临时索引。',
        ),
      ],
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.dividerFaint),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                height: 30,
                constraints: const BoxConstraints(minWidth: 58),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: option == value ? tokens.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: option == value ? tokens.shadow : null,
                ),
                child: Text(
                  option,
                  style: type.label.copyWith(
                    color: option == value ? tokens.ink : tokens.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: YnekoThemeTokens.fastMotion,
        width: 42,
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: checked ? tokens.primary : tokens.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: checked ? tokens.primary : tokens.outline),
        ),
        child: AnimatedAlign(
          duration: YnekoThemeTokens.fastMotion,
          alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: tokens.shadow,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.dividerFaint),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 28),
            onPressed: () => onChanged(value - 1),
            icon: const Icon(Icons.remove_rounded, size: 16),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: YnekoTypography.of(
                context,
              ).label.copyWith(color: tokens.ink, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 28),
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded, size: 16),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = const [
      ('Yneko 粉', [Color(0xFFFF6699), Color(0xFFFFF0F5), Color(0xFF00A1D6)]),
      ('海风蓝', [Color(0xFF00A1D6), Color(0xFFE6F7FF), Color(0xFFFF6699)]),
      ('薄荷绿', [Color(0xFF16A085), Color(0xFFE8FFF7), Color(0xFF2F8AF5)]),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: option.$1,
              child: InkWell(
                onTap: () => onChanged(option.$1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: YnekoThemeTokens.of(context).surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value == option.$1
                          ? YnekoThemeTokens.of(context).primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      for (final color in option.$2)
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RuleStatusDot extends StatelessWidget {
  const _RuleStatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2DBF6F)
            : YnekoThemeTokens.of(context).soft,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.52)),
      ),
      child: Text(text, style: YnekoTypography.of(context).meta),
    );
  }
}
