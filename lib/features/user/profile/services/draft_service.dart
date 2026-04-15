import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';

class DraftService {
  final _client = supabaseConfig.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  static const int pageSize = 15;

  Future<List<ArticleModel>> getMyArticles({
    int page = 0,
    String query = '',
    String? status,
  }) async {
    final uid = _currentUserId;
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var req = _client
        .from('articles')
        .select('''
          id, author_id, title, thumbnail, status, category_id,
          estimated_reading, like_count, comment_count, view_count,
          created_at, updated_at, content,
          users:author_id(name, photo_url),
          categories:category_id(name),
          article_tags(
            tags(*)
          )
        ''')
        .eq('author_id', uid);

    if (status != null) {
      req = req.eq('status', status);
    } else {
      req = req.inFilter('status', ['draft', 'published']);
    }

    if (query.trim().isNotEmpty) {
      req = req.ilike('title', '%${query.trim()}%');
    }

    final res = await req.order('updated_at', ascending: false).range(from, to);

    return (res as List).map((e) => ArticleModel.fromJson(e)).toList();
  }

  Future<void> deleteArticle(String articleId) async {
    final uid = _currentUserId;
    await _client.from('article_tags').delete().eq('article_id', articleId);
    await _client
        .from('articles')
        .delete()
        .eq('id', articleId)
        .eq('author_id', uid);
  }
}
