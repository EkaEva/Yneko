import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../application/appearance_settings_controller.dart';
import '../application/settings_navigation_controller.dart';
import '../../sources/index.dart';
import '../../../infrastructure/platform/directory_picker/index.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _startupPage = '首页';
  String _downloadPath = 'D:\\Yneko\\Downloads';
  int _downloadConcurrency = 3;
  String _downloadStrategy = '自动';
  String _downloadNameTemplate = 'folderEpisode';
  String _downloadCustomTemplate = _downloadCustomTemplateDefault;
  String _playerEngine = '自动';
  String _superResolution = '关闭';
  String _aspectRatio = '自动';
  String _danmakuSource = '自动匹配';
  String _danmakuBlockRule = '基础屏蔽';
  bool _useSystemFont = false;
  bool _mirror = false;
  bool _subtitleRendering = true;

  @override
  Widget build(BuildContext context) {
    final panel = ref.watch(settingsPanelProvider);
    final appearance =
        ref.watch(appearanceSettingsProvider).value ??
        AppearanceSettings.defaults;
    if (panel == SettingsPanel.root) {
      return _SettingsRootPage(
        colorScheme: appearance.colorScheme,
        onPanel: (panel) =>
            ref.read(settingsPanelProvider.notifier).open(panel),
      );
    }

    return _SettingsDetailPage(panel: panel, child: _panelContent(panel));
  }

  Widget _panelContent(SettingsPanel panel) {
    return switch (panel) {
      SettingsPanel.appearance => _AppearancePanel(
        startupPage: _startupPage,
        useSystemFont: _useSystemFont,
        onStartupPage: (value) => setState(() => _startupPage = value),
        onSystemFont: () => setState(() => _useSystemFont = !_useSystemFont),
      ),
      SettingsPanel.download => _DownloadPanel(
        path: _downloadPath,
        concurrency: _downloadConcurrency,
        strategy: _downloadStrategy,
        nameTemplate: _downloadNameTemplate,
        customTemplate: _downloadCustomTemplate,
        onPath: (value) => setState(() => _downloadPath = value),
        onConcurrency: (value) =>
            setState(() => _downloadConcurrency = value.clamp(1, 5)),
        onStrategy: (value) => setState(() => _downloadStrategy = value),
        onNameTemplate: (value) =>
            setState(() => _downloadNameTemplate = value),
        onCustomTemplate: (value) =>
            setState(() => _downloadCustomTemplate = value),
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

  final YnekoColorScheme colorScheme;
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
              description: '主题配色、字体与启动页，当前配色方案 ${colorScheme.label}。',
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
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(color: tokens.surface, borderRadius: radius),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: tokens.outline.withValues(alpha: 0.58)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(children: children),
      ),
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
    return YnekoPressable(
      onTap: onTap ?? () {},
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      borderRadius: 0,
      scaleOnPress: false,
      builder: (context, hovered, pressed) {
        final hoverBackground = Color.lerp(
          tokens.surfaceHigh,
          tokens.surface,
          pressed ? 0.04 : 0.12,
        )!;
        return AnimatedContainer(
          key: ValueKey('settings-entry-$title'),
          duration: YnekoThemeTokens.fastMotion,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            color: hovered || pressed ? hoverBackground : tokens.surface,
            border: Border(
              bottom: BorderSide(color: tokens.outline.withValues(alpha: 0.34)),
            ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        overflow: TextOverflow.ellipsis,
                        style: type.label.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
        );
      },
    );
  }
}

class _SettingsDetailGroup extends StatelessWidget {
  const _SettingsDetailGroup({required this.title, required this.children});

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
            style: type.controlTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsEntryList(children: children),
        ],
      ),
    );
  }
}

class _SettingsControlRow extends StatelessWidget {
  const _SettingsControlRow({
    required this.icon,
    required this.title,
    this.description,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsEntry(
      icon: icon,
      title: title,
      description: description ?? '',
      trailing: trailing,
      onTap: onTap,
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
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
      children: [child],
    );
  }
}

class _AppearancePanel extends ConsumerWidget {
  const _AppearancePanel({
    required this.startupPage,
    required this.useSystemFont,
    required this.onStartupPage,
    required this.onSystemFont,
  });

