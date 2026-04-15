import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';

class MainPageService {
  final _client = supabaseConfig.client;
  static const int _pageSize = 10;

  Future<List<ArticleModel>> getPublishedArticles({
    int page = 0,
    String? categoryId,
  }) async {
    final from = page * _pageSize;
    final to = from + _pageSize - 1;

    try {
      var query = _client
          .from('articles')
          .select('''
            *,
            users:author_id (name, photo_url),
            categories:category_id (name)
          ''')
          .eq('status', 'published')
          .eq('users.status', 'active');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List).map((e) => ArticleModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await _client
          .from('categories')
          .select()
          .order('name', ascending: true);
      return (res as List).map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
