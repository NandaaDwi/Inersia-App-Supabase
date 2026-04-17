import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inersia_supabase/models/comment_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';
import 'package:inersia_supabase/utils/moderation_client.dart';

class ReadCommentItem extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final VoidCallback onReport;

  const ReadCommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final text = ModerationClient.censorCommentSync(comment.commentText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/user/${comment.userId}'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1F2937),
              backgroundImage: comment.userPhoto != null
                  ? NetworkImage(comment.userPhoto!)
                  : null,
              child: comment.userPhoto == null
                  ? Text(
                      comment.userName.isNotEmpty
                          ? comment.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.timeAgo(comment.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (comment.userId != currentUserId)
                      GestureDetector(
                        onTap: onReport,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz,
                            color: Color(0xFF4B5563),
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
