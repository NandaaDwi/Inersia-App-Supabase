import 'package:inersia_supabase/config/supabase_config.dart';

class AdminReportItem {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetId;
  final String targetType;
  final String reasonCategory;
  final String? description;
  final Map<String, dynamic>? contentSnapshot;
  final String status;
  final String? adminId;
  final String? adminNote;
  final DateTime createdAt;

  const AdminReportItem({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetType,
    required this.reasonCategory,
    this.description,
    this.contentSnapshot,
    required this.status,
    this.adminId,
    this.adminNote,
    required this.createdAt,
  });

  factory AdminReportItem.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>?;
    return AdminReportItem(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reporterName: reporter?['name'] as String? ?? 'Pengguna',
      targetId: json['target_id'] as String,
      targetType: json['target_type'] as String? ?? 'article',
      reasonCategory: json['reason_category'] as String? ?? '',
      description: json['description'] as String?,
      contentSnapshot: json['content_snapshot'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'pending',
      adminId: json['admin_id'] as String?,
      adminNote: json['admin_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminReportService {
  final _client = supabaseConfig.client;

  static const int _pageSize = 15;

  Future<List<AdminReportItem>> getReports({
    int page = 0,
    String? status,
    String? targetType,
  }) async {
    final from = page * _pageSize;
    final to = from + _pageSize - 1;

    var query = _client.from('reports').select('*, reporter:reporter_id(name)');

    if (status != null) query = query.eq('status', status);
    if (targetType != null) query = query.eq('target_type', targetType);

    final res = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (res as List).map((e) => AdminReportItem.fromJson(e)).toList();
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNote,
  }) async {
    final adminId = _client.auth.currentUser!.id;
    await _client
        .from('reports')
        .update({
          'status': status,
          'admin_id': adminId,
          if (adminNote != null) 'admin_note': adminNote,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId);
  }

  Future<void> deleteArticle(String articleId) async {
    await _client.from('article_tags').delete().eq('article_id', articleId);
    await _client.from('likes').delete().eq('article_id', articleId);
    await _client.from('reading_list').delete().eq('article_id', articleId);
    await _client.from('comments').delete().eq('article_id', articleId);
    await _client.from('articles').delete().eq('id', articleId);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comment_likes').delete().eq('comment_id', commentId);
    await _client.from('comments').delete().eq('id', commentId);
  }

  static Future<void> notifyAdminsOfNewReport({
    required String reportId,
    required String senderId,
    required String targetType,
  }) async {
    final client = supabaseConfig.client;

    final admins = await client.from('users').select('id').eq('role', 'admin');

    if ((admins as List).isEmpty) return;

    final notifications = admins
        .map(
          (a) => {
            'receiver_id': a['id'] as String,
            'sender_id': senderId,
            'type': 'report_new',
            'article_id': null,
            'is_read': false,
          },
        )
        .toList();

    await client.from('notifications').insert(notifications);
  }

  Future<void> markNotificationRead(String notifId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notifId);
  }

  Future<void> markAllNotificationsRead(String adminId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', adminId)
        .eq('is_read', false);
  }
}
