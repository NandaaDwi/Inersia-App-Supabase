import 'package:flutter/material.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class BookmarkCardWidget extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const BookmarkCardWidget({
    required this.article,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              ThumbnailWidget(url: article.thumbnail),
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
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.categoryName!,
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
                          const Icon(
                            Icons.favorite_border,
                            color: Color(0xFF6B7280),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${article.likeCount}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
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

class ThumbnailWidget extends StatelessWidget {
  final String? url;
  const ThumbnailWidget({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
  }

  Widget _placeholder() => Container(
    width: 100,
    height: 120,
    color: const Color(0xFF1F2937),
    child: const Icon(Icons.image_outlined, color: Color(0xFF374151), size: 28),
  );
}
