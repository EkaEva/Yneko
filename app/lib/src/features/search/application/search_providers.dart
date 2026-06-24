import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/bridge/yneko_backend.dart';
import '../../../shared/domain/index.dart';

enum SearchMode { keyword, tag }

const searchPageLimit = 24;
const searchMaxPage = 20;

class SearchInput extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) {
    state = value;
  }
}

final searchInputProvider = NotifierProvider<SearchInput, String>(
  SearchInput.new,
);

class SearchModeController extends Notifier<SearchMode> {
  @override
  SearchMode build() => SearchMode.keyword;

  void set(SearchMode value) {
    state = value;
  }
}

final searchModeProvider = NotifierProvider<SearchModeController, SearchMode>(
  SearchModeController.new,
);

class SearchHistoryController extends Notifier<List<String>> {
  @override
  List<String> build() {
    Future<void>.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    try {
      final history = await ref.read(ynekoBackendProvider).listSearchHistory();
      if (ref.mounted) state = normalizeSearchHistory(history);
    } catch (_) {
      // History is a convenience feature; search itself should stay available.
    }
  }

  void add(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    _setHistory([clean, ...state.where((item) => item != clean)]);
  }

  void remove(String value) {
    _setHistory(state.where((item) => item != value));
  }

  void clear() {
    _setHistory(const []);
  }

  void _setHistory(Iterable<String> history) {
    state = normalizeSearchHistory(history);
    unawaited(ref.read(ynekoBackendProvider).saveSearchHistory(state));
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryController, List<String>>(
      SearchHistoryController.new,
    );

class SearchState {
  const SearchState({
    this.query = '',
    this.mode = SearchMode.keyword,
    this.subjects = const [],
    this.page = 0,
    this.hasNext = false,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.appendError,
  });

  final String query;
  final SearchMode mode;
  final List<AnimeSubject> subjects;
  final int page;
  final bool hasNext;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String? appendError;

  bool get hasQuery => query.trim().isNotEmpty;

  SearchState copyWith({
    String? query,
    SearchMode? mode,
    List<AnimeSubject>? subjects,
    int? page,
    bool? hasNext,
    bool? loading,
    bool? loadingMore,
    Object? error = _unchanged,
    Object? appendError = _unchanged,
  }) {
    return SearchState(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      subjects: subjects ?? this.subjects,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: identical(error, _unchanged) ? this.error : error as String?,
      appendError: identical(appendError, _unchanged)
          ? this.appendError
          : appendError as String?,
    );
  }
}

class SearchController extends Notifier<SearchState> {
  var _requestGeneration = 0;

  @override
  SearchState build() {
    return const SearchState();
  }

  Future<void> submit({String? query, SearchMode? mode}) async {
    final String sourceQuery;
    if (query == null) {
      sourceQuery = ref.read(searchInputProvider);
    } else {
      sourceQuery = query;
    }
    final clean = sourceQuery.trim();
    final SearchMode nextMode = mode ?? ref.read(searchModeProvider);
    ref.read(searchInputProvider.notifier).set(clean);
    ref.read(searchModeProvider.notifier).set(nextMode);

    final generation = ++_requestGeneration;
    if (clean.isEmpty) {
      state = SearchState(mode: nextMode);
      return;
    }

    ref.read(searchHistoryProvider.notifier).add(clean);
    state = SearchState(query: clean, mode: nextMode, loading: true);

    try {
      final items = await _loadPage(clean, nextMode, 1);
      if (generation != _requestGeneration || !ref.mounted) return;
      state = state.copyWith(
        subjects: uniqueSearchSubjects(items),
        page: 1,
        hasNext: items.length >= searchPageLimit && 1 < searchMaxPage,
        loading: false,
        error: null,
      );
    } catch (error) {
      if (generation != _requestGeneration || !ref.mounted) return;
      state = state.copyWith(
        subjects: const [],
        page: 0,
        hasNext: false,
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> retry() {
    return submit(query: state.query, mode: state.mode);
  }

  void clear({SearchMode mode = SearchMode.keyword}) {
    _requestGeneration++;
    ref.read(searchInputProvider.notifier).set('');
    ref.read(searchModeProvider.notifier).set(mode);
    state = SearchState(mode: mode);
  }

  Future<void> loadMore() async {
    if (state.loading ||
        state.loadingMore ||
        !state.hasNext ||
        state.query.trim().isEmpty ||
        state.page >= searchMaxPage) {
      return;
    }

    final generation = _requestGeneration;
    final page = state.page + 1;
    state = state.copyWith(loadingMore: true, appendError: null);
    try {
      final items = await _loadPage(state.query, state.mode, page);
      if (generation != _requestGeneration || !ref.mounted) return;
      state = state.copyWith(
        subjects: uniqueSearchSubjects([...state.subjects, ...items]),
        page: page,
        hasNext: items.length >= searchPageLimit && page < searchMaxPage,
        loadingMore: false,
      );
    } catch (error) {
      if (generation != _requestGeneration || !ref.mounted) return;
      state = state.copyWith(loadingMore: false, appendError: error.toString());
    }
  }

  Future<List<AnimeSubject>> _loadPage(
    String query,
    SearchMode mode,
    int page,
  ) async {
    final backend = ref.read(ynekoBackendProvider);
    return switch (mode) {
      SearchMode.keyword => backend.searchSubjects(query, page),
      SearchMode.tag => backend.searchTagSubjects(query, page),
    };
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);

List<AnimeSubject> uniqueSearchSubjects(List<AnimeSubject> subjects) {
  final seen = <int>{};
  return [
    for (final subject in subjects)
      if (seen.add(subject.id)) subject,
  ];
}

List<String> normalizeSearchHistory(Iterable<String> history) {
  final seen = <String>{};
  return [
    for (final item in history)
      if (item.trim().isNotEmpty && seen.add(item.trim())) item.trim(),
  ].take(12).toList(growable: false);
}

extension SearchModeLabel on SearchMode {
  String get heading {
    return switch (this) {
      SearchMode.keyword => '搜索',
      SearchMode.tag => '标签',
    };
  }

  String get emptyTitle {
    return switch (this) {
      SearchMode.keyword => '输入关键词开始搜索',
      SearchMode.tag => '输入标签开始搜索',
    };
  }

  String get loadingTitle {
    return switch (this) {
      SearchMode.keyword => '正在搜索 Bangumi',
      SearchMode.tag => '正在加载标签页',
    };
  }

  String get errorTitle {
    return switch (this) {
      SearchMode.keyword => 'Bangumi 搜索失败',
      SearchMode.tag => 'Bangumi 标签页加载失败',
    };
  }
}

const _unchanged = Object();
