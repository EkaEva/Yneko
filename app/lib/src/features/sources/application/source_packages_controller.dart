import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/bridge/yneko_backend.dart';
import '../../../shared/domain/index.dart';

const defaultRuleGroupId = 'default';
const defaultRuleRepositorySubscription = RuleRepositorySubscription(
  id: 'kazumi-rules',
  name: 'KazumiRules',
  url: 'https://github.com/Predidit/KazumiRules',
  enabled: true,
  updatedAtMs: 0,
);

final sourceLibraryControllerProvider =
    AsyncNotifierProvider<SourceLibraryController, SourceLibraryState>(
      SourceLibraryController.new,
    );

final sourcePackagesControllerProvider =
    Provider<AsyncValue<List<SourcePackageSummary>>>((ref) {
      return ref.watch(
        sourceLibraryControllerProvider.select(
          (state) => state.whenData((library) => library.packages),
        ),
      );
    });

class SourceLibraryState {
  const SourceLibraryState({
    this.packages = const [],
    this.groups = const [],
    this.subscriptions = const [],
  });

  final List<SourcePackageSummary> packages;
  final List<RuleGroupSummary> groups;
  final List<RuleRepositorySubscription> subscriptions;

  List<RuleRepositorySubscription> get visibleSubscriptions {
    if (subscriptions.any(
      (item) => item.id == defaultRuleRepositorySubscription.id,
    )) {
      return subscriptions;
    }
    return [defaultRuleRepositorySubscription, ...subscriptions];
  }

  List<RuleGroupSummary> get visibleGroups {
    if (groups.any((group) => group.id == defaultRuleGroupId)) {
      return groups;
    }
    return [defaultGroup, ...groups];
  }

  RuleGroupSummary get defaultGroup {
    return groups.firstWhere(
      (group) => group.id == defaultRuleGroupId,
      orElse: () => RuleGroupSummary(
        id: defaultRuleGroupId,
        name: '默认规则组',
        enabled: true,
        ruleIds: packages.map((package) => package.id).toList(),
      ),
    );
  }

  List<SourcePackageSummary> packagesForGroup(RuleGroupSummary group) {
    final ids = group.ruleIds.toSet();
    return packages.where((package) => ids.contains(package.id)).toList();
  }

  List<String> enabledRuleIdsForGroup(String groupId) {
    final group = groups.firstWhere(
      (item) => item.id == groupId,
      orElse: () => defaultGroup,
    );
    if (!group.enabled) return const [];
    final packagesById = {for (final package in packages) package.id: package};
    return group.ruleIds
        .where((id) {
          final package = packagesById[id];
          return package != null &&
              package.enabled &&
              !group.disabledRuleIds.contains(id);
        })
        .toList(growable: false);
  }
}

class SourceLibraryController extends AsyncNotifier<SourceLibraryState> {
  @override
  Future<SourceLibraryState> build() {
    return _load();
  }

  Future<SourceImportResult> importText(String text, {String? groupId}) async {
    final result = await ref.read(ynekoBackendProvider).importSourceText(text);
    if (groupId != null) {
      await _addRuleToGroup(groupId, result.package.id);
    }
    state = await AsyncValue.guard(_load);
    return result;
  }

  Future<SourceImportResult> importUrl(String url, {String? groupId}) async {
    final result = await ref.read(ynekoBackendProvider).importSourceUrl(url);
    if (groupId != null) {
      await _addRuleToGroup(groupId, result.package.id);
    }
    state = await AsyncValue.guard(_load);
    return result;
  }

  Future<SourcePackageText?> getPackageText(String id) {
    return ref.read(ynekoBackendProvider).getSourcePackageText(id);
  }

  Future<void> setPackageEnabled(String id, bool enabled) async {
    state = await AsyncValue.guard(() async {
      await ref
          .read(ynekoBackendProvider)
          .setSourcePackageEnabled(id: id, enabled: enabled);
      return _load();
    });
  }

  Future<void> deletePackage(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(ynekoBackendProvider).deleteSourcePackage(id);
      return _load();
    });
  }

  Future<void> saveGroup(RuleGroupSummary group) async {
    state = await AsyncValue.guard(() async {
      await ref.read(ynekoBackendProvider).saveRuleGroup(group);
      return _load();
    });
  }

  Future<void> createGroup(String name) async {
    final id = 'group-${DateTime.now().millisecondsSinceEpoch}';
    await saveGroup(
      RuleGroupSummary(
        id: id,
        name: name.trim().isEmpty ? '自建规则组' : name.trim(),
        enabled: true,
      ),
    );
  }

  Future<void> deleteGroup(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(ynekoBackendProvider).deleteRuleGroup(id);
      return _load();
    });
  }

  Future<void> toggleRuleInGroup({
    required RuleGroupSummary group,
    required String ruleId,
  }) {
    final disabled = group.disabledRuleIds.contains(ruleId);
    return saveGroup(
      group.copyWith(
        disabledRuleIds: disabled
            ? group.disabledRuleIds.where((id) => id != ruleId).toList()
            : [...group.disabledRuleIds, ruleId],
      ),
    );
  }

  Future<void> saveSubscription(RuleRepositorySubscription subscription) async {
    state = await AsyncValue.guard(() async {
      await ref
          .read(ynekoBackendProvider)
          .saveRuleRepositorySubscription(subscription);
      return _load();
    });
  }

  Future<void> deleteSubscription(String id) async {
    state = await AsyncValue.guard(() async {
      await ref.read(ynekoBackendProvider).deleteRuleRepositorySubscription(id);
      return _load();
    });
  }

  Future<List<RuleRepositoryIndexEntry>> loadRepositoryIndex(
    RuleRepositorySubscription subscription,
  ) {
    return ref.read(ynekoBackendProvider).loadRuleRepositoryIndex(subscription);
  }

  Future<SourceImportResult> importRepositoryRule({
    required String groupId,
    required RuleRepositoryIndexEntry entry,
  }) async {
    final result = await ref
        .read(ynekoBackendProvider)
        .importRepositoryRule(groupId: groupId, entry: entry);
    state = await AsyncValue.guard(_load);
    return result;
  }

  Future<SourceLibraryState> _load() async {
    final backend = ref.read(ynekoBackendProvider);
    final packages = await backend.listSourcePackages();
    final groups = await backend.listRuleGroups();
    final subscriptions = await backend.listRuleRepositorySubscriptions();
    return SourceLibraryState(
      packages: packages,
      groups: groups,
      subscriptions: subscriptions,
    );
  }

  Future<void> _addRuleToGroup(String groupId, String ruleId) async {
    final current = state.value ?? await _load();
    final group = current.groups.firstWhere(
      (item) => item.id == groupId,
      orElse: () => current.defaultGroup,
    );
    await ref
        .read(ynekoBackendProvider)
        .saveRuleGroup(
          group.copyWith(
            ruleIds: {...group.ruleIds, ruleId}.toList(),
            disabledRuleIds: group.disabledRuleIds
                .where((id) => id != ruleId)
                .toList(),
          ),
        );
  }
}
