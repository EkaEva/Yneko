import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/source_packages_controller.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(sourceLibraryControllerProvider);
    return ListView(
      key: const ValueKey('sources-page'),
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 48),
      children: [
        _SourcesHeader(onImport: () => showRuleSourceEditor(context, ref)),
        const SizedBox(height: 18),
        library.when(
          loading: () => const _SourceLoadingPanel(),
          error: (error, stackTrace) => SourceLibraryView(
            state: const SourceLibraryState(),
            warning: error.toString(),
          ),
          data: (state) => SourceLibraryView(state: state),
        ),
      ],
    );
  }
}

class SourceLibraryView extends StatelessWidget {
  const SourceLibraryView({super.key, required this.state, this.warning});

  final SourceLibraryState state;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (warning != null) ...[
          _SourceWarningPanel(message: warning!),
          const SizedBox(height: 18),
        ],
        RuleGroupsSection(state: state),
        const SizedBox(height: 22),
        const PluginLibrarySection(),
      ],
    );
  }
}

class _SourcesHeader extends StatelessWidget {
  const _SourcesHeader({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final type = YnekoTypography.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('规则源', style: type.pageTitle),
              const SizedBox(height: 5),
              Text(
                '规则组、仓库订阅、搜索候选与播放解析。',
                style: type.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        _RuleActionButton(
          key: const ValueKey('source-import-open'),
          onPressed: onImport,
          icon: const Icon(Icons.add_rounded),
          label: '新增规则源',
          tone: _RuleActionButtonTone.primary,
        ),
      ],
    );
  }
}

class RuleGroupsSection extends ConsumerWidget {
  const RuleGroupsSection({super.key, required this.state});

  final SourceLibraryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsLikeGroup(
      title: '规则组',
      children: [
        for (final group in state.visibleGroups)
          RuleGroupRow(group: group, packages: state.packages),
        _ListAction(
          key: const ValueKey('rule-group-create-open'),
          icon: Icons.add_rounded,
          title: '新增规则组',
          description: '创建自建规则组，并在内部添加规则源。',
          onTap: () => showRuleGroupNameDialog(context, ref),
        ),
      ],
    );
  }
}

class PluginLibrarySection extends StatelessWidget {
  const PluginLibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsLikeGroup(
      title: '插件库',
      children: [
        _StaticRow(
          icon: Icons.archive_outlined,
          title: '采集插件组',
          description: '用于扩展搜索、详情与剧集采集能力。 当前 0 个插件。',
        ),
        _StaticRow(
          icon: Icons.archive_outlined,
          title: '播放插件组',
          description: '用于扩展解析、播放地址处理与播放前处理。 当前 0 个插件。',
        ),
        _StaticRow(
          icon: Icons.add_rounded,
          title: '新增插件组',
          description: '插件能力后续接入，这里先预留管理入口。',
        ),
      ],
    );
  }
}

class RuleGroupRow extends ConsumerWidget {
  const RuleGroupRow({super.key, required this.group, required this.packages});

  final RuleGroupSummary group;
  final List<SourcePackageSummary> packages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupPackages = packages
        .where((package) => group.ruleIds.contains(package.id))
        .toList();
    final enabled = group.enabledRuleCount(packages);
    return _ActionRow(
      key: ValueKey('rule-group-${group.id}'),
      icon: Icons.tune_rounded,
      title: group.name,
      description: groupPackages.isEmpty
          ? '暂无规则源，进入后添加自建规则源。'
          : '${groupPackages.length} 个规则源，$enabled 个已启用',
      trailing: YnekoSwitch(
        checked: group.enabled,
        onTap: () => ref
            .read(sourceLibraryControllerProvider.notifier)
            .saveGroup(group.copyWith(enabled: !group.enabled)),
      ),
      onTap: () => showRuleGroupDetailDialog(context, ref, group),
    );
  }
}

class SourcePackageList extends ConsumerWidget {
  const SourcePackageList({super.key, required this.packages});

