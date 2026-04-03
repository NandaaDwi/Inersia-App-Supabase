import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_tag_service.dart';
import 'package:inersia_supabase/models/tag_model.dart';

final tagServiceProvider = Provider((ref) => AdminTagService());
final tagSearchProvider = StateProvider<String>((ref) => '');
final tagPageProvider = StateProvider<int>((ref) => 0);

final tagsProvider = FutureProvider<List<TagModel>>((ref) {
  final query = ref.watch(tagSearchProvider);
  final page = ref.watch(tagPageProvider);
  return ref.watch(tagServiceProvider).getTags(page: page, query: query);
});
