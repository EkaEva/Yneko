import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/index.dart';
import '../../../infrastructure/bridge/yneko_backend.dart';

final ynekoBackendProvider = Provider<YnekoBackend>((ref) {
  return const FrbYnekoBackend();
});

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) {
    state = value;
  }
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

final searchResultsProvider = FutureProvider<List<AnimeSubject>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const [];
  final backend = ref.watch(ynekoBackendProvider);
  return backend.searchSubjects(query, 1);
});
