import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class ReadAuthorRow extends StatelessWidget {
  final ArticleModel article;
  final String currentUserId;
  final AsyncValue<bool> followState;
  final VoidCallback onFollowToggle;
  final VoidCallback onAuthorTap;

  const ReadAuthorRow({
    super.key,
    required this.article,
    required this.currentUserId,
    required this.followState,
    required this.onFollowToggle,
    required this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAuthorTap,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1F2937),
            backgroundImage: article.authorPhoto != null
                ? NetworkImage(article.authorPhoto!)
                : null,
            child: article.authorPhoto == null
                ? Text(
                    article.authorName.isNotEmpty
                        ? article.authorName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.authorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${AppDateUtils.formatDate(article.createdAt)}  •  '
                '${article.estimatedReading} menit baca',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
        ),
        if (article.authorId != currentUserId)
          followState.when(
            data: (isFollowing) => _ReadFollowButton(
              isFollowing: isFollowing,
              onTap: onFollowToggle,
            ),
            loading: () => const SizedBox(
              width: 80,
              height: 32,
              child: LinearProgressIndicator(color: Color(0xFF2563EB)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _ReadFollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;
  const _ReadFollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFollowing ? Colors.transparent : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFollowing
              ? const Color(0xFF374151)
              : const Color(0xFF2563EB),
        ),
      ),
      child: Text(
        isFollowing ? 'Mengikuti' : 'Ikuti',
        style: TextStyle(
          color: isFollowing ? const Color(0xFF9CA3AF) : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
