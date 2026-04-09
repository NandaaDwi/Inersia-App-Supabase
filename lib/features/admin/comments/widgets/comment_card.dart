import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/comments/providers/admin_comment_provider.dart';
import 'package:inersia_supabase/features/admin/comments/services/admin_comment_service.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class CommentCard extends ConsumerWidget {
  final AdminCommentItem item;
  final bool isSelectMode;
  final bool isSelected;

  const CommentCard({
    super.key,
    required this.item,
    required this.isSelectMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isSelectMode ? () => _toggle(ref) : null,
      onLongPress: !isSelectMode ? () => _toggle(ref) : null,
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
            if (isSelectMode) _buildCheckbox(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArticleTag(title: item.articleTitle),
                  const SizedBox(height: 8),
                  _UserHeader(item: item, isSelectMode: isSelectMode),
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

  void _toggle(WidgetRef ref) =>
      ref.read(commentAdminProvider.notifier).toggleSelection(item.id);

  Widget _buildCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 2),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
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
    );
  }
}

class _ArticleTag extends StatelessWidget {
  final String title;
  const _ArticleTag({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              title,
              style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserHeader extends ConsumerWidget {
  final AdminCommentItem item;
  final bool isSelectMode;
  const _UserHeader({required this.item, required this.isSelectMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF1F2937),
          backgroundImage: item.userPhoto != null
              ? NetworkImage(item.userPhoto!)
              : null,
          child: item.userPhoto == null
              ? Text(
                  item.userName[0],
                  style: const TextStyle(color: Colors.white, fontSize: 11),
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
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
              ),
            ],
          ),
        ),
        if (!isSelectMode)
          PopupMenuButton<String>(
            color: const Color(0xFF1F2937),
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            onSelected: (val) => _handleAction(context, ref, val),
            itemBuilder: (_) => [
              _menuItem(
                'warn',
                Icons.warning_amber_rounded,
                'Peringatan',
                const Color(0xFFD97706),
              ),
              _menuItem(
                'delete',
                Icons.delete_outline,
                'Hapus',
                const Color(0xFFEF4444),
              ),
              _menuItem(
                'ban',
                Icons.block_outlined,
                'Ban User',
                const Color(0xFFDC2626),
              ),
            ],
          ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String val,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'delete') {
      ref.read(commentAdminProvider.notifier).deleteComment(item.id);
    } else if (action == 'ban') {
      ref.read(commentAdminProvider.notifier).banUser(item.userId);
    } else if (action == 'warn') {
      ref
          .read(commentAdminProvider.notifier)
          .sendWarning(
            targetUserId: item.userId,
            commentText: item.commentText,
            articleTitle: item.articleTitle,
          );
    }
  }
}