  final String startupPage;
  final bool useSystemFont;
  final ValueChanged<String> onStartupPage;
  final VoidCallback onSystemFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(appearanceSettingsProvider).value ??
        AppearanceSettings.defaults;
    return Column(
      children: [
        _SettingsDetailGroup(
          title: '主题配色',
          children: [
            _SettingsControlRow(
              icon: Icons.palette_outlined,
              title: '默认模式',
              trailing: _SegmentedControl(
                options: const ['浅色', '深色'],
                value: appearance.themeMode == ThemeMode.dark ? '深色' : '浅色',
                onChanged: (value) => ref
                    .read(appearanceSettingsProvider.notifier)
                    .setThemeMode(
                      value == '深色' ? ThemeMode.dark : ThemeMode.light,
                    ),
              ),
            ),
            _SettingsControlRow(
              icon: Icons.auto_awesome_rounded,
              title: '配色方案',
              description: appearance.colorScheme.label,
              onTap: () => _showColorSchemeDialog(
                context,
                value: appearance.colorScheme,
                onChanged: (scheme) => ref
                    .read(appearanceSettingsProvider.notifier)
                    .setColorScheme(scheme),
              ),
            ),
          ],
        ),
        _SettingsDetailGroup(
          title: '字体设置',
          children: [
            _SettingsControlRow(
              icon: Icons.text_fields_rounded,
              title: '使用系统字体',
              description: '关闭时优先使用项目内置 MiSansYneko。',
              trailing: _SettingsSwitch(
                checked: useSystemFont,
                onTap: onSystemFont,
              ),
            ),
          ],
        ),
        _SettingsDetailGroup(
          title: '启动页设置',
          children: [
            _SettingsControlRow(
              icon: Icons.monitor_rounded,
              title: '启动后打开',
              description: startupPage,
              trailing: _SegmentedControl(
                options: const ['首页', '我的'],
                value: startupPage == '设置' ? '首页' : startupPage,
                onChanged: onStartupPage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DownloadPanel extends ConsumerWidget {
  const _DownloadPanel({
    required this.path,
    required this.concurrency,
    required this.strategy,
    required this.nameTemplate,
    required this.customTemplate,
    required this.onPath,
    required this.onConcurrency,
    required this.onStrategy,
    required this.onNameTemplate,
    required this.onCustomTemplate,
  });

  final String path;
  final int concurrency;
  final String strategy;
  final String nameTemplate;
  final String customTemplate;
  final ValueChanged<String> onPath;
  final ValueChanged<int> onConcurrency;
  final ValueChanged<String> onStrategy;
  final ValueChanged<String> onNameTemplate;
  final ValueChanged<String> onCustomTemplate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryPicker = ref.watch(directoryPickerProvider);
    return Column(
      children: [
        _SettingsDetailGroup(
          title: '保存位置',
          children: [
            _SettingsControlRow(
              icon: Icons.storage_rounded,
              title: '下载路径',
              description: path,
              onTap: () => _showDownloadPathDialog(
                context,
                value: path,
                onSave: onPath,
                directoryPicker: directoryPicker,
              ),
            ),
          ],
        ),
        _SettingsDetailGroup(
          title: '任务设置',
          children: [
            _SettingsControlRow(
              icon: Icons.playlist_play_rounded,
              title: '并发任务',
              description: '同时下载的任务数量',
              trailing: _Stepper(value: concurrency, onChanged: onConcurrency),
            ),
            _SettingsControlRow(
              icon: Icons.shuffle_rounded,
              title: '下载策略',
              trailing: _SegmentedControl(
                options: const ['自动', '仅 Wi-Fi', '手动确认'],
                value: strategy,
                onChanged: onStrategy,
              ),
            ),
          ],
        ),
        _SettingsDetailGroup(
          title: '文件命名',
          children: [
            _SettingsControlRow(
              icon: Icons.title_rounded,
              title: '命名规范',
              description: _downloadTemplatePreview(
                nameTemplate,
                customTemplate,
              ),
              onTap: () => _showNamingTemplateDialog(
                context,
                value: nameTemplate,
                customTemplate: customTemplate,
                onSave: onNameTemplate,
                onSaveCustomTemplate: onCustomTemplate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RulesPanel extends ConsumerWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(sourceLibraryControllerProvider);
    return library.when(
      loading: () => const YnekoPanel(
        child: YnekoLoadingState(title: '正在读取规则源', size: 64, minHeight: 180),
      ),
      error: (error, stackTrace) => Column(
        children: [
          SourceLibraryView(
            state: const SourceLibraryState(),
            warning: error.toString(),
          ),
        ],
      ),
      data: (state) => Column(children: [SourceLibraryView(state: state)]),
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
    return Column(
      children: [
        _SettingsDetailGroup(
          title: '播放引擎',
          children: [
            _SettingsControlRow(
              icon: Icons.memory_rounded,
              title: '播放引擎',
              description: engine,
              trailing: _ChoicePill(label: engine),
              onTap: () => _showChoiceDialog(
                context,
                title: '播放引擎',
                value: engine,
                options: const [
                  _SettingsChoice('自动', '根据片源类型自动选择当前最稳的播放链路。'),
                  _SettingsChoice('media_kit', '使用 Flutter media_kit 播放适配器。'),
                  _SettingsChoice('占位', '保留后续播放器引擎入口。', disabled: true),
                ],
                onChanged: onEngine,
              ),
            ),
          ],
        ),
        _SettingsDetailGroup(
          title: '画面设置',
          children: [
            _SettingsControlRow(
              icon: Icons.auto_awesome_rounded,
              title: '超分辨率',
              description: superResolution,
              trailing: _ChoicePill(label: superResolution),
              onTap: () => _showChoiceDialog(
                context,
                title: '超分辨率',
                value: superResolution,
                options: const [
                  _SettingsChoice('关闭', '保持原始分辨率与当前播放性能。'),
                  _SettingsChoice('均衡', '预留 GPU 超分增强，优先控制功耗。', disabled: true),
                  _SettingsChoice('画质优先', '预留高质量超分增强，适合大屏播放。', disabled: true),
                ],
                onChanged: onSuperResolution,
              ),
            ),
            _SettingsControlRow(
              icon: Icons.aspect_ratio_rounded,
              title: '视频比例',
              description: aspectRatio,
              trailing: _ChoicePill(label: aspectRatio),
              onTap: () => _showChoiceDialog(
                context,
                title: '视频比例',
                value: aspectRatio,
                options: const [
                  _SettingsChoice('自动', '按视频原始比例显示，避免画面变形。'),
                  _SettingsChoice('适应窗口', '完整显示画面，保留必要黑边。'),
                  _SettingsChoice('填充窗口', '铺满播放区域，可能裁切边缘内容。'),
                  _SettingsChoice('16:9', '固定为宽屏比例。'),
                  _SettingsChoice('4:3', '固定为经典比例。'),
                ],
                onChanged: onAspectRatio,
              ),
            ),
            _SettingsControlRow(
              icon: Icons.flip_rounded,
              title: '镜像画面',
              description: '播放器控件壳预留设置项。',
              trailing: _SettingsSwitch(checked: mirror, onTap: onMirror),
            ),
          ],
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
    return Column(
      children: [
        _SettingsDetailGroup(
          title: '弹幕来源',
          children: [
            _SettingsControlRow(
              icon: Icons.forum_outlined,
              title: '弹幕源',
              description: source,
              trailing: _ChoicePill(label: source),
              onTap: () => _showChoiceDialog(
                context,
                title: '弹幕源',
                value: source,
                options: const [
                  _SettingsChoice('自动匹配', '随当前播放源尝试匹配可用弹幕数据。'),
                  _SettingsChoice(
                    '本地弹幕文件',
                    '预留 XML / ASS 本地弹幕导入能力。',
                    disabled: true,
                  ),
                  _SettingsChoice('插件弹幕源', '由插件库扩展弹幕来源，后续接入。', disabled: true),
                ],
                onChanged: onSource,
              ),
            ),
          ],
        ),
        _SettingsDetailGroup(
          title: '显示与过滤',
          children: [
            _SettingsControlRow(
              icon: Icons.block_rounded,
              title: '屏蔽规则',
              description: blockRule,
              trailing: _ChoicePill(label: blockRule),
              onTap: () => _showChoiceDialog(
                context,
                title: '屏蔽规则',
                value: blockRule,
                options: const [
                  _SettingsChoice('关闭屏蔽', '显示所有弹幕内容，不做额外过滤。'),
                  _SettingsChoice('基础屏蔽', '过滤重复、空白和明显异常的弹幕内容。'),
                  _SettingsChoice('严格屏蔽', '扩大重复检测与低质量内容过滤范围。'),
                  _SettingsChoice(
                    '自定义规则',
                    '预留关键词、正则和用户规则编辑能力。',
                    disabled: true,
                  ),
                ],
                onChanged: onBlockRule,
              ),
            ),
            _SettingsControlRow(
              icon: Icons.subtitles_rounded,
              title: '字幕渲染',
              description: '保留播放器字幕/弹幕组合入口。',
              trailing: _SettingsSwitch(
                checked: subtitleRendering,
                onTap: onSubtitleRendering,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BackupPanel extends StatelessWidget {
  const _BackupPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SettingsDetailGroup(
          title: '本地备份',
          children: [
            _SettingsControlRow(
              icon: Icons.file_upload_outlined,
              title: '导出本地备份',
              description: '导出追番、历史、规则源和设置。',
            ),
            _SettingsControlRow(
              icon: Icons.file_download_outlined,
              title: '导入本地备份',
              description: '从本地备份恢复应用数据。',
            ),
          ],
        ),
      ],
    );
  }
}

class _CachePanel extends StatelessWidget {
  const _CachePanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SettingsDetailGroup(
          title: '缓存清理',
          children: [
            _SettingsControlRow(
              icon: Icons.storage_rounded,
              title: '离线缓存',
              description: '约 1.6 GB · V1 暂不启用下载。',
            ),
            _SettingsControlRow(
              icon: Icons.cleaning_services_outlined,
              title: '清理临时数据',
              description: '清理封面缓存、日志与临时索引。',
            ),
          ],
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
    final selectedIndex = options.indexOf(value).clamp(0, options.length - 1);
    const minItemWidth = 58.0;
    final itemWidth = options.length > 2 ? 64.0 : minItemWidth;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.dividerFaint),
      ),
      child: SizedBox(
        width: itemWidth * options.length,
        height: 30,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: YnekoThemeTokens.fastMotion,
              curve: Curves.easeOutCubic,
              left: selectedIndex * itemWidth,
              top: 0,
              width: itemWidth,
              height: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: tokens.shadow,
                ),
              ),
            ),
            Row(
              children: [
                for (final option in options)
                  _SegmentedButton(
                    width: itemWidth,
                    label: option,
                    selected: option == value,
                    textStyle: type.label,
                    inkColor: tokens.ink,
                    mutedColor: tokens.muted,
                    onTap: () => onChanged(option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedButton extends StatefulWidget {
  const _SegmentedButton({
    required this.width,
    required this.label,
    required this.selected,
    required this.textStyle,
    required this.inkColor,
    required this.mutedColor,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;
  final TextStyle textStyle;
  final Color inkColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  State<_SegmentedButton> createState() => _SegmentedButtonState();
}

class _SegmentedButtonState extends State<_SegmentedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: 30,
          child: Center(
            child: Text(
              widget.label,
              style: widget.textStyle.copyWith(
                color: widget.selected || _hovered
                    ? widget.inkColor
                    : widget.mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
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

Future<void> _showColorSchemeDialog(
  BuildContext context, {
  required YnekoColorScheme value,
  required ValueChanged<YnekoColorScheme> onChanged,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (context) => _ColorSchemeDialog(
      value: value,
      onChanged: (scheme) {
        onChanged(scheme);
        Navigator.of(context).pop();
      },
    ),
  );
}

class _ColorSchemeDialog extends StatelessWidget {
  const _ColorSchemeDialog({required this.value, required this.onChanged});

  final YnekoColorScheme value;
  final ValueChanged<YnekoColorScheme> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 920,
        padding: const EdgeInsets.fromLTRB(34, 30, 34, 34),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.52)),
          boxShadow: tokens.shadowStrong,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '配色方案',
                    style: type.sectionTitle.copyWith(fontSize: 24),
                  ),
                ),
                YnekoIconActionButton(
                  tooltip: '关闭配色方案',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  transparent: true,
                  size: 34,
                ),
              ],
            ),
            const SizedBox(height: 28),
            GridView.count(
              crossAxisCount: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 22,
              crossAxisSpacing: 18,
              childAspectRatio: 0.84,
              children: [
                for (final option in YnekoColorScheme.values)
                  Center(
                    child: _ColorSchemeOptionTile(
                      option: option,
                      active: option == value,
                      onTap: () => onChanged(option),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSchemeOptionTile extends StatelessWidget {
  const _ColorSchemeOptionTile({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final YnekoColorScheme option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPressable(
      onTap: onTap,
      borderRadius: 18,
      scaleOnPress: false,
      builder: (context, hovered, pressed) {
        final labelColor = hovered || pressed
            ? option.previewColors.first
            : tokens.ink;
        return AnimatedContainer(
          key: ValueKey('settings-color-scheme-option-${option.label}'),
          duration: YnekoThemeTokens.fastMotion,
          curve: Curves.easeOutCubic,
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        size: const Size.square(58),
                        painter: _ColorSchemePreviewPainter(
                          primary: option.previewColors[0],
                          secondary: option.previewColors[1],
                          soft: option.previewColors[2],
                          surface: tokens.surface,
                          ring: tokens.surface.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    if (active)
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color.lerp(tokens.primary, Colors.black, 0.28),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AnimatedDefaultTextStyle(
                duration: YnekoThemeTokens.fastMotion,
                curve: Curves.easeOut,
                style: YnekoTypography.of(context).label.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                child: Text(option.label, textAlign: TextAlign.center),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorSchemePreviewPainter extends CustomPainter {
  const _ColorSchemePreviewPainter({
    required this.primary,
    required this.secondary,
    required this.soft,
    required this.surface,
    required this.ring,
  });

  final Color primary;
  final Color secondary;
  final Color soft;
  final Color surface;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect);
    final innerRect = rect.deflate(8);
    final innerCircle = Path()..addOval(innerRect);
    final outerSliceWidth = size.width / 4;
    final leftColor = Color.lerp(primary, soft, 0.42)!;
    final rightColor = Color.lerp(secondary, primary, 0.22)!;
    final leftLightColor = Color.lerp(primary, soft, 0.72)!;
    final rightLightColor = Color.lerp(secondary, soft, 0.72)!;
    final innerTopColor = Color.lerp(soft, surface, 0.18)!;

    canvas.save();
    canvas.clipPath(circle);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, outerSliceWidth, size.height),
      Paint()..color = leftColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(outerSliceWidth, 0, outerSliceWidth, size.height),
      Paint()..color = leftLightColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(outerSliceWidth * 2, 0, outerSliceWidth, size.height),
      Paint()..color = rightLightColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(outerSliceWidth * 3, 0, outerSliceWidth, size.height),
      Paint()..color = rightColor,
    );
    canvas.drawCircle(
      rect.center,
      size.width / 2,
      Paint()..color = ring.withValues(alpha: 0.34),
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(innerCircle);
    canvas.drawRect(
      Rect.fromLTWH(
        innerRect.left,
        innerRect.top,
        innerRect.width / 2,
        innerRect.height,
      ),
      Paint()..color = leftColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        innerRect.left + innerRect.width / 2,
        innerRect.top,
        innerRect.width / 2,
        innerRect.height,
      ),
      Paint()..color = rightColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        innerRect.left,
        innerRect.top,
        innerRect.width,
        innerRect.height / 2,
      ),
      Paint()..color = innerTopColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ColorSchemePreviewPainter oldDelegate) {
    return primary != oldDelegate.primary ||
        secondary != oldDelegate.secondary ||
        soft != oldDelegate.soft ||
        surface != oldDelegate.surface ||
        ring != oldDelegate.ring;
  }
}

class _SettingsChoice {
  const _SettingsChoice(this.label, this.description, {this.disabled = false});

  final String label;
  final String description;
  final bool disabled;
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.dividerFaint),
      ),
      child: Text(
        label,
        style: YnekoTypography.of(
          context,
        ).label.copyWith(color: tokens.ink, fontWeight: FontWeight.w800),
      ),
    );
  }
}

Future<void> _showChoiceDialog(
  BuildContext context, {
  required String title,
  required String value,
  required List<_SettingsChoice> options,
  required ValueChanged<String> onChanged,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (context) => _SettingsChoiceDialog(
      title: title,
      value: value,
      options: options,
      onChanged: (next) {
        onChanged(next);
        Navigator.of(context).pop();
      },
    ),
  );
}

class _SettingsChoiceDialog extends StatelessWidget {
  const _SettingsChoiceDialog({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<_SettingsChoice> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 560,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.52)),
          boxShadow: tokens.shadowStrong,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: type.sectionTitle)),
                YnekoIconActionButton(
                  tooltip: '关闭$title',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  transparent: true,
                  size: 34,
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SettingsChoiceTile(
                  option: option,
                  active: option.label == value,
                  onTap: option.disabled ? null : () => onChanged(option.label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsChoiceTile extends StatelessWidget {
  const _SettingsChoiceTile({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final _SettingsChoice option;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Opacity(
      opacity: option.disabled ? 0.58 : 1,
      child: YnekoPressable(
        onTap: onTap,
        borderRadius: 12,
        scaleOnPress: false,
        builder: (context, hovered, pressed) {
          final highlighted = active || hovered || pressed;
          return AnimatedContainer(
            duration: YnekoThemeTokens.fastMotion,
            constraints: const BoxConstraints(minHeight: 74),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: active
                  ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.38)
                  : Color.lerp(tokens.surfaceLow, tokens.surface, 0.28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? tokens.primary.withValues(alpha: 0.58)
                    : highlighted
                    ? Color.lerp(tokens.outline, tokens.primary, 0.32)!
                    : tokens.outline.withValues(alpha: 0.58),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: YnekoTypography.of(context).controlTitle,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        option.description,
                        overflow: TextOverflow.ellipsis,
                        style: YnekoTypography.of(
                          context,
                        ).label.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: active
                      ? Icon(
                          Icons.check_rounded,
                          color: tokens.primary,
                          size: 20,
                        )
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _downloadDefaultPath = '~/Downloads/Yneko';
const _downloadCustomTemplateDefault = '{title}/S{season}E{episode}';
const _downloadTemplateOptions = [
  _DownloadTemplateOption(
    label: '番剧名/集数',
    value: 'folderEpisode',
    template: '{title}/S{season}E{episode}',
  ),
  _DownloadTemplateOption(
    label: '番剧名 - S01E01',
    value: 'sxe',
    template: '{title} - S{season}E{episode}',
  ),
  _DownloadTemplateOption(
    label: '番剧名/季度/集数',
    value: 'seasonFolder',
    template: '{title}/S{season}/E{episode}',
  ),
  _DownloadTemplateOption(
    label: '自定义模板',
    value: 'custom',
    template: _downloadCustomTemplateDefault,
  ),
];

class _DownloadTemplateOption {
  const _DownloadTemplateOption({
    required this.label,
    required this.value,
    required this.template,
  });

  final String label;
  final String value;
  final String template;
}

String _downloadTemplatePreview(String value, String customTemplate) {
  final option = _downloadTemplateOptions.firstWhere(
    (option) => option.value == value,
    orElse: () => _downloadTemplateOptions.first,
  );
  final rawTemplate = value == 'custom'
      ? (customTemplate.trim().isEmpty
            ? _downloadCustomTemplateDefault
            : customTemplate)
      : option.template;
  final preview = rawTemplate
      .trim()
      .replaceAll('{title}', '葬送的芙莉莲')
      .replaceAll('{season}', '01')
      .replaceAll('{episode}', '01');
  final fallback = _downloadCustomTemplateDefault
      .replaceAll('{title}', '葬送的芙莉莲')
      .replaceAll('{season}', '01')
      .replaceAll('{episode}', '01');
  final normalized = preview.isEmpty ? fallback : preview;
  return normalized.endsWith('.mp4') ? normalized : '$normalized.mp4';
}

Future<void> _showDownloadPathDialog(
  BuildContext context, {
  required String value,
  required ValueChanged<String> onSave,
  required DirectoryPickerService directoryPicker,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (context) => _DownloadPathDialog(
      value: value,
      onSave: onSave,
      directoryPicker: directoryPicker,
    ),
  );
}

class _DownloadPathDialog extends StatefulWidget {
  const _DownloadPathDialog({
    required this.value,
    required this.onSave,
    required this.directoryPicker,
  });

  final String value;
  final ValueChanged<String> onSave;
  final DirectoryPickerService directoryPicker;

  @override
  State<_DownloadPathDialog> createState() => _DownloadPathDialogState();
}

class _DownloadPathDialogState extends State<_DownloadPathDialog> {
  late final TextEditingController _controller;
  final _inputFocusNode = FocusNode();
  String _pickerMessage = '';
  bool _selectingDirectory = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _save() {
    final path = _controller.text.trim();
    widget.onSave(path.isEmpty ? _downloadDefaultPath : path);
    Navigator.of(context).pop();
  }

  Future<void> _chooseCustomPath() async {
    setState(() {
      _pickerMessage = '';
      _selectingDirectory = true;
    });
    try {
      final selected = await widget.directoryPicker.pickDirectory(
        initialDirectory: _defaultPathForPicker(_controller.text),
      );
      if (!mounted) return;
      if (selected != null) {
        _controller.text = selected;
      } else {
        _inputFocusNode.requestFocus();
      }
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _pickerMessage = '桌面端会打开文件夹选择器，当前预览环境可手动输入路径。';
      });
      _inputFocusNode.requestFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pickerMessage = '未能打开文件夹选择器，可先手动输入路径。';
      });
      _inputFocusNode.requestFocus();
    } finally {
      if (mounted) {
        setState(() => _selectingDirectory = false);
      }
    }
  }

  String? _defaultPathForPicker(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed.startsWith('~')) return null;
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 560,
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.52)),
          boxShadow: tokens.shadowStrong,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DialogHeader(title: '下载路径'),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _DialogOptionCard(
                    title: '系统下载目录',
                    description: '使用系统常用下载位置',
                    minHeight: 72,
                    onTap: () {
                      setState(() => _pickerMessage = '');
                      _controller.text = '~/Downloads';
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogOptionCard(
                    title: 'Yneko 默认目录',
                    description: '按应用独立归档',
                    minHeight: 72,
                    onTap: () {
                      setState(() => _pickerMessage = '');
                      _controller.text = _downloadDefaultPath;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogOptionCard(
                    title: _selectingDirectory ? '正在打开...' : '自定义路径',
                    description: '在下方输入保存位置',
                    minHeight: 72,
                    onTap: _chooseCustomPath,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DialogTextField(
              label: '保存位置',
              controller: _controller,
              focusNode: _inputFocusNode,
              autofocus: true,
              hintText: _downloadDefaultPath,
              onChanged: () {
                if (_pickerMessage.isNotEmpty) {
                  setState(() => _pickerMessage = '');
                }
              },
              onSubmitted: _save,
            ),
            if (_pickerMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _pickerMessage,
                style: type.label.copyWith(
                  color: tokens.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _DialogActionButton(
                  label: '取消',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                _DialogActionButton(
                  label: '保存',
                  primary: true,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showNamingTemplateDialog(
  BuildContext context, {
  required String value,
  required String customTemplate,
  required ValueChanged<String> onSave,
  required ValueChanged<String> onSaveCustomTemplate,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (context) => _NamingTemplateDialog(
      value: value,
      customTemplate: customTemplate,
      onSave: onSave,
      onSaveCustomTemplate: onSaveCustomTemplate,
    ),
  );
}

class _NamingTemplateDialog extends StatefulWidget {
  const _NamingTemplateDialog({
    required this.value,
    required this.customTemplate,
    required this.onSave,
    required this.onSaveCustomTemplate,
  });

  final String value;
  final String customTemplate;
  final ValueChanged<String> onSave;
  final ValueChanged<String> onSaveCustomTemplate;

  @override
  State<_NamingTemplateDialog> createState() => _NamingTemplateDialogState();
}

class _NamingTemplateDialogState extends State<_NamingTemplateDialog> {
  late String _draftTemplate;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _draftTemplate = widget.value;
    _customController = TextEditingController(text: widget.customTemplate);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _saveCustomTemplate() {
    final custom = _customController.text.trim().isEmpty
        ? _downloadCustomTemplateDefault
        : _customController.text;
    widget.onSave('custom');
    widget.onSaveCustomTemplate(custom);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final preview = _downloadTemplatePreview(
      _draftTemplate,
      _customController.text,
    );
    final showingCustom = _draftTemplate == 'custom';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 680,
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.52)),
          boxShadow: tokens.shadowStrong,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DialogHeader(title: '命名规范'),
            const SizedBox(height: 28),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 4.5,
              children: [
                for (final option in _downloadTemplateOptions)
                  _DialogOptionCard(
                    title: option.label,
                    description: _downloadTemplatePreview(
                      option.value,
                      _customController.text,
                    ),
                    active: option.value == _draftTemplate,
                    minHeight: 76,
                    onTap: () {
                      if (option.value == 'custom') {
                        setState(() => _draftTemplate = 'custom');
                      } else {
                        widget.onSave(option.value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
            if (showingCustom) ...[
              const SizedBox(height: 18),
              _DialogTextField(
                label: '自定义模板',
                controller: _customController,
                hintText: _downloadCustomTemplateDefault,
                onSubmitted: _saveCustomTemplate,
                onChanged: () => setState(() {}),
              ),
            ],
            const SizedBox(height: 18),
            _PreviewStrip(preview: preview),
            if (showingCustom) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _DialogActionButton(
                    label: '取消',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  _DialogActionButton(
                    label: '保存',
                    primary: true,
                    onPressed: _saveCustomTemplate,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: YnekoTypography.of(
              context,
            ).sectionTitle.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
        YnekoIconActionButton(
          tooltip: '关闭$title',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          transparent: true,
          size: 34,
        ),
      ],
    );
  }
}

class _DialogOptionCard extends StatelessWidget {
  const _DialogOptionCard({
    required this.title,
    required this.description,
    required this.onTap,
    this.active = false,
    this.minHeight = 72,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final bool active;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPressable(
      onTap: onTap,
      borderRadius: 8,
      scaleOnPress: false,
      builder: (context, hovered, pressed) {
        final highlighted = active || hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.38)
                : Color.lerp(tokens.surfaceLow, tokens.surface, 0.22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? tokens.primary.withValues(alpha: 0.48)
                  : highlighted
                  ? Color.lerp(tokens.outline, tokens.primary, 0.32)!
                  : tokens.outline.withValues(alpha: 0.62),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: YnekoTypography.of(context).controlTitle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                overflow: TextOverflow.ellipsis,
                style: YnekoTypography.of(context).label.copyWith(
                  color: tokens.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSubmitted;
  final VoidCallback onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: YnekoTypography.of(
            context,
          ).label.copyWith(color: tokens.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            decoration: InputDecoration(hintText: hintText),
            style: YnekoTypography.of(
              context,
            ).body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmitted(),
          ),
        ),
      ],
    );
  }
}

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({required this.preview});

  final String preview;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: Color.lerp(tokens.surfaceLow, tokens.surface, 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '预览',
            style: YnekoTypography.of(
              context,
            ).label.copyWith(color: tokens.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            preview,
            overflow: TextOverflow.ellipsis,
            style: YnekoTypography.of(
              context,
            ).controlTitle.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPressable(
      onTap: onPressed,
      borderRadius: 8,
      scaleOnPress: false,
      builder: (context, hovered, pressed) {
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          height: 34,
          constraints: const BoxConstraints(minWidth: 72),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: primary
                ? tokens.primary
                : (hovered || pressed ? tokens.surfaceHigh : tokens.surface),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: primary
                  ? tokens.primary
                  : tokens.outline.withValues(alpha: 0.72),
            ),
          ),
          child: Text(
            label,
            style: YnekoTypography.of(context).label.copyWith(
              color: primary ? Colors.white : tokens.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        );
      },
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
          YnekoIconActionButton(
            tooltip: '减少',
            onPressed: () => onChanged(value - 1),
            icon: const Icon(Icons.remove_rounded, size: 16),
            tone: YnekoActionButtonTone.ghost,
            transparent: true,
            size: 30,
            iconSize: 16,
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
          YnekoIconActionButton(
            tooltip: '增加',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded, size: 16),
            tone: YnekoActionButtonTone.ghost,
            transparent: true,
            size: 30,
            iconSize: 16,
          ),
        ],
      ),
    );
  }
}
