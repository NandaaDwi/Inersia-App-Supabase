import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/comments/providers/admin_comment_provider.dart';

class CommentAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CommentAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commentAdminProvider);
    final isSelectMode = state.isSelectMode;
    final selectedCount = state.selectedIds.length;

    return AppBar(
      backgroundColor: const Color(0xFF0A0A0F),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          isSelectMode ? Icons.close : Icons.arrow_back_ios_new,
          color: Colors.white,
          size: isSelectMode ? 22 : 18,
        ),
        onPressed: () {
          if (isSelectMode) {
            ref.read(commentAdminProvider.notifier).exitSelectMode();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        isSelectMode ? '$selectedCount dipilih' : 'Manajemen Komentar',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      actions: [
        if (isSelectMode) ...[
          TextButton(
            onPressed: selectedCount == state.items.length
                ? () => ref.read(commentAdminProvider.notifier).clearSelection()
                : () => ref.read(commentAdminProvider.notifier).selectAll(),
            child: Text(
              selectedCount == state.items.length ? 'Batal' : 'Semua',
              style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            onPressed: selectedCount == 0
                ? null
                : () => _bulkDelete(context, ref, selectedCount),
          ),
        ] else
          IconButton(
            icon: const Icon(
              Icons.checklist_rounded,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
            onPressed: () =>
                ref.read(commentAdminProvider.notifier).enterSelectMode(),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _bulkDelete(BuildContext context, WidgetRef ref, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Hapus Komentar',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Hapus $count komentar terpilih?',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(commentAdminProvider.notifier).bulkDelete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
