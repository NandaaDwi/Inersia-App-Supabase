import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/category_model.dart';

class AdminCategoryService {
  final _client = supabaseConfig.client;

  Future<List<CategoryModel>> getCategories({
    int page = 0,
    String query = '',
  }) async {
    final from = page * 10;
    final to = from + 9;

    var request = _client.from('categories').select();

    if (query.isNotEmpty) {
      request = request.or('name.ilike.%$query%');
    }

    final res = await request.order('name', ascending: true).range(from, to);

    return (res as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<void> upsertCategory(String? id, String name) async {
    final data = {'name': name};
    if (id == null) {
      await _client.from('categories').insert(data);
    } else {
      await _client.from('categories').update(data).eq('id', id);
    }
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final res = await _client
        .from('categories')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (res == null) return null;
    return CategoryModel.fromJson(res);
  }
}
