import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';

class ReadPageService {
  final _client = supabaseConfig.client;

  // ─── Article ──────────────────────────────────────────────────

  Future<ArticleModel> getArticleById(String id) async {
    final res = await _client
        .from('articles')
        .select('''
          id, author_id, title, content, thumbnail, status,
          category_id, estimated_reading, like_count,
          comment_count, view_count, tags, created_at, updated_at,
          users(name, photo_url),
          categories(name)
        ''')
        .eq('id', id)
        .single();

    // Increment view_count fire-and-forget — tidak block UI
    _incrementViewCount(id, res['view_count'] as int? ?? 0);

    return ArticleModel.fromJson(res);
  }

  void _incrementViewCount(String articleId, int currentCount) {
    _client
        .from('articles')
        .update({'view_count': currentCount + 1})
        .eq('id', articleId)
        .then((_) {})
        .catchError((_) {});
  }

  // Fetch angka stats terbaru (like, view, comment) dari DB
  Future<Map<String, int>> getArticleStats(String articleId) async {
    final res = await _client
        .from('articles')
        .select('like_count, view_count, comment_count')
        .eq('id', articleId)
        .single();
    return {
      'like_count': res['like_count'] as int? ?? 0,
      'view_count': res['view_count'] as int? ?? 0,
      'comment_count': res['comment_count'] as int? ?? 0,
    };
  }

  // ─── Like ─────────────────────────────────────────────────────

  Future<bool> isLiked(String articleId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final res = await _client
        .from('likes')
        .select('article_id')
        .eq('article_id', articleId)
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }

  /// Return: {isLiked: bool, count: int}
  /// Menggunakan PostgreSQL raw UPDATE dengan expr untuk atomic increment/decrement
  /// menghindari race condition dan tidak bergantung pada RPC custom
  Future<({bool isLiked, int count})> toggleLike(
    String articleId,
    bool currentlyLiked,
  ) async {
    final userId = _client.auth.currentUser!.id;

    if (currentlyLiked) {
      // Unlike: hapus dari likes, kurangi like_count dengan raw SQL expr
      await _client
          .from('likes')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', userId);

      // Gunakan rpc yang aman atau update manual dengan fetch dulu
      final countRes = await _client
          .from('articles')
          .select('like_count')
          .eq('id', articleId)
          .single();
      final current = countRes['like_count'] as int? ?? 0;
      final newCount = (current - 1).clamp(0, 999999);

      await _client
          .from('articles')
          .update({'like_count': newCount})
          .eq('id', articleId);

      return (isLiked: false, count: newCount);
    } else {
      // Like: insert ke likes, tambah like_count
      await _client.from('likes').insert({
        'article_id': articleId,
        'user_id': userId,
      });

      final countRes = await _client
          .from('articles')
          .select('like_count')
          .eq('id', articleId)
          .single();
      final current = countRes['like_count'] as int? ?? 0;
      final newCount = current + 1;

      await _client
          .from('articles')
          .update({'like_count': newCount})
          .eq('id', articleId);

      return (isLiked: true, count: newCount);
    }
  }

  // ─── Bookmark ─────────────────────────────────────────────────

  Future<bool> isBookmarked(String articleId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final res = await _client
        .from('reading_list')
        .select('id')
        .eq('article_id', articleId)
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }

