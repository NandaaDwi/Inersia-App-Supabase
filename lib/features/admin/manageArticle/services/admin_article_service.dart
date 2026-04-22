import 'dart:io';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';

class AdminArticleService {
  final _client = supabaseConfig.client;

  static const int pageSize = 15;

  Future<List<ArticleModel>> getArticles({
    int page = 0,
    String query = '',
    String? status,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1; 

    var req = _client.from('articles').select('''
      id,
      author_id,
      title,
      thumbnail,
      status,
      category_id,
      estimated_reading,
      like_count,
      comment_count,
      view_count,
      created_at,
      updated_at,
      content,
      users:author_id(name, photo_url),
      categories:category_id(name)
    ''');

    if (query.trim().isNotEmpty) {
      req = req.ilike('title', '%${query.trim()}%');
    }

    if (status != null) {
      req = req.eq('status', status);
    }

    final res = await req.order('created_at', ascending: false).range(from, to);

    return (res as List).map((e) => ArticleModel.fromJson(e)).toList();
  }

  Future<String?> uploadThumbnail(File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    await _client.storage.from('thumbnails').upload(fileName, file);
    return _client.storage.from('thumbnails').getPublicUrl(fileName);
  }

  Future<void> saveArticle({
    String? id,
    required String title,
    required String content,
    String? thumbnail,
    required String categoryId,
    required List<String> tagIds,
    required String status,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final wordCount = content.split(' ').length;
    final data = {
      'author_id': userId,
      'title': title,
      'content': content,
      'thumbnail': thumbnail,
      'category_id': categoryId,
      'status': status,
      'estimated_reading': (wordCount / 200).ceil().clamp(1, 999),
    };

    final articleRes = id == null
        ? await _client.from('articles').insert(data).select().single()
        : await _client
              .from('articles')
              .update(data)
              .eq('id', id)
              .select()
              .single();

    final String articleId = articleRes['id'] as String;

    await _client.from('article_tags').delete().eq('article_id', articleId);
    if (tagIds.isNotEmpty) {
      await _client
          .from('article_tags')
          .insert(
            tagIds
                .map((tid) => {'article_id': articleId, 'tag_id': tid})
                .toList(),
          );
    }
  }

  Future<TagModel> getOrCreateTag(String name) async {
    final normalized = name.trim().toLowerCase();
    final existing = await _client
        .from('tags')
        .select()
        .ilike('name', normalized)
        .maybeSingle();
    if (existing != null) return TagModel.fromJson(existing);

    final res = await _client
        .from('tags')
        .insert({'name': name.trim()})
        .select()
        .single();
    return TagModel.fromJson(res);
  }
}
