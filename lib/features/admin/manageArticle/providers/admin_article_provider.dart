import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageArticle/services/admin_article_service.dart';
import 'package:inersia_supabase/models/article_model.dart';

final adminArticleServiceProvider = Provider((ref) => AdminArticleService());

final articleSearchProvider = StateProvider<String>((ref) => '');

final articleSearchDebounceProvider = StateNotifierProvider<_Debounce, String>(
  (ref) => _Debounce(ref),
);

class _Debounce extends StateNotifier<String> {
  final Ref _ref;
  Timer? _t;
  _Debounce(this._ref) : super('') {
    _ref.listen<String>(articleSearchProvider, (_, next) {
      _t?.cancel();
      _t = Timer(const Duration(milliseconds: 400), () {
        if (mounted) state = next;
      });
    });
  }
  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

final adminArticlesProvider =
    AsyncNotifierProvider<AdminArticlesNotifier, List<ArticleModel>>(
      AdminArticlesNotifier.new,
    );

class AdminArticlesNotifier extends AsyncNotifier<List<ArticleModel>> {
  @override
  FutureOr<List<ArticleModel>> build() {
    final query = ref.watch(articleSearchDebounceProvider);
    return ref
        .read(adminArticleServiceProvider)
        .getArticles(query: query, status: 'published');
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(adminArticleServiceProvider)
          .getArticles(status: 'published'),
    );
  }
}
