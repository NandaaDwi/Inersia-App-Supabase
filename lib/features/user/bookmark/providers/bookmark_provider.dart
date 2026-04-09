import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/bookmark/services/bookmark_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';

final bookmarkServiceProvider =
    Provider.autoDispose((_) => BookmarkService());


class BookmarkState {
  final List<ArticleModel> allArticles;

  final List<ArticleModel> filtered;

  final List<CategoryModel> categories;

  final bool isLoading;
  final String? error;

  final String query;

  final String? selectedCategoryId;

  const BookmarkState({
    this.allArticles = const [],
    this.filtered = const [],
    this.categories = const [],
    this.isLoading = true,
    this.error,
    this.query = '',
    this.selectedCategoryId,
  });

  bool get isEmpty => filtered.isEmpty;

  BookmarkState copyWith({
    List<ArticleModel>? allArticles,
    List<ArticleModel>? filtered,
    List<CategoryModel>? categories,
    bool? isLoading,
    String? error,
    String? query,
    String? selectedCategoryId,
    bool clearCategory = false,
    bool clearError = false,
  }) {
    return BookmarkState(
      allArticles: allArticles ?? this.allArticles,
      filtered: filtered ?? this.filtered,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }
}


class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final BookmarkService _service;
  Timer? _debounce;

  BookmarkNotifier(this._service) : super(const BookmarkState()) {
    load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _service.getBookmarkedArticles(),
        _service.getBookmarkedCategories(),
      ]);

      final articles = results[0] as List<ArticleModel>;
      final categories = results[1] as List<CategoryModel>;

      if (!mounted) return;
      state = state.copyWith(
        allArticles: articles,
        filtered: _applyFilter(
          articles,
          state.query,
          state.selectedCategoryId,
        ),
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat bookmark. Coba lagi.',
      );
    }
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query);

    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      state = state.copyWith(
        filtered: _applyFilter(
          state.allArticles,
          query,
          state.selectedCategoryId,
        ),
      );
    });
  }

  void selectCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      filtered: _applyFilter(
        state.allArticles,
        state.query,
        categoryId,
      ),
    );
  }

  Future<void> removeBookmark(String articleId) async {
    final newAll =
        state.allArticles.where((a) => a.id != articleId).toList();
    final newFiltered =
        state.filtered.where((a) => a.id != articleId).toList();
    final remainingCatIds =
        newAll.map((a) => a.categoryId).toSet();
    final newCategories =
        state.categories.where((c) => remainingCatIds.contains(c.id)).toList();

    final catStillExists = state.selectedCategoryId == null ||
        remainingCatIds.contains(state.selectedCategoryId);

    state = state.copyWith(
      allArticles: newAll,
      filtered: newFiltered,
      categories: newCategories,
      selectedCategoryId:
          catStillExists ? state.selectedCategoryId : null,
      clearCategory: !catStillExists,
    );

    try {
      await _service.removeBookmark(articleId);
    } catch (_) {
      load();
    }
  }

  List<ArticleModel> _applyFilter(
    List<ArticleModel> all,
    String query,
    String? categoryId,
  ) {
    var result = all;

    if (categoryId != null) {
      result =
          result.where((a) => a.categoryId == categoryId).toList();
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.authorName.toLowerCase().contains(q) ||
                (a.categoryName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    return result;
  }
}

final bookmarkListProvider =
    StateNotifierProvider.autoDispose<BookmarkNotifier, BookmarkState>(
  (ref) => BookmarkNotifier(ref.read(bookmarkServiceProvider)),
);