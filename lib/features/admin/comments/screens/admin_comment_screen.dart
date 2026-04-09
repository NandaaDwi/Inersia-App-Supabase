import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/comments/providers/admin_comment_provider.dart';
import 'package:inersia_supabase/features/admin/comments/services/admin_comment_service.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class AdminCommentScreen extends ConsumerStatefulWidget {
  const AdminCommentScreen({super.key});

  @override
  ConsumerState<AdminCommentScreen> createState() => _AdminCommentScreenState();
}

class _AdminCommentScreenState extends ConsumerState<AdminCommentScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(commentAdminProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentAdminProvider);
    final isSelectMode = state.isSelectMode;
    final selectedCount = state.selectedIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: isSelectMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
                onPressed: () =>
                    ref.read(commentAdminProvider.notifier).exitSelectMode(),
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
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
                  ? () =>
                        ref.read(commentAdminProvider.notifier).clearSelection()
                  : () => ref.read(commentAdminProvider.notifier).selectAll(),
              child: Text(
                selectedCount == state.items.length
                    ? 'Batal Pilih Semua'
                    : 'Pilih Semua',
                style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
              tooltip: 'Hapus Terpilih',
              onPressed: selectedCount == 0
                  ? null
                  : () => _confirmBulkDelete(context, selectedCount),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(
                Icons.checklist_rounded,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
              tooltip: 'Pilih Komentar',
              onPressed: () =>
                  ref.read(commentAdminProvider.notifier).enterSelectMode(),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              onChanged: (v) =>
                  ref.read(commentSearchRawProvider.notifier).state = v,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari isi komentar...',
                hintStyle: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFF111827),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          if (isSelectMode && selectedCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2563EB).withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '$selectedCount komentar dipilih',
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmBulkDelete(context, selectedCount),
                    child: const Text(
                      'Hapus Semua',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  )
                : state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFF6B7280),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Gagal memuat komentar',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(commentAdminProvider.notifier).refresh(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : state.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF374151),
                          size: 56,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada komentar',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF7C3AED),
                    backgroundColor: const Color(0xFF111827),
                    onRefresh: () =>
                        ref.read(commentAdminProvider.notifier).refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: state.items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        if (i == state.items.length) {
                          return state.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF7C3AED),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 8);
                        }
                        final item = state.items[i];
                        final isSelected = state.selectedIds.contains(item.id);

                        return _CommentCard(
                          item: item,
                          isSelectMode: isSelectMode,
                          isSelected: isSelected,
                          onToggle: () => ref
                              .read(commentAdminProvider.notifier)
                              .toggleSelection(item.id),
                          onDelete: () => _confirmDelete(context, item),
                          onBan: () => _confirmBan(context, item),
                          onWarn: () => _confirmWarn(context, item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete(BuildContext context, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Komentar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Hapus $count komentar yang dipilih? Tindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(commentAdminProvider.notifier).bulkDelete();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$count komentar berhasil dihapus.'),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminCommentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Komentar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Komentar ini akan dihapus:',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.commentText,
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(commentAdminProvider.notifier).deleteComment(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBan(BuildContext context, AdminCommentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ban Pengguna',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${item.userName}" akan dinonaktifkan dan tidak bisa login. Lanjutkan?',
          style: const TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(commentAdminProvider.notifier).banUser(item.userId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${item.userName}" berhasil di-ban.'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ban User',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmWarn(BuildContext context, AdminCommentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kirim Peringatan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi peringatan akan dikirim ke "${item.userName}" terkait komentar mereka.',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                height: 1.5,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${item.commentText}"',
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontSize: 12,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(commentAdminProvider.notifier)
                  .sendWarning(
                    targetUserId: item.userId,
                    commentText: item.commentText,
                    articleTitle: item.articleTitle,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Peringatan terkirim ke "${item.userName}".'),
                  backgroundColor: const Color(0xFFD97706),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Kirim Peringatan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final AdminCommentItem item;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onBan;
  final VoidCallback onWarn;

  const _CommentCard({
    required this.item,
    required this.isSelectMode,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
    required this.onBan,
    required this.onWarn,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectMode ? onToggle : null,
      onLongPress: !isSelectMode ? onToggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A5F).withOpacity(0.6)
              : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB).withOpacity(0.5)
                : const Color(0xFF1F2937),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelectMode)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
              ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          color: Color(0xFF60A5FA),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.articleTitle,
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF1F2937),
                        backgroundImage: item.userPhoto != null
                            ? NetworkImage(item.userPhoto!)
                            : null,
                        child: item.userPhoto == null
                            ? Text(
                                item.userName.isNotEmpty
                                    ? item.userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              AppDateUtils.timeAgo(item.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!isSelectMode)
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') onDelete();
                            if (v == 'ban') onBan();
                            if (v == 'warn') onWarn();
                          },
                          color: const Color(0xFF1F2937),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF6B7280),
                            size: 18,
                          ),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'warn',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706),
                                    size: 16,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Kirim Peringatan',
                                    style: TextStyle(
                                      color: Color(0xFFD97706),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFEF4444),
                                    size: 16,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Hapus Komentar',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'ban',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.block_outlined,
                                    color: Color(0xFFDC2626),
                                    size: 16,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Ban Pengguna',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    item.commentText,
                    style: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
