import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageArticle/services/admin_article_service.dart';
import 'package:inersia_supabase/models/article_model.dart';


final adminArticleServiceProvider =
    Provider((_) => AdminArticleService());


final articleSearchProvider = StateProvider<String>((ref) => '');


final articleSearchDebounceProvider =
    StateNotifierProvider<_DebounceNotifier, String>(
  (ref) => _DebounceNotifier(ref),
);

class _DebounceNotifier extends StateNotifier<String> {
  final Ref _ref;
  Timer? _timer;

  _DebounceNotifier(this._ref) : super('') {
    _ref.listen<String>(articleSearchProvider, (_, next) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) state = next;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}


class AdminArticleState {
  final List<ArticleModel> articles;
  final bool isLoading;       
  final bool isLoadingMore;   
  final bool hasMore;         
  final String? error;
  final int page;             

  const AdminArticleState({
    this.articles = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
  });

  AdminArticleState copyWith({
    List<ArticleModel>? articles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? page,
    bool clearError = false,
  }) {
    return AdminArticleState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
    );
  }
}


class AdminArticlesNotifier extends StateNotifier<AdminArticleState> {
  final AdminArticleService _service;
  final Ref _ref;

  AdminArticlesNotifier(this._service, this._ref)
      : super(const AdminArticleState()) {
    _ref.listen<String>(articleSearchDebounceProvider, (prev, next) {
      if (prev != next) _reset();
    });
    _fetch(page: 0);
  }


  Future<void> _fetch({required int page}) async {
    final query = _ref.read(articleSearchDebounceProvider);
    try {
      final results = await _service.getArticles(
        page: page,
        query: query,
        status: null,
      );

      if (!mounted) return;

      final newList = page == 0
          ? results
          : [...state.articles, ...results];

      state = state.copyWith(
        articles: newList,
        isLoading: false,
        isLoadingMore: false,
        hasMore: results.length == AdminArticleService.pageSize,
        page: page,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Gagal memuat artikel: $e',
      );
    }
  }


  Future<void> _reset() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetch(page: 0);
  }

  Future<void> refresh() => _reset();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetch(page: state.page + 1);
  }

  void removeArticle(String articleId) {
    if (!mounted) return;
    state = state.copyWith(
      articles: state.articles.where((a) => a.id != articleId).toList(),
    );
  }
}


final adminArticlesProvider = StateNotifierProvider.autoDispose<
    AdminArticlesNotifier, AdminArticleState>(
  (ref) => AdminArticlesNotifier(
    ref.read(adminArticleServiceProvider),
    ref,
  ),
);