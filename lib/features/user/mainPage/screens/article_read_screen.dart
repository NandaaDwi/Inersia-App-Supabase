// lib/features/user/mainPage/screens/article_read_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_app_bar.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_author_row.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_bottom_bar.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_comment_header.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_comment_input.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_comment_item.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_quill_content.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_report_sheet.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_stats_box.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/read_tag_chips.dart';
import 'package:inersia_supabase/models/article_model.dart';

class ArticleReadScreen extends HookConsumerWidget {
  final ArticleModel article;
  const ArticleReadScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        supabaseConfig.client.auth.currentUser?.id ?? '';

    // Controller komentar — di sini supaya dispose diurus hooks
    final commentCtrl = useTextEditingController();
    final commentFocus = useFocusNode();

    final likeKey = (article.id, currentUserId);
    final bookmarkKey = (article.id, currentUserId);

    // Watch hanya state yang dipakai di level ini
    final likeState = ref.watch(likeProvider(likeKey));
    final bookmarkState = ref.watch(bookmarkProvider(bookmarkKey));
    final statsAsync = ref.watch(articleStatsStreamProvider(article.id));

    // articleDetailProvider — fetch sekali, bukan stream → ringan
    final articleAsync = ref.watch(articleDetailProvider(article.id));

    return articleAsync.when(
      loading: () => ReadLoadingScaffold(article: article),
      error: (_, __) => ReadErrorScaffold(
        article: article,
        onRetry: () => ref.invalidate(articleDetailProvider(article.id)),
      ),
      data: (full) {
        final followKey = (full.authorId, currentUserId);
        final followState = ref.watch(followProvider(followKey));

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          // ── Body ───────────────────────────────────────────
          body: CustomScrollView(
            // physics: ClampingScrollPhysics → sedikit lebih ringan dari default
            physics: const ClampingScrollPhysics(),
            slivers: [
              ReadAppBar(
                article: full,
                onBack: () => Navigator.pop(context),
                onReport: () => showReadReportSheet(
                  context: context,
                  ref: ref,
                  targetId: full.id,
                  targetType: 'article',
                  snapshot: full.toJson(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author + follow
                      ReadAuthorRow(
                        article: full,
                        currentUserId: currentUserId,
                        followState: followState,
                        onFollowToggle: () => ref
                            .read(followProvider(followKey).notifier)
                            .toggle(),
                        onAuthorTap: () =>
                            context.push('/user/${full.authorId}'),
                      ),
                      const SizedBox(height: 24),

                      // ── Konten dengan format Quill asli ────
                      // Menggantikan plain-text _parseContent yang menghilangkan
                      // formatting (justify, bold, heading, dll)
                      ReadQuillContent(content: full.content),
                      const SizedBox(height: 16),

                      // Tags
                      if (full.tags.isNotEmpty) ...[
                        ReadTagChips(tags: full.tags),
                        const SizedBox(height: 24),
                      ],

                      // Stats (stream realtime)
                      statsAsync.when(
                        data: (s) => ReadStatsBox(
                          likeCount: s.likeCount,
                          viewCount: s.viewCount,
                          commentCount: s.commentCount,
                        ),
                        loading: () => const SizedBox(
                          height: 72,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),

                      // ── Komentar ───────────────────────────
                      // Dipisah ke widget sendiri agar section komentar
                      // tidak ikut rebuild saat stats atau like berubah
                      _CommentSection(
                        articleId: full.id,
                        currentUserId: currentUserId,
                        commentCtrl: commentCtrl,
                        commentFocus: commentFocus,
                        onReport: (c) => showReadReportSheet(
                          context: context,
                          ref: ref,
                          targetId: c.id,
                          targetType: 'comment',
                          snapshot: {
                            'comment_text': c.commentText,
                            'user_id': c.userId,
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Bar ─────────────────────────────────────
          bottomNavigationBar: ReadBottomBar(
            likeState: likeState,
            bookmarkState: bookmarkState,
            statsAsync: statsAsync,
            fallbackLikeCount: article.likeCount,
            isOwnArticle: full.authorId == currentUserId,
            onLike: () =>
                ref.read(likeProvider(likeKey).notifier).toggle(),
            onBookmark: () =>
                ref.read(bookmarkProvider(bookmarkKey).notifier).toggle(),
          ),
        );
      },
    );
  }
}

// ─── Comment Section ──────────────────────────────────────────
// Widget terpisah agar tidak ikut rebuild saat parent rebuild.
// Hanya rebuild saat commentsAsync atau commentWrite berubah.

class _CommentSection extends ConsumerWidget {
  final String articleId;
  final String currentUserId;
  final TextEditingController commentCtrl;
  final FocusNode commentFocus;
  final void Function(dynamic comment) onReport;

  const _CommentSection({
    required this.articleId,
    required this.currentUserId,
    required this.commentCtrl,
    required this.commentFocus,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream komentar realtime
    final commentsAsync = ref.watch(commentsRealtimeProvider(articleId));
    final commentWrite = ref.watch(commentWriteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReadCommentsHeader(commentsAsync: commentsAsync),
        const SizedBox(height: 16),

        // Input komentar
        ReadCommentInput(
          controller: commentCtrl,
          focusNode: commentFocus,
          isSending: commentWrite.isLoading,
          onSend: () async {
            final text = commentCtrl.text.trim();
            if (text.isEmpty) return;
            await ref.read(commentWriteProvider.notifier).addComment(
                  articleId: articleId,
                  commentText: text,
                );
            if (!ref.read(commentWriteProvider).hasError) {
              commentCtrl.clear();
              commentFocus.unfocus();
            }
          },
        ),

        if (commentWrite.hasError)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Gagal mengirim komentar.',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),

        // List komentar
        commentsAsync.when(
          data: (comments) => comments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada komentar. Jadilah yang pertama!',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              : Column(
                  children: comments
                      .map(
                        (c) => ReadCommentItem(
                          comment: c,
                          currentUserId: currentUserId,
                          onReport: () => onReport(c),
                        ),
                      )
                      .toList(),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2563EB), strokeWidth: 2),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Gagal memuat komentar.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ),
      ],
    );
  }
}