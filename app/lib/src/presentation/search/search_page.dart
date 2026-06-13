import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/backend_providers.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yneko', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: '搜索番剧',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: results.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('输入关键词开始 Bangumi-first 搜索'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.nameCn ?? item.name),
                      subtitle: item.summary == null ? null : Text(item.summary!),
                    );
                  },
                );
              },
              error: (error, stackTrace) => Center(child: Text(error.toString())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
