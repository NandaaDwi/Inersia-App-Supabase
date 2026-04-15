import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/services/main_page_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';

final mainPageServiceProvider = Provider<MainPageService>(
  (_) => MainPageService(),
);

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.read(mainPageServiceProvider).getCategories();
});

class ArticleListState {
  final List<ArticleModel> articles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int page;

  const ArticleListState({
    this.articles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
  });

  ArticleListState copyWith({
    List<ArticleModel>? articles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? page,
  }) {
    return ArticleListState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
    );
  }
}

class ArticleListNotifier extends StateNotifier<ArticleListState> {
  final MainPageService _service;
  final Ref _ref;

  ArticleListNotifier(this._service, this._ref)
    : super(const ArticleListState()) {
    _ref.listen<String?>(selectedCategoryProvider, (_, __) => _reset());
    _fetchInitial();
  }

  void _reset() {
    state = const ArticleListState(isLoading: true);
    _fetchPage(0);
  }

  Future<void> _fetchInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchPage(0);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final results = await _service.getPublishedArticles(
        page: page,
        categoryId: _ref.read(selectedCategoryProvider),
      );

      final newList = page == 0 ? results : [...state.articles, ...results];

      state = state.copyWith(
        articles: newList,
        isLoading: false,
        isLoadingMore: false,
        hasMore: results.length == 10,
        page: page,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => _fetchInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetchPage(state.page + 1);
  }
}

final articleListProvider =
    StateNotifierProvider<ArticleListNotifier, ArticleListState>(
      (ref) => ArticleListNotifier(ref.read(mainPageServiceProvider), ref),
    );

final articleLikeCountStreamProvider = StreamProvider.family<int, String>((
  ref,
  articleId,
) {
  return supabaseConfig.client
      .from('articles')
      .stream(primaryKey: ['id'])
      .eq('id', articleId)
      .map((rows) {
        if (rows.isEmpty) return 0;
        return rows.first['like_count'] as int? ?? 0;
      });
});

final articleCommentCountStreamProvider = StreamProvider.family<int, String>((
  ref,
  articleId,
) {
  return supabaseConfig.client
      .from('articles')
      .stream(primaryKey: ['id'])
      .eq('id', articleId)
      .map((rows) {
        if (rows.isEmpty) return 0;
        return rows.first['comment_count'] as int? ?? 0;
      });
});

final cardLikeStatusProvider = FutureProvider.family<bool, (String, String)>((
  ref,
  args,
) async {
  final articleId = args.$1;
  final userId = args.$2;
  if (userId.isEmpty) return false;

  final res = await supabaseConfig.client
      .from('likes')
      .select('article_id')
      .eq('article_id', articleId)
      .eq('user_id', userId)
      .maybeSingle();
  return res != null;
});
