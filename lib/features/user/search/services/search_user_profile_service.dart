import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/user_model.dart';

class SearchUserProfileService {
  final _client = supabaseConfig.client;

  Future<UserModel> getUserProfile(String userId) async {
    final res = await _client.from('users').select().eq('id', userId).single();
    return UserModel.fromJson(res);
  }

  Future<List<ArticleModel>> getUserArticles(String userId) async {
    final res = await _client
        .from('articles')
        .select('''
          *,
          users:author_id(name,photo_url),
          categories:category_id(name)
        ''')
        .eq('author_id', userId)
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .limit(20);

    return (res as List).map((e) => ArticleModel.fromJson(e)).toList();
  }
}