  final List<SourcePackageSummary> packages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (packages.isEmpty) {
      return YnekoPanel(
        child: Column(
          children: [
            const YnekoEmptyState(
              icon: Icons.tune_rounded,
              title: '还没有规则源',
              description: '导入一个声明式规则包后，播放页会用它搜索候选与解析播放。',
            ),
            const SizedBox(height: 12),
            _RuleActionButton(
              onPressed: () => showRuleSourceEditor(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: '新增规则源',
              tone: _RuleActionButtonTone.primary,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final package in packages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SourcePackageCard(package: package),
          ),
      ],
    );
  }
}

class SourcePackageCard extends ConsumerWidget {
  const SourcePackageCard({super.key, required this.package, this.group});

  final SourcePackageSummary package;
  final RuleGroupSummary? group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disabledInGroup =
        group?.disabledRuleIds.contains(package.id) ?? false;
    return _ActionRow(
      key: ValueKey('source-package-${package.id}'),
      icon: Icons.list_alt_rounded,
      title: package.name,
      description:
          '${package.id} · v${package.version} · ${package.sourceLabel}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceChip(text: package.format),
          const SizedBox(width: 8),
          _RuleIconButton(
            tooltip: '编辑',
            onPressed: () =>
                showRuleSourceEditor(context, ref, source: package),
            icon: const Icon(Icons.settings_rounded, size: 17),
          ),
          _RuleIconButton(
            tooltip: '删除规则源',
            onPressed: () => ref
                .read(sourceLibraryControllerProvider.notifier)
                .deletePackage(package.id),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            danger: true,
          ),
          YnekoSwitch(
            checked: group == null ? package.enabled : !disabledInGroup,
            onTap: () {
              final targetGroup = group;
              if (targetGroup == null) {
                ref
                    .read(sourceLibraryControllerProvider.notifier)
                    .setPackageEnabled(package.id, !package.enabled);
              } else {
                ref
                    .read(sourceLibraryControllerProvider.notifier)
                    .toggleRuleInGroup(group: targetGroup, ruleId: package.id);
              }
            },
          ),
        ],
      ),
      onTap: () => showRuleSourceEditor(context, ref, source: package),
    );
  }
}

Future<void> showRuleGroupNameDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: _RuleDialogFrame(
        maxWidth: 560,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '新增规则组',
                      style: YnekoTypography.of(context).sectionTitle,
                    ),
                  ),
                  _RuleIconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    transparent: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                key: const ValueKey('rule-group-name-field'),
                controller: controller,
                autofocus: true,
                decoration: _ruleInputDecoration(
                  context,
                  labelText: '规则组名称',
                  hintText: '例如：常用规则组',
                ),
                onSubmitted: (_) =>
                    _saveGroupName(context, ref, controller.text),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _RuleActionButton(
                    onPressed: () => Navigator.of(context).pop(),
                    label: '取消',
                    tone: _RuleActionButtonTone.ghost,
                  ),
                  const SizedBox(width: 10),
                  _RuleActionButton(
                    key: const ValueKey('rule-group-name-save'),
                    onPressed: () =>
                        _saveGroupName(context, ref, controller.text),
                    label: '保存',
                    tone: _RuleActionButtonTone.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _saveGroupName(BuildContext context, WidgetRef ref, String value) {
  ref.read(sourceLibraryControllerProvider.notifier).createGroup(value);
  Navigator.of(context).pop();
}

Future<void> showRuleGroupDetailDialog(
  BuildContext context,
  WidgetRef ref,
  RuleGroupSummary group,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _RuleGroupDetailDialog(groupId: group.id),
  );
}

