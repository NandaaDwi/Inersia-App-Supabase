import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class ArticleReadScreen extends HookConsumerWidget {
  final ArticleModel article;
  const ArticleReadScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = supabaseConfig.client.auth.currentUser?.id ?? '';

    // Fetch data lengkap dari DB — ini menjamin konten selalu ada
    // bahkan jika datang dari search (yang hanya punya data parsial)
    final articleAsync = ref.watch(articleDetailProvider(article.id));

    final commentController = useTextEditingController();
    final commentFocusNode = useFocusNode();

    final likeKey = (article.id, currentUserId);
    final bookmarkKey = (article.id, currentUserId);

    final likeState = ref.watch(likeProvider(likeKey));
    final bookmarkState = ref.watch(bookmarkProvider(bookmarkKey));

    final statsAsync = ref.watch(articleStatsStreamProvider(article.id));
    final commentsAsync = ref.watch(commentsRealtimeProvider(article.id));
    final commentWrite = ref.watch(commentWriteProvider);

    return articleAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: _buildLoadingScaffold(article, context),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
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
                'Gagal memuat artikel',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(articleDetailProvider(article.id)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (fullArticle) {
        final followKey = (fullArticle.authorId, currentUserId);
        final followState = ref.watch(followProvider(followKey));
        final contentParagraphs = _parseContent(fullArticle.content);

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF0D0D0D),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.flag_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _showReportDialog(
                        context: context,
                        ref: ref,
                        targetId: fullArticle.id,
                        targetType: 'article',
                        snapshot: fullArticle.toJson(),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      fullArticle.thumbnail != null
                          ? Image.network(
                              fullArticle.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                            )
                          : _thumbPlaceholder(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0D0D0D).withOpacity(0.85),
                              const Color(0xFF0D0D0D),
                            ],
                            stops: const [0.3, 0.75, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 16,
                        child: Text(
                          fullArticle.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF1F2937),
                            backgroundImage: fullArticle.authorPhoto != null
                                ? NetworkImage(fullArticle.authorPhoto!)
                                : null,
                            child: fullArticle.authorPhoto == null
                                ? Text(
                                    fullArticle.authorName.isNotEmpty
                                        ? fullArticle.authorName[0]
                                              .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullArticle.authorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${AppDateUtils.formatDate(fullArticle.createdAt)}  •  ${fullArticle.estimatedReading} menit baca',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (fullArticle.authorId != currentUserId)
                            followState.when(
                              data: (isFollowing) => _FollowButton(
                                isFollowing: isFollowing,
                                onTap: () => ref
                                    .read(followProvider(followKey).notifier)
                                    .toggle(),
                              ),
                              loading: () => const SizedBox(
                                width: 80,
                                height: 32,
                                child: LinearProgressIndicator(
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Isi Artikel
                      ...contentParagraphs.map(
                        (para) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            para,
                            style: const TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 15,
                              height: 1.75,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      if (fullArticle.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: fullArticle.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161616),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  child: Text(
                                    '#${tag.name}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 24),

                      // Stats Bar — realtime
                      statsAsync.when(
                        data: (stats) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _StatItem(
                                value: _fmt(stats.likeCount),
                                label: 'Suka',
                              ),
                              _StatDivider(),
                              _StatItem(
                                value: _fmt(stats.viewCount),
                                label: 'Dilihat',
                              ),
                              _StatDivider(),
                              // Gunakan jumlah komentar realtime dari stream komentar
                              // agar sinkron saat admin hapus komentar
                              commentsAsync.when(
                                data: (comments) => _StatItem(
                                  value: _fmt(comments.length),
                                  label: 'Komentar',
                                ),
                                loading: () => _StatItem(
                                  value: _fmt(stats.commentCount),
                                  label: 'Komentar',
                                ),
                                error: (_, __) => _StatItem(
                                  value: _fmt(stats.commentCount),
                                  label: 'Komentar',
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),

                      // Komentar Header
                      Row(
                        children: [
                          const Text(
                            'Komentar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          commentsAsync.when(
                            data: (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A5F),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${c.length}',
                                style: const TextStyle(
                                  color: Color(0xFF60A5FA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Comment Input
                      _CommentInput(
                        controller: commentController,
                        focusNode: commentFocusNode,
                        isSending: commentWrite.isLoading,
                        onSend: () async {
                          final text = commentController.text.trim();
                          if (text.isEmpty) return;
                          await ref
                              .read(commentWriteProvider.notifier)
                              .addComment(
                                articleId: fullArticle.id,
                                commentText: text,
                              );
                          if (!ref.read(commentWriteProvider).hasError) {
                            commentController.clear();
                            commentFocusNode.unfocus();
                          }
                        },
                      ),

                      if (commentWrite.hasError)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Gagal mengirim komentar. Coba lagi.',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Comment List — realtime
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
                                      (c) => _CommentItem(
                                        comment: c,
                                        currentUserId: currentUserId,
                                        onReport: () => _showReportDialog(
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
                                    )
                                    .toList(),
                              ),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        error: (e, _) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Gagal memuat komentar.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              border: Border(
                top: BorderSide(color: Color(0xFF1F2937), width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    likeState.when(
                      data: (like) => statsAsync.when(
                        data: (stats) => GestureDetector(
                          onTap: () =>
                              ref.read(likeProvider(likeKey).notifier).toggle(),
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
                        loading: () => Row(
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              color: Color(0xFF6B7280),
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _fmt(fullArticle.likeCount),
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () => const SizedBox(
                        width: 60,
                        child: LinearProgressIndicator(
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    bookmarkState.when(
                      data: (isBookmarked) => GestureDetector(
                        onTap: () => ref
                            .read(bookmarkProvider(bookmarkKey).notifier)
                            .toggle(),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            key: ValueKey(isBookmarked),
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                            color: isBookmarked
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF6B7280),
                            size: 26,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(width: 26, height: 26),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Skeleton loading saat fetch artikel
  Widget _buildLoadingScaffold(ArticleModel article, BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: const Color(0xFF0D0D0D),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                article.thumbnail != null
                    ? Image.network(
                        article.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                      )
                    : _thumbPlaceholder(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0D0D0D).withOpacity(0.85),
                        const Color(0xFF0D0D0D),
                      ],
                      stops: const [0.3, 0.75, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2563EB),
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  void _showReportDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String targetId,
    required String targetType,
    required Map<String, dynamic> snapshot,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _ReportSheet(
        targetId: targetId,
        targetType: targetType,
        contentSnapshot: snapshot,
        onSubmit: (reason, desc) async {
          await ref
              .read(reportProvider.notifier)
              .submit(
                targetId: targetId,
                targetType: targetType,
                reasonCategory: reason,
                description: desc,
                contentSnapshot: snapshot,
              );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Laporan berhasil dikirim. Tim kami akan meninjaunya.',
                ),
                backgroundColor: Color(0xFF059669),
              ),
            );
          }
        },
      ),
    );
  }

  String _fmt(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  List<String> _parseContent(String content) {
    try {
      final List ops = jsonDecode(content) as List;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert'] as String);
        }
      }
      return buffer
          .toString()
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return content.split('\n').where((p) => p.trim().isNotEmpty).toList();
    }
  }

  Widget _thumbPlaceholder() => Container(
    color: const Color(0xFF111827),
    child: const Center(
      child: Icon(Icons.image_outlined, color: Color(0xFF374151), size: 48),
    ),
  );
}

// ─── Follow Button ─────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;
  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

// ─── Stat Widgets ──────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFF1F2937));
}

// ─── Comment Item ──────────────────────────────────────────────

class _CommentItem extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final VoidCallback onReport;

  const _CommentItem({
    required this.comment,
    required this.currentUserId,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
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
                        child: const Icon(
                          Icons.more_horiz,
                          color: Color(0xFF4B5563),
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.commentText,
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

// ─── Comment Input ─────────────────────────────────────────────

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF1F2937),
          child: Icon(Icons.person_outline, color: Color(0xFF6B7280), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan pendapatmu...',
                      hintStyle: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: onSend,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Report Bottom Sheet ───────────────────────────────────────

class _ReportSheet extends HookWidget {
  final String targetId;
  final String targetType;
  final Map<String, dynamic> contentSnapshot;
  final Future<void> Function(String reason, String? description) onSubmit;

  const _ReportSheet({
    required this.targetId,
    required this.targetType,
    required this.contentSnapshot,
    required this.onSubmit,
  });

  static const _reasons = [
    ('spam', 'Spam / Iklan'),
    ('plagiat', 'Plagiat / Konten Curian'),
    ('tidak_pantas', 'Konten Tidak Pantas'),
    ('ujaran_kebencian', 'Ujaran Kebencian'),
    ('misinformasi', 'Informasi Menyesatkan'),
    ('lainnya', 'Lainnya'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedReason = useState<String?>(null);
    final descController = useTextEditingController();
    final isSubmitting = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Laporkan ${targetType == 'article' ? 'Artikel' : 'Komentar'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih alasan laporan kamu',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((r) {
              final isSelected = selectedReason.value == r.$1;
              return GestureDetector(
                onTap: () => selectedReason.value = r.$1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151),
                    ),
                  ),
                  child: Text(
                    r.$2,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Deskripsi tambahan (opsional)...',
              hintStyle: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedReason.value == null || isSubmitting.value
                  ? null
                  : () async {
                      isSubmitting.value = true;
                      try {
                        await onSubmit(
                          selectedReason.value!,
                          descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kirim Laporan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
