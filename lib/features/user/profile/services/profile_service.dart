import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/user_model.dart';

class ProfileData {
  final UserModel user;
  final int publishedCount;
  final int draftCount;

  const ProfileData({
    required this.user,
    required this.publishedCount,
    required this.draftCount,
  });
}

class ProfileService {
  final _client = supabaseConfig.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  Future<ProfileData> getProfile() async {
    final uid = _currentUserId;

    final results = await Future.wait<dynamic>([
      _client.from('users').select().eq('id', uid).single(),
      _client
          .from('articles')
          .select('id')
          .eq('author_id', uid)
          .eq('status', 'published')
          .count(),
      _client
          .from('articles')
          .select('id')
          .eq('author_id', uid)
          .eq('status', 'draft')
          .count(),
    ]);

    final user = UserModel.fromJson(results[0] as Map<String, dynamic>);
    final published = (results[1] as dynamic).count as int;
    final draft = (results[2] as dynamic).count as int;

    return ProfileData(
      user: user,
      publishedCount: published,
      draftCount: draft,
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
