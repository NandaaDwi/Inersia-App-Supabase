import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/admin_user_provider.dart';
import '../widgets/user_list.dart';
import '../widgets/user_search_field.dart';
import '../widgets/user_pagination.dart';

class UserManagementScreen extends HookConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final searchController = useTextEditingController();
    final currentPage = ref.watch(userPageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Kelola Pengguna",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          UserSearchField(controller: searchController),
          Expanded(
            child: usersAsync.when(
              data: (users) => UserList(users: users),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF3F7AF6)),
              ),
              error: (e, _) => Center(
                child: Text(
                  "Error: $e",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          UserPagination(currentPage: currentPage),
        ],
      ),
    );
  }
}