class _RuleGroupDetailDialog extends ConsumerWidget {
  const _RuleGroupDetailDialog({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(sourceLibraryControllerProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: _RuleDialogFrame(
        maxWidth: 720,
        maxHeight: 860,
        child: library.when(
          loading: () => const SizedBox(
            height: 360,
            child: Center(child: YnekoRingLoader()),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.all(20),
            child: YnekoEmptyState(
              icon: Icons.error_outline_rounded,
              title: '规则组加载失败',
              description: error.toString(),
            ),
          ),
          data: (state) {
            final group = state.groups.firstWhere(
              (item) => item.id == groupId,
              orElse: () => state.defaultGroup,
            );
            final packages = state.packagesForGroup(group);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: YnekoTypography.of(context).sectionTitle,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              packages.isEmpty
                                  ? '暂无规则源'
                                  : '${packages.length} 个规则源',
                              style: YnekoTypography.of(context).meta,
                            ),
                          ],
                        ),
                      ),
                      if (group.id != defaultRuleGroupId)
                        _RuleIconButton(
                          tooltip: '删除规则组',
                          onPressed: () {
                            ref
                                .read(sourceLibraryControllerProvider.notifier)
                                .deleteGroup(group.id);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          danger: true,
                        ),
                      _RuleIconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        transparent: true,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                    child: _RuleListFrame(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (packages.isEmpty)
                            const _InlineEmpty(
                              icon: Icons.tune_rounded,
                              title: '还没有规则源',
                              description: '可以新增自建规则源，或从外部仓库导入。',
                            )
                          else
                            for (final package in packages)
                              SourcePackageCard(package: package, group: group),
                          _ListAction(
                            key: const ValueKey('rule-repository-import-open'),
                            icon: Icons.download_rounded,
                            title: '从外部导入',
                            description: '从已订阅的规则仓库选择规则源导入。',
                            onTap: () => showRuleRepositoryImportDialog(
                              context,
                              ref,
                              group,
                            ),
                          ),
                          _ListAction(
                            key: const ValueKey('rule-source-editor-open'),
                            icon: Icons.add_rounded,
                            title: '新增规则源',
                            description: '使用可视化编辑器填写规则变量。',
                            onTap: () => showRuleSourceEditor(
                              context,
                              ref,
                              groupId: group.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> showRuleSourceEditor(
  BuildContext context,
  WidgetRef ref, {
  SourcePackageSummary? source,
  String? groupId,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _RuleSourceEditorDialog(source: source, groupId: groupId),
  );
}

class _RuleSourceEditorDialog extends ConsumerStatefulWidget {
  const _RuleSourceEditorDialog({this.source, this.groupId});

  final SourcePackageSummary? source;
  final String? groupId;

  @override
  ConsumerState<_RuleSourceEditorDialog> createState() =>
      _RuleSourceEditorDialogState();
}

class _RuleSourceEditorDialogState
    extends ConsumerState<_RuleSourceEditorDialog> {
  String _mode = 'visual';
  bool _loading = false;
  bool _saving = false;
  String _message = '';
  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _version;
  late final TextEditingController _userAgent;
  late final TextEditingController _searchPath;
  late final TextEditingController _searchParam;
  late final TextEditingController _searchItem;
  late final TextEditingController _searchTitle;
  late final TextEditingController _searchUrl;
  late final TextEditingController _episodeItem;
  late final TextEditingController _episodeTitle;
  late final TextEditingController _episodeUrl;
  late final TextEditingController _episodeOrder;
  late final TextEditingController _iframeSelector;
  late final TextEditingController _streamRegex;
  late final TextEditingController _config;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    _id = TextEditingController(
      text:
          source?.id ??
          'custom-source-${DateTime.now().millisecondsSinceEpoch}',
    );
    _name = TextEditingController(text: source?.name ?? '自建规则源');
    _baseUrl = TextEditingController(text: 'https://example.com');
    _version = TextEditingController(text: source?.version ?? '1');
    _userAgent = TextEditingController();
    _searchPath = TextEditingController(text: '/search');
    _searchParam = TextEditingController(text: 'q');
    _searchItem = TextEditingController(text: '.result-item');
    _searchTitle = TextEditingController(text: '.title | text');
    _searchUrl = TextEditingController(text: '.title | attr:href | url');
    _episodeItem = TextEditingController(text: '.episode-list a');
    _episodeTitle = TextEditingController(text: 'text');
    _episodeUrl = TextEditingController(text: 'attr:href | url');
    _episodeOrder = TextEditingController(text: 'text');
    _iframeSelector = TextEditingController();
    _streamRegex = TextEditingController(
      text: r'''https?://[^"']+\.m3u8[^"']*''',
    );
    _config = TextEditingController(text: _visualYaml());
    if (source != null) {
      _loadSourceText(source.id);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
      _name,
      _baseUrl,
      _version,
      _userAgent,
      _searchPath,
      _searchParam,
      _searchItem,
      _searchTitle,
      _searchUrl,
      _episodeItem,
      _episodeTitle,
      _episodeUrl,
      _episodeOrder,
      _iframeSelector,
      _streamRegex,
      _config,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: _RuleDialogFrame(
        maxWidth: 920,
        maxHeight: 900,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.source == null ? '新增规则源' : '编辑规则源',
                          style: YnekoTypography.of(context).sectionTitle,
                        ),
                        const SizedBox(height: 12),
                        YnekoSegmentedControl(
                          options: const ['visual', 'config'],
                          labels: const {'visual': '可视化', 'config': '配置文件'},
                          value: _mode,
                          onChanged: (value) {
                            if (value == 'config') _config.text = _visualYaml();
                            setState(() => _mode = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  _RuleIconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    transparent: true,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: YnekoRingLoader())
                  : _mode == 'visual'
                  ? _VisualRuleForm(
                      id: _id,
                      name: _name,
                      baseUrl: _baseUrl,
                      version: _version,
                      userAgent: _userAgent,
                      searchPath: _searchPath,
                      searchParam: _searchParam,
                      searchItem: _searchItem,
                      searchTitle: _searchTitle,
                      searchUrl: _searchUrl,
                      episodeItem: _episodeItem,
                      episodeTitle: _episodeTitle,
                      episodeUrl: _episodeUrl,
                      episodeOrder: _episodeOrder,
                      iframeSelector: _iframeSelector,
                      streamRegex: _streamRegex,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: TextField(
                        key: const ValueKey('rule-source-config-field'),
                        controller: _config,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        spellCheckConfiguration:
                            const SpellCheckConfiguration.disabled(),
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 12,
                          height: 1.45,
                        ),
                        decoration: _ruleInputDecoration(
                          context,
                          hintText: '直接编辑 YAML / JSON 规则源配置',
                        ),
                      ),
                    ),
            ),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _message,
                    style: YnekoTypography.of(context).meta,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _RuleActionButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    label: '取消',
                    tone: _RuleActionButtonTone.ghost,
                  ),
                  const SizedBox(width: 10),
                  _RuleActionButton(
                    key: const ValueKey('rule-source-editor-save'),
                    onPressed: _saving ? null : _save,
                    label: _saving ? '保存中' : '保存',
                    tone: _RuleActionButtonTone.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSourceText(String id) async {
    setState(() => _loading = true);
    try {
      final text = await ref
          .read(sourceLibraryControllerProvider.notifier)
          .getPackageText(id);
      if (!mounted || text == null) return;
      _config.text = text.body;
      _mode = 'config';
    } catch (error) {
      if (mounted) _message = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = '';
    });
    try {
      final body = _mode == 'config' ? _config.text : _visualYaml();
      await ref
          .read(sourceLibraryControllerProvider.notifier)
          .importText(body, groupId: widget.groupId);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _visualYaml() {
    final userAgent = _userAgent.text.trim();
    final iframe = _iframeSelector.text.trim();
    return '''
id: "${_id.text.trim()}"
name: "${_name.text.trim()}"
version: "${_version.text.trim().isEmpty ? '1' : _version.text.trim()}"
base_url: "${_baseUrl.text.trim()}"
request:
  user_agent: "${userAgent.isEmpty ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' : userAgent}"
  timeout_ms: 10000
  rate_limit_per_minute: 120
search:
  path: "${_searchPath.text.trim()}"
  query:
    ${_searchParam.text.trim().isEmpty ? 'q' : _searchParam.text.trim()}: "{{keyword}}"
  item_selector: "${_searchItem.text.trim()}"
  fields:
    title: "${_searchTitle.text.trim()}"
    url: "${_searchUrl.text.trim()}"
    source_item_key: "${_searchUrl.text.trim()}"
episodes:
  item_selector: "${_episodeItem.text.trim()}"
  fields:
    title: "${_episodeTitle.text.trim()}"
    url: "${_episodeUrl.text.trim()}"
    source_episode_key: "${_episodeUrl.text.trim()}"
    order: "${_episodeOrder.text.trim()}"
play:
${iframe.isEmpty ? '' : '  iframe_selector: "$iframe"\n'}  stream_patterns:
    - type: "hls"
      regex: "${_streamRegex.text.trim().replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"
''';
  }
}

class _VisualRuleForm extends StatelessWidget {
  const _VisualRuleForm({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.version,
    required this.userAgent,
    required this.searchPath,
    required this.searchParam,
    required this.searchItem,
    required this.searchTitle,
    required this.searchUrl,
    required this.episodeItem,
    required this.episodeTitle,
    required this.episodeUrl,
    required this.episodeOrder,
    required this.iframeSelector,
    required this.streamRegex,
  });

  final TextEditingController id;
  final TextEditingController name;
  final TextEditingController baseUrl;
  final TextEditingController version;
  final TextEditingController userAgent;
  final TextEditingController searchPath;
  final TextEditingController searchParam;
  final TextEditingController searchItem;
  final TextEditingController searchTitle;
  final TextEditingController searchUrl;
  final TextEditingController episodeItem;
  final TextEditingController episodeTitle;
  final TextEditingController episodeUrl;
  final TextEditingController episodeOrder;
  final TextEditingController iframeSelector;
  final TextEditingController streamRegex;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      children: [
        _FormSection(
          title: '基础信息',
          children: [
            _FormField(label: '规则 ID', controller: id),
            _FormField(label: '规则名称', controller: name),
            _FormField(label: '站点地址', controller: baseUrl),
            _FormField(label: '版本号', controller: version),
          ],
        ),
        _FormSection(
          title: '请求设置',
          children: [_FormField(label: 'User-Agent', controller: userAgent)],
        ),
        _FormSection(
          title: '搜索规则',
          children: [
            _FormField(label: '搜索路径', controller: searchPath),
            _FormField(label: '关键词参数名', controller: searchParam),
            _FormField(label: '结果项选择器', controller: searchItem),
            _FormField(label: '标题字段', controller: searchTitle),
            _FormField(label: '详情链接字段', controller: searchUrl),
          ],
        ),
        _FormSection(
          title: '剧集规则',
          children: [
            _FormField(label: '剧集项选择器', controller: episodeItem),
            _FormField(label: '剧集标题字段', controller: episodeTitle),
            _FormField(label: '剧集链接字段', controller: episodeUrl),
            _FormField(label: '集数排序字段', controller: episodeOrder),
          ],
        ),
        _FormSection(
          title: '播放规则',
          children: [
            _FormField(label: 'iframe 选择器', controller: iframeSelector),
            _FormField(label: '视频流匹配表达式', controller: streamRegex),
          ],
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.lerp(tokens.surface, tokens.surfaceLow, 0.45),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.52)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: YnekoTypography.of(context).controlTitle),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: children),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      child: TextField(
        controller: controller,
        decoration: _ruleInputDecoration(context, labelText: label),
      ),
    );
  }
}

InputDecoration _ruleInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  bool compact = false,
}) {
  final tokens = YnekoThemeTokens.of(context);
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    prefixIconConstraints: compact
        ? const BoxConstraints.tightFor(width: 34, height: 38)
        : null,
    filled: true,
    fillColor: tokens.surface,
    hoverColor: tokens.surface,
    contentPadding: EdgeInsets.symmetric(
      horizontal: compact ? 12 : 14,
      vertical: compact ? 10 : 14,
    ),
    border: border(tokens.outline.withValues(alpha: 0.66)),
    enabledBorder: border(tokens.outline.withValues(alpha: 0.66)),
    focusedBorder: border(tokens.primary.withValues(alpha: 0.64), 1.2),
    errorBorder: border(tokens.danger.withValues(alpha: 0.74)),
    focusedErrorBorder: border(tokens.danger, 1.2),
  );
}

Future<void> showRuleRepositoryImportDialog(
  BuildContext context,
  WidgetRef ref,
  RuleGroupSummary group,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _RuleRepositoryImportDialog(group: group),
  );
}

class _RuleRepositoryImportDialog extends ConsumerStatefulWidget {
  const _RuleRepositoryImportDialog({required this.group});

  final RuleGroupSummary group;

  @override
  ConsumerState<_RuleRepositoryImportDialog> createState() =>
      _RuleRepositoryImportDialogState();
}

class _RuleRepositoryImportDialogState
    extends ConsumerState<_RuleRepositoryImportDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _query = TextEditingController();
  List<RuleRepositoryIndexEntry> _entries = const [];
  final Set<String> _selected = {};
  bool _loading = false;
  bool _importing = false;
  String _message = '';
  String? _selectedSubscriptionId = defaultRuleRepositorySubscription.id;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(sourceLibraryControllerProvider).value;
    final subscriptions =
        library?.visibleSubscriptions ??
        const [defaultRuleRepositorySubscription];
    final subscription = subscriptions.firstWhere(
      (item) => item.id == _selectedSubscriptionId,
      orElse: () => subscriptions.isEmpty
          ? const RuleRepositorySubscription(
              id: '',
              name: '暂无订阅',
              url: '',
              enabled: false,
              updatedAtMs: 0,
            )
          : subscriptions.first,
    );
    final filtered = _entries
        .where(
          (entry) => entry.name.toLowerCase().contains(
            _query.text.trim().toLowerCase(),
          ),
        )
        .toList();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: _RuleDialogFrame(
        maxWidth: 900,
        maxHeight: 820,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 24, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '从外部导入',
                          style: YnekoTypography.of(context).sectionTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '从规则仓库选择 JSON 规则源导入到当前规则组。',
                          style: YnekoTypography.of(
                            context,
                          ).label.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  _RuleIconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    transparent: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
              child: Column(
                children: [
                  _RepositorySubscribePanel(
                    name: _name,
                    url: _url,
                    canDelete:
                        subscription.id.isNotEmpty &&
                        subscription.id != defaultRuleRepositorySubscription.id,
                    onAdd: _addSubscription,
                    onDelete: () => _deleteSubscription(subscription),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 236,
                        child: _RepositorySubscriptionDropdown(
                          subscriptions: subscriptions,
                          value: subscription.id.isEmpty
                              ? defaultRuleRepositorySubscription.id
                              : subscription.id,
                          onChanged: (value) => setState(() {
                            _selectedSubscriptionId = value;
                            _entries = const [];
                            _selected.clear();
                            _message = '';
                          }),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _query,
                            style: YnekoTypography.of(context).label.copyWith(
                              color: YnekoThemeTokens.of(context).ink,
                              fontWeight: FontWeight.w700,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: _ruleInputDecoration(
                              context,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                              ),
                              hintText: '搜索规则源',
                              compact: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        key: const ValueKey('rule-repository-refresh-slot'),
                        width: 104,
                        height: 40,
                        child: _MiniActionButton(
                          key: const ValueKey('rule-repository-refresh-button'),
                          onPressed: _loading || subscription.url.isEmpty
                              ? null
                              : () => _refresh(subscription),
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: _loading ? '刷新中' : '刷新',
                          minWidth: 104,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _RepositoryToolsBar(
                    message: _message.isEmpty
                        ? (_entries.isEmpty
                              ? '刷新订阅后读取规则源。'
                              : '已读取 ${_entries.length} 个规则源。')
                        : _message,
                    selectedCount: _selected.length,
                    canSelect: filtered.isNotEmpty,
                    onSelectAll: () => setState(
                      () =>
                          _selected.addAll(filtered.map((entry) => entry.name)),
                    ),
                    onClear: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: _RuleListFrame(
                  child: filtered.isEmpty
                      ? _InlineEmpty(
                          icon: Icons.download_rounded,
                          title: _loading ? '正在读取规则仓库...' : '刷新订阅后选择要导入的规则源。',
                          description:
                              subscription.id ==
                                  defaultRuleRepositorySubscription.id
                              ? '当前订阅：KazumiRules'
                              : '当前订阅：${subscription.name}',
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            final selected = _selected.contains(entry.name);
                            return _RepositoryEntryRow(
                              entry: entry,
                              selected: selected,
                              isLast: index == filtered.length - 1,
                              onTap: () => setState(() {
                                selected
                                    ? _selected.remove(entry.name)
                                    : _selected.add(entry.name);
                              }),
                            );
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _RuleActionButton(
                    onPressed: () => Navigator.of(context).pop(),
                    label: '关闭',
                    tone: _RuleActionButtonTone.ghost,
                  ),
                  const SizedBox(width: 10),
                  _RuleActionButton(
                    key: const ValueKey('rule-repository-import-submit'),
                    onPressed: _importing || _selected.isEmpty ? null : _import,
                    label: _importing
                        ? '导入中'
                        : '导入${_selected.isEmpty ? '' : ' ${_selected.length} 个'}',
                    tone: _RuleActionButtonTone.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSubscription() async {
    final name = _name.text.trim().isEmpty ? '外部规则仓库' : _name.text.trim();
    final url = _url.text.trim();
    if (url.isEmpty) return;
    final subscription = RuleRepositorySubscription(
      id: 'repo-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      url: url,
      enabled: true,
      updatedAtMs: 0,
    );
    await ref
        .read(sourceLibraryControllerProvider.notifier)
        .saveSubscription(subscription);
    setState(() {
      _selectedSubscriptionId = subscription.id;
      _name.clear();
      _url.clear();
      _message = '已添加订阅：$name';
    });
  }

  Future<void> _deleteSubscription(
    RuleRepositorySubscription subscription,
  ) async {
    if (subscription.id.isEmpty ||
        subscription.id == defaultRuleRepositorySubscription.id) {
      return;
    }
    await ref
        .read(sourceLibraryControllerProvider.notifier)
        .deleteSubscription(subscription.id);
    setState(() {
      _selectedSubscriptionId = defaultRuleRepositorySubscription.id;
      _entries = const [];
      _selected.clear();
      _message = '已删除订阅：${subscription.name}';
    });
  }

  Future<void> _refresh(RuleRepositorySubscription subscription) async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final entries = await ref
          .read(sourceLibraryControllerProvider.notifier)
          .loadRepositoryIndex(subscription);
      setState(() {
        _entries = entries;
        _selected.clear();
        _message = '已读取 ${entries.length} 个规则源。';
      });
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final controller = ref.read(sourceLibraryControllerProvider.notifier);
      for (final entry in _entries.where(
        (item) => _selected.contains(item.name),
      )) {
        await controller.importRepositoryRule(
          groupId: widget.group.id,
          entry: entry,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}

class _RepositorySubscribePanel extends StatelessWidget {
  const _RepositorySubscribePanel({
    required this.name,
    required this.url,
    required this.canDelete,
    required this.onAdd,
    required this.onDelete,
  });

  final TextEditingController name;
  final TextEditingController url;
  final bool canDelete;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.lerp(tokens.surfaceLow, tokens.surface, 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.44)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '添加订阅',
                  style: type.controlTitle.copyWith(fontSize: 14),
                ),
              ),
              Text(
                '支持 GitHub 仓库地址或 raw index.json。',
                overflow: TextOverflow.ellipsis,
                style: type.label.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: name,
                    style: type.label.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _ruleInputDecoration(
                      context,
                      hintText: '订阅名称',
                      compact: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: url,
                    style: type.label.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: _ruleInputDecoration(
                      context,
                      hintText: '仓库 URL',
                      compact: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _MiniActionButton(
                icon: Icons.add_rounded,
                label: '添加',
                onPressed: onAdd,
              ),
              const SizedBox(width: 8),
              _MiniActionButton(
                icon: Icons.delete_outline_rounded,
                label: '删除',
                onPressed: canDelete ? onDelete : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepositorySubscriptionDropdown extends StatelessWidget {
  const _RepositorySubscriptionDropdown({
    required this.subscriptions,
    required this.value,
    required this.onChanged,
  });

  final List<RuleRepositorySubscription> subscriptions;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '订阅',
          style: YnekoTypography.of(
            context,
          ).label.copyWith(fontWeight: FontWeight.w800, color: tokens.muted),
        ),
        const SizedBox(height: 6),
        YnekoHoverMenu<String>(
          key: const ValueKey('rule-repository-subscription-menu'),
          triggerKey: const ValueKey('rule-repository-subscription-trigger'),
          value: value,
          height: 40,
          optionMinWidth: 236,
          panelMaxWidth: 320,
          triggerFontSize: 13,
          optionFontSize: 13,
          leadingPadding: 14,
          trailingPadding: 10,
          items: [
            for (final item in subscriptions)
              YnekoHoverMenuItem(value: item.id, label: item.name),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RepositoryToolsBar extends StatelessWidget {
  const _RepositoryToolsBar({
    required this.message,
    required this.selectedCount,
    required this.canSelect,
    required this.onSelectAll,
    required this.onClear,
  });

  final String message;
  final int selectedCount;
  final bool canSelect;
  final VoidCallback onSelectAll;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
      decoration: BoxDecoration(
        color: Color.lerp(tokens.surfaceLow, tokens.surface, 0.52),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              style: type.label.copyWith(
                color: tokens.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _RuleToolbarTextButton(
            onPressed: canSelect ? onSelectAll : null,
            label: '全选',
          ),
          _RuleToolbarTextButton(onPressed: onClear, label: '取消全选'),
          Text(
            '已选 $selectedCount 个',
            style: type.label.copyWith(
              color: tokens.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    super.key,
    this.icon,
    required this.label,
    required this.onPressed,
    this.minWidth = 82,
  });

  final Object? icon;
  final String label;
  final VoidCallback? onPressed;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final leading = icon;
    final leadingWidget = leading is IconData
        ? Icon(leading, size: 17)
        : leading is Widget
        ? leading
        : null;
    return _RuleActionButton(
      onPressed: onPressed,
      icon: leadingWidget,
      label: label,
      tone: _RuleActionButtonTone.outlineAccent,
      height: 40,
      minWidth: minWidth,
      borderRadius: 22,
      horizontalPadding: 14,
    );
  }
}

enum _RuleActionButtonTone { primary, ghost, outlineAccent }

class _RuleActionButton extends StatefulWidget {
  const _RuleActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = _RuleActionButtonTone.outlineAccent,
    this.height = 34,
    this.minWidth = 72,
    this.borderRadius = 8,
    this.horizontalPadding = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final _RuleActionButtonTone tone;
  final double height;
  final double minWidth;
  final double borderRadius;
  final double horizontalPadding;

  @override
  State<_RuleActionButton> createState() => _RuleActionButtonState();
}

class _RuleActionButtonState extends State<_RuleActionButton> {
  @override
  Widget build(BuildContext context) {
    return YnekoActionButton(
      key: widget.key,
      label: widget.label,
      onPressed: widget.onPressed,
      icon: widget.icon,
      tone: switch (widget.tone) {
        _RuleActionButtonTone.primary => YnekoActionButtonTone.primary,
        _RuleActionButtonTone.ghost => YnekoActionButtonTone.ghost,
        _RuleActionButtonTone.outlineAccent => YnekoActionButtonTone.outline,
      },
      height: widget.height,
      minWidth: widget.minWidth,
      borderRadius: widget.borderRadius,
      horizontalPadding: widget.horizontalPadding,
    );
  }
}

class _RuleToolbarTextButton extends StatelessWidget {
  const _RuleToolbarTextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _RuleActionButton(
      label: label,
      onPressed: onPressed,
      tone: _RuleActionButtonTone.ghost,
      height: 30,
      minWidth: 44,
      borderRadius: 8,
      horizontalPadding: 8,
    );
  }
}

class _RuleIconButton extends StatefulWidget {
  const _RuleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.danger = false,
    this.transparent = false,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool danger;
  final bool transparent;

  @override
  State<_RuleIconButton> createState() => _RuleIconButtonState();
}

class _RuleIconButtonState extends State<_RuleIconButton> {
  @override
  Widget build(BuildContext context) {
    return YnekoIconActionButton(
      tooltip: widget.tooltip,
      onPressed: widget.onPressed,
      icon: widget.icon,
      tone: widget.danger
          ? YnekoActionButtonTone.danger
          : YnekoActionButtonTone.outline,
      size: widget.transparent ? 34 : 32,
      transparent: widget.transparent,
    );
  }
}

class _RepositoryEntryRow extends StatelessWidget {
  const _RepositoryEntryRow({
    required this.entry,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  final RuleRepositoryIndexEntry entry;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return YnekoPressable(
      onTap: onTap,
      builder: (context, hovered, pressed) {
        final highlighted = selected || hovered || pressed;
        return AnimatedContainer(
          duration: YnekoThemeTokens.fastMotion,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: highlighted
                ? Color.lerp(tokens.primaryContainer, tokens.surface, 0.48)
                : tokens.surface,
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.transparent : tokens.dividerFaint,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? tokens.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? Color.lerp(tokens.outline, tokens.primary, 0.52)!
                        : tokens.outline.withValues(alpha: 0.66),
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: tokens.primaryStrong,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: YnekoTypography.of(context).controlTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${entry.version}${entry.antiCrawlerEnabled ? ' · 反爬' : ''}',
                      style: YnekoTypography.of(context).meta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showSourceImportDialog(BuildContext context, WidgetRef ref) {
  return showRuleSourceEditor(context, ref);
}

class YnekoSwitch extends StatelessWidget {
  const YnekoSwitch({super.key, required this.checked, required this.onTap});

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

class YnekoSegmentedControl extends StatelessWidget {
  const YnekoSegmentedControl({
    super.key,
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final Map<String, String> labels;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    final selectedIndex = options.indexOf(value).clamp(0, options.length - 1);
    const itemWidth = 74.0;
    return Container(
      key: const ValueKey('source-editor-mode-segmented'),
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
              key: const ValueKey('source-editor-mode-thumb'),
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
                  _SegmentedModeItem(
                    key: ValueKey('source-editor-mode-$option'),
                    width: itemWidth,
                    height: 30,
                    label: labels[option] ?? option,
                    selected: option == value,
                    textStyle: type.label,
                    inkColor: tokens.ink,
                    mutedColor: tokens.muted,
                    primaryContainer: tokens.primaryContainer,
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

class _SegmentedModeItem extends StatefulWidget {
  const _SegmentedModeItem({
    super.key,
    required this.width,
    required this.height,
    required this.label,
    required this.selected,
    required this.textStyle,
    required this.inkColor,
    required this.mutedColor,
    required this.primaryContainer,
    required this.onTap,
  });

  final double width;
  final double height;
  final String label;
  final bool selected;
  final TextStyle textStyle;
  final Color inkColor;
  final Color mutedColor;
  final Color primaryContainer;
  final VoidCallback onTap;

  @override
  State<_SegmentedModeItem> createState() => _SegmentedModeItemState();
}

class _SegmentedModeItemState extends State<_SegmentedModeItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.selected || _hovered
        ? widget.inkColor
        : widget.mutedColor;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(
            child: Text(
              widget.label,
              style: widget.textStyle.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleDialogFrame extends StatelessWidget {
  const _RuleDialogFrame({
    required this.child,
    required this.maxWidth,
    this.maxHeight,
  });

  final Widget child;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tokens.outline.withValues(alpha: 0.48)),
          boxShadow: tokens.shadowStrong,
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
      ),
    );
  }
}

class _RuleListFrame extends StatelessWidget {
  const _RuleListFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.outline.withValues(alpha: 0.54)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final type = YnekoTypography.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.dividerFaint)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: tokens.primary, size: 34),
          const SizedBox(height: 12),
          Text(title, style: type.controlTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: type.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SettingsLikeGroup extends StatelessWidget {
  const _SettingsLikeGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    final radius = BorderRadius.circular(20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: YnekoTypography.of(
            context,
          ).controlTitle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: radius,
            border: Border.all(color: tokens.outline.withValues(alpha: 0.54)),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _BaseRow(
      icon: icon,
      title: title,
      description: description,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _BaseRow(icon: icon, title: title, description: description);
  }
}

class _ListAction extends StatelessWidget {
  const _ListAction({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseRow(
      icon: icon,
      title: title,
      description: description,
      onTap: onTap,
    );
  }
}

class _BaseRow extends StatelessWidget {
  const _BaseRow({
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
      onTap: onTap,
      borderRadius: 0,
      scaleOnPress: false,
      builder: (context, hovered, pressed) {
        final hoverBackground = Color.lerp(
          tokens.surfaceHigh,
          tokens.surface,
          pressed ? 0.04 : 0.12,
        )!;
        return AnimatedContainer(
          key: ValueKey('source-row-$title'),
          duration: YnekoThemeTokens.fastMotion,
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            color: hovered || pressed ? hoverBackground : tokens.surface,
            border: Border(bottom: BorderSide(color: tokens.dividerFaint)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Icon(icon, size: 21, color: tokens.ink),
              ),
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
                      style: type.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        );
      },
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = YnekoThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: YnekoTypography.of(context).label.copyWith(
          color: tokens.primaryStrong,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SourceLoadingPanel extends StatelessWidget {
  const _SourceLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const YnekoPanel(
      child: SizedBox(height: 180, child: Center(child: YnekoRingLoader())),
    );
  }
}

class _SourceWarningPanel extends StatelessWidget {
  const _SourceWarningPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return YnekoPanel(
      child: YnekoEmptyState(
        icon: Icons.error_outline_rounded,
        title: '规则源列表暂时不可用',
        description: message,
      ),
    );
  }
}
