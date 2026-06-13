import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/index.dart';
import '../application/search_providers.dart';
import '../../../shared/domain/index.dart';
import '../../../shared/mock/index.dart';
import '../../../shared/theme/index.dart';
import '../../../shared/ui/index.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final tokens = YnekoThemeTokens.of(context);
    final displayItems = query.trim().isEmpty ? mockAnimeCards : mockAnimeCards.reversed.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
      children: [
        YnekoSectionTitle(
          title: '搜索',
          subtitle: 'Bangumi-first 搜索入口，当前以静态结果预览最终体验',
          trailing: SizedBox(
            width: 360,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '输入关键词开始搜索',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final label in ['星轨', '治愈', '原创动画', '2026', '高分'])
              ActionChip(
                label: Text(label),
                onPressed: () => ref.read(searchQueryProvider.notifier).set(label),
                backgroundColor: tokens.surfaceHigh,
                side: BorderSide(color: tokens.outline.withValues(alpha: 0.48)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        results.when(
          data: (_) => _SearchResults(items: displayItems),
          loading: () => const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
          error: (error, stackTrace) => const YnekoPanel(
            child: YnekoEmptyState(
              icon: Icons.cloud_off_rounded,
              title: '真实后端尚未接入',
              description: '当前先展示 mock 搜索结果，FRB 接入后会替换这里的数据源。',
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.items});

  final List<UiAnimeCard> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1120 ? 5 : constraints.maxWidth > 820 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisSpacing: 28,
            childAspectRatio: 0.62,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return AnimePosterCard(
              item: item,
              onTap: () => ref.read(shellRouteProvider.notifier).openSubjectDetail(item.id),
            );
          },
        );
      },
    );
  }
}
