import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';

class ReadPageService {
  final _client = supabaseConfig.client;
  String? get _uid => _client.auth.currentUser?.id;

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
    return ArticleModel.fromJson(res);
  }

  Future<void> incrementViewCount(String articleId) async {
    try {
      await _client.rpc(
        'increment_view_count',
        params: {'article_id': articleId},
      );
    } catch (_) {
      try {
        final r = await _client
            .from('articles')
            .select('view_count')
            .eq('id', articleId)
            .single();
        final current = r['view_count'] as int? ?? 0;
        await _client
            .from('articles')
            .update({'view_count': current + 1})
            .eq('id', articleId);
      } catch (_) {}
    }
  }

  Future<bool> isLiked(String articleId) async {
    final uid = _uid;
    if (uid == null) return false;
    final res = await _client
        .from('likes')
        .select('article_id')
        .eq('article_id', articleId)
        .eq('user_id', uid)
        .maybeSingle();
    return res != null;
  }

  Future<({bool isLiked})> toggleLike(
    String articleId,
    bool currentlyLiked,
  ) async {
    final uid = _uid!;

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

    try {
      final countRes = await _client
          .from('likes')
          .select('user_id')
          .eq('article_id', articleId)
          .count();
      await _client
          .from('articles')
          .update({'like_count': countRes.count})
          .eq('id', articleId);
    } catch (_) {}

    return (isLiked: !currentlyLiked);
  }

  Future<bool> isBookmarked(String articleId) async {
    final uid = _uid;
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
    final uid = _uid!;

    if (currentlyBookmarked) {
      await _client
          .from('reading_list')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', uid);
    } else {
      final article = await _client
          .from('articles')
          .select('author_id')
          .eq('id', articleId)
          .single();

      if (article['author_id'] == uid) {
        throw Exception(
          'Anda tidak dapat menyimpan artikel sendiri ke daftar baca.',
        );
      }

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
        .order('created_at', ascending: false);
    return (res as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  Future<CommentModel> addComment({
    required String articleId,
    required String commentText,
    String? parentId,
  }) async {
    final uid = _uid!;
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

    _syncCommentCount(articleId);

    return CommentModel.fromJson(res);
  }

  Future<void> deleteComment(String commentId, String articleId) async {
    await _client
        .from('comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', _uid!);
    _syncCommentCount(articleId);
  }

  Future<void> _syncCommentCount(String articleId) async {
    try {
      final res = await _client
          .from('comments')
          .select('id')
          .eq('article_id', articleId)
          .isFilter('parent_id', null)
          .count();
      await _client
          .from('articles')
          .update({'comment_count': res.count})
          .eq('id', articleId);
    } catch (_) {}
  }

  Future<bool> isFollowing(String targetUserId) async {
    final uid = _uid;
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
    final uid = _uid!;
    if (uid == targetUserId) return currentlyFollowing;

    if (currentlyFollowing) {
      await _client
          .from('social')
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', targetUserId);

      _updateCount(targetUserId, 'followers_count', -1);
      _updateCount(uid, 'following_count', -1);
      return false;
    } else {
      await _client.from('social').insert({
        'follower_id': uid,
        'following_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      _updateCount(targetUserId, 'followers_count', 1);
      _updateCount(uid, 'following_count', 1);

      _client
          .from('notifications')
          .insert({
            'receiver_id': targetUserId,
            'sender_id': uid,
            'type': 'follow',
            'is_read': false,
            'message': 'mulai mengikuti kamu',
          })
          .then((_) {})
          .catchError((_) {});

      return true;
    }
  }

  Future<void> _updateCount(String userId, String field, int delta) async {
    try {
      final res = await _client
          .from('users')
          .select(field)
          .eq('id', userId)
          .single();
      final current = res[field] as int? ?? 0;
      await _client
          .from('users')
          .update({field: (current + delta).clamp(0, 999999)})
          .eq('id', userId);
    } catch (_) {}
  }

  Future<void> submitReport({
    required String targetId,
    required String targetType,
    required String reasonCategory,
    String? description,
    Map<String, dynamic>? contentSnapshot,
  }) async {
    final uid = _uid!;

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
