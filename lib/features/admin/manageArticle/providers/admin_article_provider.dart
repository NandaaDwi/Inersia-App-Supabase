import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageArticle/services/admin_article_service.dart';
import 'package:inersia_supabase/models/article_model.dart';

final adminArticleServiceProvider = Provider((ref) => AdminArticleService());

final articleSearchProvider = StateProvider<String>((ref) => '');

final _debouncedSearchProvider = StateProvider<String>((ref) => '');

final articleStatusFilterProvider = StateProvider<String?>((ref) => null);
final articlePageProvider = StateProvider<int>((ref) => 0);

final articleSearchDebounceProvider =
    StateNotifierProvider<_SearchDebounceNotifier, String>(
      (ref) => _SearchDebounceNotifier(ref),
    );

class _SearchDebounceNotifier extends StateNotifier<String> {
  final Ref _ref;
  Timer? _timer;

  _SearchDebounceNotifier(this._ref) : super('') {
    _ref.listen<String>(articleSearchProvider, (_, next) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 500), () {
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

final adminArticlesProvider =
    AsyncNotifierProvider<AdminArticlesNotifier, List<ArticleModel>>(
      AdminArticlesNotifier.new,
    );

class AdminArticlesNotifier extends AsyncNotifier<List<ArticleModel>> {
  @override
  FutureOr<List<ArticleModel>> build() {
    final query = ref.watch(articleSearchDebounceProvider);
    final status = ref.watch(articleStatusFilterProvider);
    final page = ref.watch(articlePageProvider);

    return ref
        .read(adminArticleServiceProvider)
        .getArticles(query: query, status: status, page: page);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminArticleServiceProvider).getArticles(),
    );
  }
}
