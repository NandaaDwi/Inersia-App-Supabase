import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/tag_model.dart';

class AdminTagService {
  final _client = supabaseConfig.client;

  Future<List<TagModel>> getTags({int page = 0, String query = ''}) async {
    final from = page * 10;
    final to = from + 9;

    var request = _client.from('tags').select();

    if (query.isNotEmpty) {
      request = request.or('name.ilike.%$query%');
    }

    final res = await request.order('name', ascending: true).range(from, to);

    return (res as List).map((e) => TagModel.fromJson(e)).toList();
  }

  Future<void> upsertTag(String? id, String name) async {
    final data = {'name': name};
    if (id == null) {
      await _client.from('tags').insert(data);
    } else {
      await _client.from('tags').update(data).eq('id', id);
    }
  }

  Future<void> deleteTag(String id) async {
    await _client.from('tags').delete().eq('id', id);
  }
}
