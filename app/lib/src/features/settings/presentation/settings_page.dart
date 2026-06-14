import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_navigation_controller.dart';
import '../../shell/index.dart';
import '../../sources/index.dart';
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
  String _downloadStrategy = '自动';
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
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: radius,
        border: Border.all(color: tokens.outline.withValues(alpha: 0.54)),
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
    final showContentTitle = panel != SettingsPanel.rules;
    return ListView(
      key: ValueKey('settings-detail-${panel.name}'),
      padding: EdgeInsets.fromLTRB(28, showContentTitle ? 24 : 28, 28, 48),
      children: [
        if (showContentTitle) ...[
          Text(
            _panelTitle(panel),
            style: YnekoTypography.of(context).pageTitle,
          ),
          const SizedBox(height: 20),
        ],
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
    final themeMode = ref.watch(shellThemeModeProvider);
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
                value: themeMode == ThemeMode.dark ? '深色' : '浅色',
                onChanged: (value) => ref
                    .read(shellThemeModeProvider.notifier)
                    .setMode(value == '深色' ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
            _SettingsControlRow(
              icon: Icons.auto_awesome_rounded,
              title: '配色方案',
              description: colorScheme,
              onTap: () => _showColorSchemeDialog(
                context,
                value: colorScheme,
                onChanged: onColorScheme,
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
        _SettingsDetailGroup(
          title: '下载位置',
          children: [
            _SettingsControlRow(
              icon: Icons.folder_open_rounded,
              title: '下载路径',
              description: path,
              trailing: _RuleActionButtonShell(
                label: '修改',
                onPressed: () => _showTextSettingDialog(
                  context,
                  title: '下载路径',
                  initialValue: path,
                  onSubmitted: onPath,
                ),
              ),
            ),
          ],
        ),
        _SettingsDetailGroup(
          title: '下载任务',
          children: [
            _SettingsControlRow(
              icon: Icons.format_list_numbered_rounded,
              title: '并发任务',
              description: '限制同时下载的任务数量。',
              trailing: _Stepper(value: concurrency, onChanged: onConcurrency),
            ),
            _SettingsControlRow(
              icon: Icons.rule_rounded,
              title: '下载策略',
              description: strategy,
              trailing: _ChoicePill(label: strategy),
              onTap: () => _showChoiceDialog(
                context,
                title: '下载策略',
                value: strategy,
                options: const [
                  _SettingsChoice('自动', '按当前网络和片源状态自动选择。'),
                  _SettingsChoice('仅 Wi-Fi', '预留移动端网络策略。'),
                  _SettingsChoice('手动确认', '每次下载前显示确认提示。'),
                ],
                onChanged: onStrategy,
              ),
            ),
            const _SettingsControlRow(
              icon: Icons.text_snippet_outlined,
              title: '命名模板',
              description: '{title}/S01E{episode} - {episodeTitle}',
            ),
          ],
        ),
        const _HintPanel(text: '下载与离线缓存不在 V1 范围内，本页先保留完整设置入口。'),
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
        child: SizedBox(height: 180, child: Center(child: YnekoRingLoader())),
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

class _ColorSchemeOption {
  const _ColorSchemeOption(this.label, this.colors);

  final String label;
  final List<Color> colors;
}

const _colorSchemeOptions = [
  _ColorSchemeOption('Yneko 粉', [
    Color(0xFFFF6699),
    Color(0xFF00A1D6),
    Color(0xFFFFF0F5),
  ]),
  _ColorSchemeOption('清爽蓝', [
    Color(0xFF2F8AF5),
    Color(0xFFEDF6FF),
    Color(0xFFF8FBFF),
  ]),
  _ColorSchemeOption('经典灰', [
    Color(0xFF6C727A),
    Color(0xFFEDEFF2),
    Color(0xFFFBFBFC),
  ]),
  _ColorSchemeOption('薄荷绿', [
    Color(0xFF16A085),
    Color(0xFFEDF9F5),
    Color(0xFFFBFFFD),
  ]),
  _ColorSchemeOption('云杉青', [
    Color(0xFF0F8B8D),
    Color(0xFFEDF8F8),
    Color(0xFFF9FDFD),
  ]),
  _ColorSchemeOption('晨雾紫', [
    Color(0xFF7C6BD8),
    Color(0xFFF2F0FF),
    Color(0xFFFCFBFF),
  ]),
  _ColorSchemeOption('暖杏白', [
    Color(0xFFD9824B),
    Color(0xFFFFF4EB),
    Color(0xFFFFFDF9),
  ]),
];

Future<void> _showColorSchemeDialog(
  BuildContext context, {
  required String value,
  required ValueChanged<String> onChanged,
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

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 820,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final option in _colorSchemeOptions)
                  _ColorSchemeOptionTile(
                    option: option,
                    active: option.label == value,
                    onTap: () => onChanged(option.label),
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

  final _ColorSchemeOption option;
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
        return AnimatedScale(
          key: ValueKey('settings-color-scheme-option-${option.label}'),
          duration: YnekoThemeTokens.fastMotion,
          curve: Curves.easeOutCubic,
          scale: pressed
              ? 0.97
              : hovered
              ? 1.03
              : 1,
          child: SizedBox(
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
                            if (active || hovered)
                              BoxShadow(
                                color: option.colors.first.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                          ],
                        ),
                        child: CustomPaint(
                          size: const Size.square(58),
                          painter: _ColorSchemePreviewPainter(
                            primary: option.colors[0],
                            secondary: option.colors[1],
                            soft: option.colors[2],
                            ring: Color.lerp(
                              tokens.surface,
                              Colors.transparent,
                              0.22,
                            )!,
                          ),
                        ),
                      ),
                      if (active)
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              option.colors.first,
                              Colors.black,
                              0.28,
                            ),
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
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: YnekoTypography.of(context).label.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
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
    required this.ring,
  });

  final Color primary;
  final Color secondary;
  final Color soft;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect);
    canvas.save();
    canvas.clipPath(circle);

    final left = Rect.fromLTWH(0, 0, size.width / 2, size.height);
    final right = Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
    canvas.drawRect(left, Paint()..color = Color.lerp(primary, soft, 0.42)!);
    canvas.drawRect(
      right,
      Paint()..color = Color.lerp(secondary, primary, 0.22)!,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      Paint()..color = Color.lerp(soft, Colors.white, 0.18)!,
    );
    canvas.restore();

    canvas.drawCircle(
      rect.center,
      size.width / 2 - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorSchemePreviewPainter oldDelegate) {
    return primary != oldDelegate.primary ||
        secondary != oldDelegate.secondary ||
        soft != oldDelegate.soft ||
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

Future<void> _showTextSettingDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  required ValueChanged<String> onSubmitted,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        width: 540,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: YnekoThemeTokens.of(context).surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: YnekoThemeTokens.of(context).outline.withValues(alpha: 0.52),
          ),
          boxShadow: YnekoThemeTokens.of(context).shadowStrong,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: YnekoTypography.of(context).sectionTitle),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: title),
              onSubmitted: (value) {
                onSubmitted(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RuleActionButtonShell(
                  label: '取消',
                  onPressed: () => Navigator.of(context).pop(),
                  ghost: true,
                ),
                const SizedBox(width: 10),
                _RuleActionButtonShell(
                  label: '保存',
                  onPressed: () {
                    onSubmitted(controller.text);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RuleActionButtonShell extends StatelessWidget {
  const _RuleActionButtonShell({
    required this.label,
    required this.onPressed,
    this.ghost = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return YnekoActionButton(
      label: label,
      onPressed: onPressed,
      tone: ghost ? YnekoActionButtonTone.ghost : YnekoActionButtonTone.outline,
      height: 34,
      minWidth: 64,
      borderRadius: 8,
      horizontalPadding: 12,
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
