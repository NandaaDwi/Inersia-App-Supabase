import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';

class ReadPageService {
  final _client = supabaseConfig.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<ArticleModel> getArticleById(String id) async {
    final res = await _client
        .from('articles')
        .select(
          'id,author_id,title,content,thumbnail,status,category_id,'
          'estimated_reading,like_count,comment_count,view_count,'
          'tags,created_at,updated_at,'
          'users:author_id(name,photo_url),'
          'categories:category_id(name)',
        )
        .eq('id', id)
        .single();

    _incrementViewCount(id, res['view_count'] as int? ?? 0);
    return ArticleModel.fromJson(res);
  }

  void _incrementViewCount(String articleId, int current) {
    _client
        .from('articles')
        .update({'view_count': current + 1})
        .eq('id', articleId)
        .then((_) {})
        .catchError((_) {});
  }

  Future<Map<String, int>> getArticleStats(String articleId) async {
    final res = await _client
        .from('articles')
        .select('like_count,view_count,comment_count')
        .eq('id', articleId)
        .single();
    return {
      'like_count': res['like_count'] as int? ?? 0,
      'view_count': res['view_count'] as int? ?? 0,
      'comment_count': res['comment_count'] as int? ?? 0,
    };
  }

  Future<bool> isLiked(String articleId) async {
    final uid = _currentUserId;
    if (uid == null) return false;
    final res = await _client
        .from('likes')
        .select('article_id')
        .eq('article_id', articleId)
        .eq('user_id', uid)
        .maybeSingle();
    return res != null;
  }

  Future<({bool isLiked, int count})> toggleLike(
    String articleId,
    bool currentlyLiked,
  ) async {
    final uid = _currentUserId!;

    if (currentlyLiked) {
      await _client
          .from('likes')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', uid);
    } else {
      await _client.from('likes').insert({
        'article_id': articleId,
        'user_id': uid,
      });
    }

    final countRes = await _client
        .from('articles')
        .select('like_count')
        .eq('id', articleId)
        .single();
    final current = countRes['like_count'] as int? ?? 0;
    final newCount = currentlyLiked
        ? (current - 1).clamp(0, 999999)
        : current + 1;

    await _client
        .from('articles')
        .update({'like_count': newCount})
        .eq('id', articleId);

    return (isLiked: !currentlyLiked, count: newCount);
  }

  Future<bool> isBookmarked(String articleId) async {
    final uid = _currentUserId;
    if (uid == null) return false;
    final res = await _client
        .from('reading_list')
        .select('id')
        .eq('article_id', articleId)
        .eq('user_id', uid)
        .maybeSingle();
    return res != null;
  }

  Future<void> toggleBookmark(
    String articleId,
    bool currentlyBookmarked,
  ) async {
    final uid = _currentUserId!;
    if (currentlyBookmarked) {
      await _client
          .from('reading_list')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', uid);
    } else {
      await _client.from('reading_list').insert({
        'article_id': articleId,
        'user_id': uid,
        'saved_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<CommentModel>> getComments(String articleId) async {
    final res = await _client
        .from('comments')
        .select('*,users:user_id(name,photo_url)')
        .eq('article_id', articleId)
        .isFilter('parent_id', null)
        .order('created_at', ascending: true);
    return (res as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  Future<CommentModel> addComment({
    required String articleId,
    required String commentText,
    String? parentId,
  }) async {
    final uid = _currentUserId!;

    final res = await _client
        .from('comments')
        .insert({
          'article_id': articleId,
          'user_id': uid,
          'comment_text': commentText,
          if (parentId != null) 'parent_id': parentId,
        })
        .select('*,users:user_id(name,photo_url)')
        .single();

    final countRes = await _client
        .from('articles')
        .select('comment_count')
        .eq('id', articleId)
        .single();
    final current = countRes['comment_count'] as int? ?? 0;
    await _client
        .from('articles')
        .update({'comment_count': current + 1})
        .eq('id', articleId);

    return CommentModel.fromJson(res);
  }

  Future<bool> isFollowing(String targetUserId) async {
    final uid = _currentUserId;
    if (uid == null || uid == targetUserId) return false;
    final res = await _client
        .from('social')
        .select('follower_id')
        .eq('follower_id', uid)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return res != null;
  }

  Future<bool> toggleFollow(
    String targetUserId,
    bool currentlyFollowing,
  ) async {
    final uid = _currentUserId!;
    if (uid == targetUserId) return currentlyFollowing;

    if (currentlyFollowing) {
      await _client
          .from('social')
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', targetUserId);

      final tr = await _client
          .from('users')
          .select('followers_count')
          .eq('id', targetUserId)
          .single();
      await _client
          .from('users')
          .update({
            'followers_count': ((tr['followers_count'] as int? ?? 1) - 1).clamp(
              0,
              999999,
            ),
          })
          .eq('id', targetUserId);

      final sr = await _client
          .from('users')
          .select('following_count')
          .eq('id', uid)
          .single();
      await _client
          .from('users')
          .update({
            'following_count': ((sr['following_count'] as int? ?? 1) - 1).clamp(
              0,
              999999,
            ),
          })
          .eq('id', uid);

      return false;
    } else {
      await _client.from('social').insert({
        'follower_id': uid,
        'following_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      final tr = await _client
          .from('users')
          .select('followers_count')
          .eq('id', targetUserId)
          .single();
      await _client
          .from('users')
          .update({'followers_count': (tr['followers_count'] as int? ?? 0) + 1})
          .eq('id', targetUserId);

      final sr = await _client
          .from('users')
          .select('following_count')
          .eq('id', uid)
          .single();
      await _client
          .from('users')
          .update({'following_count': (sr['following_count'] as int? ?? 0) + 1})
          .eq('id', uid);

      _client
          .from('notifications')
          .insert({
            'receiver_id': targetUserId,
            'sender_id': uid,
            'type': 'follow',
            'is_read': false,
          })
          .then((_) {})
          .catchError((_) {});

      return true;
    }
  }

  Future<void> submitReport({
    required String targetId,
    required String targetType,
    required String reasonCategory,
    String? description,
    Map<String, dynamic>? contentSnapshot,
  }) async {
    final uid = _currentUserId!;

    final existing = await _client
        .from('reports')
        .select('id')
        .eq('reporter_id', uid)
        .eq('target_id', targetId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Kamu sudah melaporkan konten ini sebelumnya.');
    }

    await _client.from('reports').insert({
      'reporter_id': uid,
      'target_id': targetId,
      'target_type': targetType,
      'reason_category': reasonCategory,
      'description': description,
      'content_snapshot': contentSnapshot,
      'status': 'pending',
    });
  }
}
