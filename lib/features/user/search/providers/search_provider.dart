import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/search/services/search_service.dart';

final searchServiceProvider = Provider.autoDispose((_) => SearchService());

final discoveryProvider = FutureProvider<DiscoveryData>((ref) {
  return ref.read(searchServiceProvider).getDiscovery();
});

enum SearchTab { all, articles, users, tags }

class SearchState {
  final String query;
  final List<SuggestionItem> suggestions;
  final SearchResults? results;
  final bool isSearching;
  final bool isSuggesting;
  final String? error;
  final SearchTab activeTab;
  final List<String> history;

  const SearchState({
    this.query = '',
    this.suggestions = const [],
    this.results,
    this.isSearching = false,
    this.isSuggesting = false,
    this.error,
    this.activeTab = SearchTab.all,
    this.history = const [],
  });

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => results != null && !results!.isEmpty;
  bool get showSuggestions => suggestions.isNotEmpty && isSuggesting == false;

  SearchState copyWith({
    String? query,
    List<SuggestionItem>? suggestions,
    SearchResults? results,
    bool? isSearching,
    bool? isSuggesting,
    String? error,
    SearchTab? activeTab,
    List<String>? history,
    bool clearResults = false,
    bool clearSuggestions = false,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      suggestions: clearSuggestions ? [] : (suggestions ?? this.suggestions),
      results: clearResults ? null : (results ?? this.results),
      isSearching: isSearching ?? this.isSearching,
      isSuggesting: isSuggesting ?? this.isSuggesting,
      error: clearError ? null : (error ?? this.error),
      activeTab: activeTab ?? this.activeTab,
      history: history ?? this.history,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _service;
  Timer? _debounceTimer;
  Timer? _suggestionTimer;

  SearchNotifier(this._service) : super(const SearchState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  void onQueryChanged(String query) {
    state = state.copyWith(
      query: query,
      clearSuggestions: query.isEmpty,
      clearResults: query.isEmpty,
      clearError: true,
    );

    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    if (query.trim().isEmpty) return;

    _suggestionTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted || state.query != query) return;
      state = state.copyWith(isSuggesting: true);
      try {
        final suggestions = await _service.getSuggestions(query);
        if (mounted && state.query == query) {
          state = state.copyWith(suggestions: suggestions, isSuggesting: false);
        }
      } catch (_) {
        if (mounted) state = state.copyWith(isSuggesting: false);
      }
    });
  }

  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    final q = query.trim();
    if (q.isEmpty) return;

    state = state.copyWith(
      query: q,
      isSearching: true,
      clearSuggestions: true,
      clearError: true,
    );

    final newHistory = [
      q,
      ...state.history.where((h) => h.toLowerCase() != q.toLowerCase()),
    ].take(8).toList();

    try {
      final results = await _service.search(q);
      if (mounted) {
        state = state.copyWith(
          results: results,
          isSearching: false,
          history: newHistory,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSearching: false,
          error: 'Gagal mencari. Coba lagi.',
          history: newHistory,
        );
      }
    }
  }

  Future<void> searchByTag(TagResult tag) async {
    state = state.copyWith(
      query: '#${tag.name}',
      isSearching: true,
      clearSuggestions: true,
      clearError: true,
    );

    try {
      final articles = await _service.searchByTag(tag.id);
      if (mounted) {
        state = state.copyWith(
          results: SearchResults(articles: articles, query: '#${tag.name}'),
          isSearching: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSearching: false, error: 'Gagal mencari tag.');
      }
    }
  }

  Future<void> searchByCategory(CategoryResult category) async {
    state = state.copyWith(
      query: category.name,
      isSearching: true,
      clearSuggestions: true,
      clearError: true,
    );

    try {
      final articles = await _service.searchByCategory(category.id);
      if (mounted) {
        state = state.copyWith(
          results: SearchResults(articles: articles, query: category.name),
          isSearching: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSearching: false,
          error: 'Gagal mencari kategori.',
        );
      }
    }
  }

  void setTab(SearchTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    state = state.copyWith(
      query: '',
      clearSuggestions: true,
      clearResults: true,
      clearError: true,
    );
  }
}

final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>(
      (ref) => SearchNotifier(ref.read(searchServiceProvider)),
    );
