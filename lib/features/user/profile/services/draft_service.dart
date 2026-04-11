import 'package:flutter/widgets.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';

class DraftService {
  final _client = supabaseConfig.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  static const int _pageSize = 15;

  Future<List<ArticleModel>> getDrafts({int page = 0}) async {
    final uid = _currentUserId;
    final from = page * _pageSize;
    final to = from * _pageSize - 1;

    final res = await _client
        .from('articles')
        .select(
          'id, author_id, title, thumbnail, status, category_id,'
          'estimated_reading, like_count, comment_count, view_count,'
          'created_at, updated_at, content,'
          'users:author_id(name, photo_url),'
          'categories:category_id(name)',
        )
        .eq('author_id', uid)
        .eq('status', 'draft')
        .order('update_at', ascending: false)
        .range(from, to);

    return (res as List).map((e) => ArticleModel.fromJson(e)).toList();
  }

  Future<void> deleteDraft(String articleId) async {
    final uid = _currentUserId;

    await _client.from('article_tags').delete().eq('article_id', articleId);
    await _client
        .from('articles')
        .delete()
        .eq('id', articleId)
        .eq('author_id', uid);
  }
}
