import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';

class BookmarkService {
  final _client = supabaseConfig.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<List<ArticleModel>> getBookmarkedArticles() async {
    final uid = _currentUserId;
    if (uid == null) return [];

    final res = await _client
        .from('reading_list')
        .select(
          'saved_at,'
          'articles!inner('
          '  id, author_id, title, content, thumbnail, status,'
          '  category_id, estimated_reading, like_count,'
          '  comment_count, view_count, created_at, updated_at,'
          '  users:author_id(name, photo_url),'
          '  categories:category_id(name, id)'
          ')',
        )
        .eq('user_id', uid)
        .order('saved_at', ascending: false);

    return (res as List).map((row) {
      final articleJson = row['articles'] as Map<String, dynamic>;
      return ArticleModel.fromJson(articleJson);
    }).toList();
  }

  Future<void> removeBookmark(String articleId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    await _client
        .from('reading_list')
        .delete()
        .eq('article_id', articleId)
        .eq('user_id', uid);
  }

  Future<List<CategoryModel>> getBookmarkedCategories() async {
    final uid = _currentUserId;
    if (uid == null) return [];

    final res = await _client
        .from('categories')
        .select(
          'id, name, article_count, created_at, articles!inner(reading_list!inner(user_id))',
        )
        .eq('articles.reading_list.user_id', uid);

    final List<dynamic> data = res as List;

    final distinctCategories = <String, CategoryModel>{};

    for (var item in data) {
      final model = CategoryModel.fromJson(item);
      if (!distinctCategories.containsKey(model.id)) {
        distinctCategories[model.id] = model;
      }
    }
    return distinctCategories.values.toList();
  }
}
