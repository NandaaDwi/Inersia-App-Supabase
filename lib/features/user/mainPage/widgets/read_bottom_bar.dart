import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';

class ReadBottomBar extends StatelessWidget {
  final AsyncValue<LikeState> likeState;
  final AsyncValue<bool> bookmarkState;
  final AsyncValue<ArticleStats> statsAsync;
  final int fallbackLikeCount;
  final bool isOwnArticle;
  final VoidCallback onLike;
  final VoidCallback onBookmark;

  const ReadBottomBar({
    super.key,
    required this.likeState,
    required this.bookmarkState,
    required this.statsAsync,
    required this.fallbackLikeCount,
    required this.isOwnArticle,
    required this.onLike,
    required this.onBookmark,
  });

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border:
            Border(top: BorderSide(color: Color(0xFF1F2937), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Like ────────────────────────────────────────
              likeState.when(
                data: (like) => statsAsync.when(
                  data: (stats) => GestureDetector(
                    onTap: onLike,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        key: ValueKey(like.isLiked),
                        children: [
                          Icon(
                            like.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: like.isLiked
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6B7280),
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmt(stats.likeCount),
                            style: TextStyle(
                              color: like.isLiked
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF9CA3AF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => Row(children: [
                    const Icon(Icons.favorite_border,
                        color: Color(0xFF6B7280), size: 26),
                    const SizedBox(width: 8),
                    Text(_fmt(fallbackLikeCount),
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ]),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(color: Color(0xFF2563EB)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // ── Bookmark ─────────────────────────────────────
              if (!isOwnArticle)
                bookmarkState.when(
                  data: (saved) => GestureDetector(
                    onTap: onBookmark,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        key: ValueKey(saved),
                        saved
                            ? Icons.bookmark
                            : Icons.bookmark_border_rounded,
                        color: saved
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF6B7280),
                        size: 26,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(width: 26, height: 26),
                  error: (_, __) => const SizedBox.shrink(),
                )
              else
                const Icon(Icons.bookmark_border_rounded,
                    color: Color(0xFF1F2937), size: 26),
            ],
          ),
        ),
      ),
    );
  }
}