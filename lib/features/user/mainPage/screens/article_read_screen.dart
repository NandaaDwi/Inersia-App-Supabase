import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';
import 'package:inersia_supabase/utils/moderation_client.dart';

class ArticleReadScreen extends HookConsumerWidget {
  final ArticleModel article;
  const ArticleReadScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = supabaseConfig.client.auth.currentUser?.id ?? '';

    final commentCtrl = useTextEditingController();
    final commentFocus = useFocusNode();

    final likeKey = (article.id, currentUserId);
    final bookmarkKey = (article.id, currentUserId);

    final likeState = ref.watch(likeProvider(likeKey));
    final bookmarkState = ref.watch(bookmarkProvider(bookmarkKey));
    final statsAsync = ref.watch(articleStatsStreamProvider(article.id));
    final commentsAsync = ref.watch(commentsRealtimeProvider(article.id));
    final commentWrite = ref.watch(commentWriteProvider);

    final articleAsync = ref.watch(articleDetailProvider(article.id));

    return articleAsync.when(
      loading: () => _loadingScaffold(article),
      error: (e, _) => _errorScaffold(
        article,
        () => ref.invalidate(articleDetailProvider(article.id)),
      ),
      data: (full) {
        final followKey = (full.authorId, currentUserId);
        final followState = ref.watch(followProvider(followKey));
        final paragraphs = _parseContent(full.content);

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF0D0D0D),
                leading: _CircleBtn(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                actions: [
                  _CircleBtn(
                    icon: Icons.flag_outlined,
                    onTap: () => _reportSheet(
                      context: context,
                      ref: ref,
                      targetId: full.id,
                      targetType: 'article',
                      snapshot: full.toJson(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      full.thumbnail != null
                          ? Image.network(
                              full.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
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
                          full.title,
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.push('/user/${full.authorId}');
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF1F2937),
                              backgroundImage: full.authorPhoto != null
                                  ? NetworkImage(full.authorPhoto!)
                                  : null,
                              child: full.authorPhoto == null
                                  ? Text(
                                      full.authorName.isNotEmpty
                                          ? full.authorName[0].toUpperCase()
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
                                  full.authorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${AppDateUtils.formatDate(full.createdAt)}  •  ${full.estimatedReading} menit baca',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (full.authorId != currentUserId)
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

                      ...paragraphs.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            p,
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

                      if (full.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: full.tags
                              .map(
                                (t) => Container(
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
                                    '#${t.name}',
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

                      statsAsync.when(
                        data: (stats) => _StatsBox(
                          likeCount: stats.likeCount,
                          viewCount: stats.viewCount,
                          commentCount: stats.commentCount,
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
                          const Spacer(),
                          const Text(
                            'Terbaru di atas',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _CommentInput(
                        controller: commentCtrl,
                        focusNode: commentFocus,
                        isSending: commentWrite.isLoading,
                        onSend: () async {
                          final text = commentCtrl.text.trim();
                          if (text.isEmpty) return;
                          await ref
                              .read(commentWriteProvider.notifier)
                              .addComment(
                                articleId: full.id,
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
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

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
                                        onReport: () => _reportSheet(
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
                        error: (_, __) => const Padding(
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
                              _fmt(article.likeCount),
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
                      data: (saved) => GestureDetector(
                        onTap: () => ref
                            .read(bookmarkProvider(bookmarkKey).notifier)
                            .toggle(),
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

  void _reportSheet({
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
        targetType: targetType,
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
                content: Text('Laporan berhasil dikirim.'),
                backgroundColor: Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  List<String> _parseContent(String content) {
    try {
      final dynamic decoded = jsonDecode(content);
      final List ops = decoded is List
          ? decoded
          : (decoded is Map ? decoded['ops'] as List? ?? [] : []);
      final buf = StringBuffer();
      for (final op in ops) {
        if (op is Map && op['insert'] is String) buf.write(op['insert']);
      }
      return buf
          .toString()
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return content.split('\n').where((p) => p.trim().isNotEmpty).toList();
    }
  }

  Scaffold _loadingScaffold(ArticleModel a) => Scaffold(
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
              onPressed: () {},
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                a.thumbnail != null
                    ? Image.network(a.thumbnail!, fit: BoxFit.cover)
                    : _placeholder(),
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
                    a.title,
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
    ),
  );

  Scaffold _errorScaffold(ArticleModel a, VoidCallback onRetry) => Scaffold(
    backgroundColor: const Color(0xFF0D0D0D),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 16,
        ),
        onPressed: () {},
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF6B7280), size: 48),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat artikel',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
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
  );

  Widget _placeholder() => Container(
    color: const Color(0xFF111827),
    child: const Center(
      child: Icon(Icons.image_outlined, color: Color(0xFF374151), size: 48),
    ),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white, size: 18),
      onPressed: onTap,
    ),
  );
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;
  const _FollowButton({required this.isFollowing, required this.onTap});

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

class _StatsBox extends StatelessWidget {
  final int likeCount;
  final int viewCount;
  final int commentCount;
  const _StatsBox({
    required this.likeCount,
    required this.viewCount,
    required this.commentCount,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        _S(value: _fmt(likeCount), label: 'Suka'),
        Container(width: 1, height: 36, color: const Color(0xFF1F2937)),
        _S(value: _fmt(viewCount), label: 'Dilihat'),
        Container(width: 1, height: 36, color: const Color(0xFF1F2937)),
        _S(value: _fmt(commentCount), label: 'Komentar'),
      ],
    ),
  );
}

class _S extends StatelessWidget {
  final String value;
  final String label;
  const _S({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
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
    final text = ModerationClient.censorCommentSync(comment.commentText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              context.push('/user/${comment.userId}');
            },
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
  Widget build(BuildContext context) => Row(
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

class _ReportSheet extends HookWidget {
  final String targetType;
  final Future<void> Function(String reason, String? description) onSubmit;

  const _ReportSheet({required this.targetType, required this.onSubmit});

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
    final selected = useState<String?>(null);
    final descCtrl = useTextEditingController();
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
              final isSel = selected.value == r.$1;
              return GestureDetector(
                onTap: () => selected.value = r.$1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151),
                    ),
                  ),
                  child: Text(
                    r.$2,
                    style: TextStyle(
                      color: isSel
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descCtrl,
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
              onPressed: selected.value == null || isSubmitting.value
                  ? null
                  : () async {
                      isSubmitting.value = true;
                      try {
                        await onSubmit(
                          selected.value!,
                          descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
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
