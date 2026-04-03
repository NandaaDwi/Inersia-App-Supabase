import 'dart:io';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';

class UserArticleService {
  final _client = supabaseConfig.client;

  Future<List<CategoryModel>> getCategories({String query = ''}) async {
    var req = _client.from('categories').select();
    if (query.isNotEmpty) req = req.ilike('name', '%$query%');
    final res = await req.order('name', ascending: true);
    return (res as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final res = await _client
        .from('categories')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return CategoryModel.fromJson(res);
  }

  Future<List<TagModel>> getTags({String query = ''}) async {
    var req = _client.from('tags').select();
    if (query.isNotEmpty) req = req.ilike('name', '%$query%');
    final res = await req.order('name', ascending: true).limit(20);
    return (res as List).map((e) => TagModel.fromJson(e)).toList();
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

  Future<String?> uploadThumbnail(File file) async {
    final fileName =
        '${_client.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.png';
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

    final data = {
      'author_id': userId,
      'title': title,
      'content': content,
      'thumbnail': thumbnail,
      'category_id': categoryId,
      'status': status,
      'estimated_reading': (content.split(' ').length / 200).ceil().clamp(
        1,
        999,
      ),
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

  Future<List<ArticleModel>> getMyArticles({
    int page = 0,
    String? status,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final from = page * 10;
    final to = from + 9;

    var req = _client
        .from('articles')
        .select('''
      *,
      users(name, photo_url),
      categories(name)
    ''')
        .eq('author_id', userId);

    if (status != null) req = req.eq('status', status);

    final res = await req.order('updated_at', ascending: false).range(from, to);

    return (res as List).map((e) => ArticleModel.fromJson(e)).toList();
  }
}
