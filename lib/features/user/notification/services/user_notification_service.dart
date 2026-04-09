import 'package:inersia_supabase/config/supabase_config.dart';

class UserNotificationService {
  Future<void> markNotificationRead(String id) async {
    await supabaseConfig.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllNotificationsRead() async {
    final uid = supabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return;

    await supabaseConfig.client
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', uid)
        .eq('is_read', false);
  }

  Future<Map<String, dynamic>> fetchArticleDetails(String articleId) async {
    return await supabaseConfig.client
        .from('articles')
        .select('''
          id, author_id, title, thumbnail, status, category_id,
          estimated_reading, like_count, comment_count, view_count,
          created_at, updated_at,
          users:author_id(name, photo_url),
          categories:category_id(name)
        ''')
        .eq('id', articleId)
        .single();
  }
}
