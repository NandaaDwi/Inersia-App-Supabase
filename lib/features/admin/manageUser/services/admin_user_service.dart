import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/user_model.dart';

class AdminUserService {
  final _client = supabaseConfig.client;

  Future<List<UserModel>> getUsers({
    required int page,
    required int limit,
    String query = '',
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    var request = _client
        .from('users')
        .select(
          'id, name, username, email, bio, role, status, photo_url, followers_count, following_count',
        ).eq('role', 'user');

    if (query.isNotEmpty) {
      request = request.or(
        'name.ilike.%$query%,username.ilike.%$query%,email.ilike.%$query%',
      );
    }

    final List res = await request
        .order('created_at', ascending: false)
        .range(from, to);

    return res.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', id);
  }
}
