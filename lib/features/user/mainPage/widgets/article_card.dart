import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/main_page_provider.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class ArticleCard extends ConsumerWidget {
  final ArticleModel article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = supabaseConfig.client.auth.currentUser?.id ?? '';

    final likeCountAsync = ref.watch(
      articleLikeCountStreamProvider(article.id),
    );

    final likeStatusAsync = ref.watch(
      cardLikeStatusProvider((article.id, currentUserId)),
    );

    final likeCount = likeCountAsync.when(
      data: (c) => c,
      loading: () => article.likeCount,
      error: (_, __) => article.likeCount,
    );

    final isLiked = likeStatusAsync.when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: article.thumbnail != null
                      ? Image.network(
                          article.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF161616).withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppDateUtils.formatDate(article.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _extractExcerpt(article.content),
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

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
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          key: ValueKey(likeCount),
                          '$likeCount',
                          style: TextStyle(
                            color: isLiked
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF6B7280),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.commentCount}',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Read More',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractExcerpt(String content) {
    if (content.isEmpty) return '';
    try {
      final clean = content
          .replaceAll(RegExp(r'\[|\]|\{|\}|"insert":"|"attributes":[^,}]+'), '')
          .replaceAll('"', '')
          .replaceAll(RegExp(r',\s*'), ' ')
          .trim();
      return clean.length > 120 ? '${clean.substring(0, 120)}...' : clean;
    } catch (_) {
      return content.length > 120 ? '${content.substring(0, 120)}...' : content;
    }
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF111827),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF374151), size: 40),
      ),
    );
  }
}
