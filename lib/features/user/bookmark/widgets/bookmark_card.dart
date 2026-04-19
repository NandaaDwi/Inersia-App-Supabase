import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/main_page_provider.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class BookmarkCard extends ConsumerWidget {
  final ArticleModel article;
  final VoidCallback onRemove;

  const BookmarkCard({
    super.key,
    required this.article,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = supabaseConfig.client.auth.currentUser?.id ?? '';
    final likeKey = (article.id, uid);

    final isLiked = ref
        .watch(cardLikeStatusProvider(likeKey))
        .maybeWhen(data: (value) => value, orElse: () => false);

    final likeCount = ref
        .watch(articleLikeCountStreamProvider(article.id))
        .maybeWhen(data: (value) => value, orElse: () => article.likeCount);

    return Dismissible(
      key: ValueKey(article.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_remove_outlined,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onRemove();
        return false;
      },
      child: GestureDetector(
        onTap: () {
          ref.invalidate(cardLikeStatusProvider(likeKey));
          context.push('/article/${article.id}', extra: article);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF161616), width: 0.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              _BookmarkThumbnail(url: article.thumbnail),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.categoryName != null)
                        _CategoryBadge(name: article.categoryName!),

                      Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF6B7280),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              article.authorName,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF4B5563),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${article.estimatedReading} menit baca',
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11,
                            ),
                          ),
                          const Text(
                            ' · ',
                            style: TextStyle(
                              color: Color(0xFF2D2D2D),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            AppDateUtils.formatDate(article.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              key: ValueKey(isLiked),
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6B7280),
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likeCount',
                            style: TextStyle(
                              color: isLiked
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF6B7280),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${article.commentCount}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF2563EB),
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkThumbnail extends StatelessWidget {
  final String? url;
  const _BookmarkThumbnail({this.url});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
    child: url != null
        ? Image.network(
            url!,
            width: 100,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          )
        : _placeholder(),
  );

  Widget _placeholder() => Container(
    width: 100,
    height: 120,
    color: const Color(0xFF161616),
    child: const Icon(Icons.image_outlined, color: Color(0xFF374151), size: 28),
  );
}

class _CategoryBadge extends StatelessWidget {
  final String name;
  const _CategoryBadge({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF1E3A5F),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      name,
      style: const TextStyle(
        color: Color(0xFF60A5FA),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
