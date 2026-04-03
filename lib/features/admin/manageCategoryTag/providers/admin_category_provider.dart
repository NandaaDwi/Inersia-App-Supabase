import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_category_service.dart';
import 'package:inersia_supabase/models/category_model.dart';

final categoryServiceProvider = Provider((ref) => AdminCategoryService());
final catSearchProvider = StateProvider<String>((ref) => '');
final catPageProvider = StateProvider<int>((ref) => 0);

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  final query = ref.watch(catSearchProvider);
  final page = ref.watch(catPageProvider);
  return ref
      .watch(categoryServiceProvider)
      .getCategories(page: page, query: query);
});
