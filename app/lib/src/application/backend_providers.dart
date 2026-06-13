import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../infrastructure/bridge/yneko_backend.dart';

final ynekoBackendProvider = Provider<YnekoBackend>((ref) {
  return const FrbYnekoBackend();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<AnimeSubject>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const [];
  final backend = ref.watch(ynekoBackendProvider);
  return backend.searchSubjects(query, 1);
});

