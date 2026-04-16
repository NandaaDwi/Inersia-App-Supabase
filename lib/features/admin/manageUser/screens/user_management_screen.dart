import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageUser/providers/admin_user_provider.dart';
import 'package:inersia_supabase/features/admin/manageUser/widgets/admin_user_card.dart';
import 'package:inersia_supabase/features/admin/manageUser/widgets/admin_user_search_bar.dart';
import 'package:inersia_supabase/features/admin/manageUser/widgets/admin_user_pagination.dart';

class UserManagementScreen extends HookConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final searchCtrl = useTextEditingController();
    final currentPage = ref.watch(userPageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kelola Pengguna',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF1F2937)),
        ),
      ),
      body: Column(
        children: [
          AdminUserSearchBar(controller: searchCtrl),
          Expanded(
            child: usersAsync.when(
              data: (users) => users.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => AdminUserCard(user: users[i]),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ),
          ),
          AdminUserPagination(currentPage: currentPage),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Color(0xFF374151), size: 52),
          SizedBox(height: 12),
          Text(
            'Tidak ada pengguna',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
