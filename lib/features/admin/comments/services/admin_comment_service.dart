import 'package:inersia_supabase/config/supabase_config.dart';

class AdminCommentItem {
  final String id;
  final String articleId;
  final String articleTitle;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String commentText;
  final DateTime createdAt;

  const AdminCommentItem({
    required this.id,
    required this.articleId,
    required this.articleTitle,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.commentText,
    required this.createdAt,
  });

  factory AdminCommentItem.fromJson(Map<String, dynamic> json) {
    final article = json['article'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    return AdminCommentItem(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      articleTitle: article?['title'] as String? ?? '(Artikel dihapus)',
      userId: json['user_id'] as String,
      userName: user?['name'] as String? ?? 'Pengguna',
      userPhoto: user?['photo_url'] as String?,
      commentText: json['comment_text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminCommentService {
  final _client = supabaseConfig.client;

  static const int _pageSize = 20;

  Future<List<AdminCommentItem>> getComments({
    int page = 0,
    String query = '',
  }) async {
    final from = page * _pageSize;
    final to = from + _pageSize - 1;

    var req = _client
        .from('comments')
        .select('*, article:article_id(title), user:user_id(name, photo_url)');

    if (query.isNotEmpty) {
      req = req.ilike('comment_text', '%$query%');
    }

    final res = await req.order('created_at', ascending: false).range(from, to);

    return (res as List).map((e) => AdminCommentItem.fromJson(e)).toList();
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comment_likes').delete().eq('comment_id', commentId);
    await _client.from('comments').delete().eq('id', commentId);
  }

  Future<void> bulkDeleteComments(List<String> commentIds) async {
    if (commentIds.isEmpty) return;

    await _client
        .from('comment_likes')
        .delete()
        .inFilter('comment_id', commentIds);

    await _client.from('comments').delete().inFilter('id', commentIds);
  }

  Future<void> banUser(String userId) async {
    await _client.from('users').update({'status': 'banned'}).eq('id', userId);
  }

  Future<void> sendWarning({
    required String targetUserId,
    required String commentText,
    required String articleTitle,
  }) async {
    final adminId = _client.auth.currentUser!.id;

    await _client.from('notifications').insert({
      'receiver_id': targetUserId,
      'sender_id': adminId,
      'type': 'warning',
      'article_id': null,
      'is_read': false,
      'message':
          'Komentar Anda melanggar pedoman komunitas. Pelanggaran berulang dapat mengakibatkan pembatasan akun.',
    });
  }
}
