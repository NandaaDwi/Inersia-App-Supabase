import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageUser/services/admin_user_service.dart';
import 'package:inersia_supabase/models/user_model.dart';

final adminUserServiceProvider = Provider((ref) => AdminUserService());

final userSearchProvider = StateProvider<String>((ref) => '');
final userPageProvider = StateProvider<int>((ref) => 0);

final adminUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final service = ref.watch(adminUserServiceProvider);
  final search = ref.watch(userSearchProvider);
  final page = ref.watch(userPageProvider);

  return service.getUsers(page: page, limit: 10, query: search);
});
