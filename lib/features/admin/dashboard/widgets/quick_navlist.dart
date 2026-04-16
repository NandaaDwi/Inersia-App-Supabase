import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';

class QuickNavList extends StatelessWidget {
  const QuickNavList({super.key});

  static const items = [
    (
      Icons.manage_accounts_outlined,
      'Manajemen User',
      '/manageUser',
      Color(0xFF3F7AF6),
    ),
    (
      Icons.library_books_outlined,
      'Manajemen Artikel',
      '/manageArticles',
      Color(0xFF059669),
    ),
    (
      Icons.category_outlined,
      'Kategori & Tag',
      '/manageCategoryTag',
      Color(0xFFD97706),
    ),
    (
      Icons.chat_bubble_outline_rounded,
      'Komentar',
      '/manageComments',
      Color(0xFF7C3AED),
    ),
    (Icons.report_problem_outlined, 'Laporan', '/reports', Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: items.map((item) => _NavTile(item: item)).toList());
  }
}

class _NavTile extends StatelessWidget {
  final dynamic item;
  const _NavTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: item.$4.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.$1, color: item.$4, size: 18),
        ),
        title: Text(
          item.$2,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF374151),
          size: 18,
        ),
        onTap: () => context.push(item.$3),
      ),
    );
  }
}

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(
          Icons.logout_rounded,
          color: Color(0xFFEF4444),
          size: 18,
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        onTap: () => _confirm(context, ref),
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
