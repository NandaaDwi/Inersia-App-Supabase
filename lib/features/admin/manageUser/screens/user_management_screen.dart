import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/admin_user_provider.dart';
import 'user_detail_screen.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: searchController,
              onChanged: (val) => ref.read(userSearchProvider.notifier).state = val,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cari nama, username, atau email...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3F7AF6), size: 20),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isActive = user.status == 'active';
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1E1E),
                          image: user.photoUrl != null
                              ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: user.photoUrl == null
                            ? Center(
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text("@${user.username}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(color: Color(0xFF3F7AF6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? Icons.verified_user_rounded : Icons.block_flipped,
                            size: 18,
                            color: isActive ? Colors.greenAccent : Colors.redAccent,
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3F7AF6))),
              error: (e, _) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageButton(
                  Icons.chevron_left,
                  currentPage > 0 ? () => ref.read(userPageProvider.notifier).state-- : null,
                ),
                const SizedBox(width: 16),
                Text(
                  "Halaman ${currentPage + 1}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(width: 16),
                _buildPageButton(
                  Icons.chevron_right,
                  () => ref.read(userPageProvider.notifier).state++,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: onPressed != null ? Colors.white : Colors.grey, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}