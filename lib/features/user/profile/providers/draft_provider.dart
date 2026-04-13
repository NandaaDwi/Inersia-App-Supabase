import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/profile/services/draft_service.dart';
import 'package:inersia_supabase/models/article_model.dart';

final draftServiceProvider = Provider.autoDispose((_) => DraftService());

// ─── Filter & Search State ────────────────────────────────────

/// Filter status artikel: null = semua, 'draft', 'published'
final articleStatusFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Query pencarian real-time
final articleSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

// ─── Article List State ───────────────────────────────────────

class DraftState {
  final List<ArticleModel> articles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int page;

  const DraftState({
    this.articles = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
  });

  DraftState copyWith({
    List<ArticleModel>? articles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? page,
    bool clearError = false,
  }) {
    return DraftState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────

class DraftNotifier extends StateNotifier<DraftState> {
  final DraftService _service;
  final Ref _ref;

  Timer? _debounce;

  DraftNotifier(this._service, this._ref) : super(const DraftState()) {
    // Dengarkan perubahan filter status
    _ref.listen<String?>(articleStatusFilterProvider, (prev, next) {
      if (prev != next) _reset();
    });

    // Dengarkan perubahan query pencarian dengan debounce
    _ref.listen<String>(articleSearchQueryProvider, (prev, next) {
      if (prev != next) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 350), _reset);
      }
    });

    _fetch(0);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _reset() {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    _fetch(0);
  }

  Future<void> _fetch(int page) async {
    try {
      final query = _ref.read(articleSearchQueryProvider);
      final statusFilter = _ref.read(articleStatusFilterProvider);

      final results = await _service.getMyArticles(
        page: page,
        query: query,
        status: statusFilter,
      );

      if (!mounted) return;
      final newList = page == 0 ? results : [...state.articles, ...results];

      state = state.copyWith(
        articles: newList,
        isLoading: false,
        isLoadingMore: false,
        hasMore: results.length == DraftService.pageSize,
        page: page,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Gagal memuat artikel.',
      );
    }
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetch(0);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetch(state.page + 1);
  }

  Future<void> deleteArticle(String articleId) async {
    final backup = state.articles;
    // Optimistic update
    state = state.copyWith(
      articles: state.articles.where((a) => a.id != articleId).toList(),
    );
    try {
      await _service.deleteArticle(articleId);
    } catch (_) {
      // Rollback jika gagal
      if (mounted) state = state.copyWith(articles: backup);
    }
  }
}

final draftProvider =
    StateNotifierProvider.autoDispose<DraftNotifier, DraftState>(
  (ref) => DraftNotifier(ref.read(draftServiceProvider), ref),
);