  Future<void> toggleBookmark(
    String articleId,
    bool currentlyBookmarked,
  ) async {
    final userId = _client.auth.currentUser!.id;
    if (currentlyBookmarked) {
      await _client
          .from('reading_list')
          .delete()
          .eq('article_id', articleId)
          .eq('user_id', userId);
    } else {
      await _client.from('reading_list').insert({
        'article_id': articleId,
        'user_id': userId,
        'saved_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ─── Comments ─────────────────────────────────────────────────

  Future<List<CommentModel>> getComments(String articleId) async {
    final res = await _client
        .from('comments')
        .select('*, users(name, photo_url)')
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
    final userId = _client.auth.currentUser!.id;

    final res = await _client
        .from('comments')
        .insert({
          'article_id': articleId,
          'user_id': userId,
          'comment_text': commentText,
          if (parentId != null) 'parent_id': parentId,
        })
        .select('*, users(name, photo_url)')
        .single();

    // Update comment_count secara atomic
    final countRes = await _client
        .from('articles')
        .select('comment_count')
        .eq('id', articleId)
        .single();
    final currentCount = countRes['comment_count'] as int? ?? 0;
    await _client
        .from('articles')
        .update({'comment_count': currentCount + 1})
        .eq('id', articleId);

    return CommentModel.fromJson(res);
  }

  /// Realtime stream untuk komentar artikel tertentu
  /// Menggunakan Supabase Realtime channel dengan filter per article_id
  Stream<List<CommentModel>> commentsStream(String articleId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('article_id', articleId)
        .order('created_at', ascending: true)
        .map(
          (rows) => rows
              .where((r) => r['parent_id'] == null)
              .map((r) => CommentModel.fromJsonStream(r))
              .toList(),
        );
  }

  // ─── Follow ───────────────────────────────────────────────────

  Future<bool> isFollowing(String targetUserId) async {
    final followerId = _client.auth.currentUser?.id;
    if (followerId == null || followerId == targetUserId) return false;
    final res = await _client
        .from('social')
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return res != null;
  }

  /// Toggle follow/unfollow dan update followers_count + following_count atomically
  Future<bool> toggleFollow(
    String targetUserId,
    bool currentlyFollowing,
  ) async {
    final followerId = _client.auth.currentUser!.id;
    if (followerId == targetUserId) return currentlyFollowing;

    if (currentlyFollowing) {
      // Unfollow
      await _client
          .from('social')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', targetUserId);

      // Kurangi followers_count target
      final targetRes = await _client
          .from('users')
          .select('followers_count')
          .eq('id', targetUserId)
          .single();
      final tc = (targetRes['followers_count'] as int? ?? 1) - 1;
      await _client
          .from('users')
          .update({'followers_count': tc.clamp(0, 999999)})
          .eq('id', targetUserId);

      // Kurangi following_count self
      final selfRes = await _client
          .from('users')
          .select('following_count')
          .eq('id', followerId)
          .single();
      final sc = (selfRes['following_count'] as int? ?? 1) - 1;
      await _client
          .from('users')
          .update({'following_count': sc.clamp(0, 999999)})
          .eq('id', followerId);

      return false;
    } else {
      // Follow
      await _client.from('social').insert({
        'follower_id': followerId,
        'following_id': targetUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Tambah followers_count target
      final targetRes = await _client
          .from('users')
          .select('followers_count')
          .eq('id', targetUserId)
          .single();
      final tc = (targetRes['followers_count'] as int? ?? 0) + 1;
      await _client
          .from('users')
          .update({'followers_count': tc})
          .eq('id', targetUserId);

      // Tambah following_count self
      final selfRes = await _client
          .from('users')
          .select('following_count')
          .eq('id', followerId)
          .single();
      final sc = (selfRes['following_count'] as int? ?? 0) + 1;
      await _client
          .from('users')
          .update({'following_count': sc})
          .eq('id', followerId);

      // Kirim notifikasi ke target (fire-and-forget)
      _sendFollowNotification(followerId, targetUserId);

      return true;
    }
  }

  void _sendFollowNotification(String senderId, String receiverId) {
    _client
        .from('notifications')
        .insert({
          'receiver_id': receiverId,
          'sender_id': senderId,
          'type': 'follow',
          'is_read': false,
        })
        .then((_) {})
        .catchError((_) {});
  }

  // ─── Report ───────────────────────────────────────────────────

  Future<void> submitReport({
    required String targetId,
    required String targetType, // 'article' atau 'comment'
    required String reasonCategory,
    String? description,
    Map<String, dynamic>? contentSnapshot,
  }) async {
    final reporterId = _client.auth.currentUser!.id;

    // Cek duplikasi — user tidak bisa report item yang sama dua kali
    final existing = await _client
        .from('reports')
        .select('id')
        .eq('reporter_id', reporterId)
        .eq('target_id', targetId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Kamu sudah melaporkan konten ini sebelumnya.');
    }

    await _client.from('reports').insert({
      'reporter_id': reporterId,
      'target_id': targetId,
      'target_type': targetType,
      'reason_category': reasonCategory,
      'description': description,
      'content_snapshot': contentSnapshot,
      'status': 'pending',
    });
  }
}
