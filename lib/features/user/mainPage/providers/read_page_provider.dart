import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/mainPage/services/read_page_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';

// ─── Service Provider ─────────────────────────────────────────

final readPageServiceProvider = Provider<ReadPageService>(
  (_) => ReadPageService(),
);

// ─── Article Detail ───────────────────────────────────────────

final articleDetailProvider = FutureProvider.family<ArticleModel, String>((
  ref,
  id,
) {
  return ref.read(readPageServiceProvider).getArticleById(id);
});

// ─── Stats (like_count, view_count, comment_count) ────────────
// Dipisah dari ArticleModel agar bisa diupdate tanpa rebuild seluruh halaman

class ArticleStats {
  final int likeCount;
  final int viewCount;
  final int commentCount;

  const ArticleStats({
    required this.likeCount,
    required this.viewCount,
    required this.commentCount,
  });

  ArticleStats copyWith({int? likeCount, int? viewCount, int? commentCount}) {
    return ArticleStats(
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class ArticleStatsNotifier extends StateNotifier<ArticleStats> {
  final ReadPageService _service;
  final String _articleId;

  ArticleStatsNotifier(this._service, this._articleId, ArticleStats initial)
    : super(initial);

  Future<void> refresh() async {
    try {
      final data = await _service.getArticleStats(_articleId);
      state = ArticleStats(
        likeCount: data['like_count']!,
        viewCount: data['view_count']!,
        commentCount: data['comment_count']!,
      );
    } catch (_) {}
  }

  void updateLikeCount(int count) => state = state.copyWith(likeCount: count);

  void updateCommentCount(int count) =>
      state = state.copyWith(commentCount: count);
}

final articleStatsProvider =
    StateNotifierProvider.family<
      ArticleStatsNotifier,
      ArticleStats,
      (String, ArticleStats)
    >(
      (ref, args) => ArticleStatsNotifier(
        ref.read(readPageServiceProvider),
        args.$1,
        args.$2,
      ),
    );

// ─── Like ─────────────────────────────────────────────────────

class LikeState {
  final bool isLiked;
  final int count;
  const LikeState({required this.isLiked, required this.count});
}

class LikeNotifier extends StateNotifier<AsyncValue<LikeState>> {
  final ReadPageService _service;
  final String _articleId;
  final int _initialCount;

  LikeNotifier(this._service, this._articleId, this._initialCount)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final liked = await _service.isLiked(_articleId);
      state = AsyncValue.data(LikeState(isLiked: liked, count: _initialCount));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle() async {
    final current = state.asData?.value;
    if (current == null) return;

    // Optimistic update — UI langsung berubah sebelum server konfirmasi
    final optimisticCount = current.isLiked
        ? current.count - 1
        : current.count + 1;
    state = AsyncValue.data(
      LikeState(isLiked: !current.isLiked, count: optimisticCount),
    );

    try {
      final result = await _service.toggleLike(_articleId, current.isLiked);
      // Gunakan count dari server (source of truth)
      state = AsyncValue.data(
        LikeState(isLiked: result.isLiked, count: result.count),
      );
    } catch (e, s) {
      // Rollback jika error
      state = AsyncValue.data(current);
    }
  }
}

final likeProvider =
    StateNotifierProvider.family<
      LikeNotifier,
      AsyncValue<LikeState>,
      (String, int)
    >(
      (ref, args) =>
          LikeNotifier(ref.read(readPageServiceProvider), args.$1, args.$2),
    );

// ─── Bookmark ─────────────────────────────────────────────────

class BookmarkNotifier extends StateNotifier<AsyncValue<bool>> {
  final ReadPageService _service;
  final String _articleId;

  BookmarkNotifier(this._service, this._articleId)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _service.isBookmarked(_articleId);
      state = AsyncValue.data(saved);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle() async {
    final current = state.asData?.value;
    if (current == null) return;

    // Optimistic update
    state = AsyncValue.data(!current);
    try {
      await _service.toggleBookmark(_articleId, current);
    } catch (_) {
      // Rollback
      state = AsyncValue.data(current);
    }
  }
}

final bookmarkProvider =
    StateNotifierProvider.family<BookmarkNotifier, AsyncValue<bool>, String>(
      (ref, articleId) =>
          BookmarkNotifier(ref.read(readPageServiceProvider), articleId),
    );

// ─── Comments (Realtime) ──────────────────────────────────────
// Menggunakan StreamProvider.family untuk realtime via Supabase stream()
// Stream ini otomatis ter-update saat ada INSERT/UPDATE/DELETE di tabel comments

final commentsStreamProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, articleId) {
      return ref.read(readPageServiceProvider).commentsStream(articleId);
    });

// Notifier terpisah untuk aksi addComment
// StreamProvider sudah handle display, notifier ini hanya untuk write
class CommentWriteNotifier extends StateNotifier<AsyncValue<void>> {
  final ReadPageService _service;

  CommentWriteNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addComment({
    required String articleId,
    required String commentText,
    String? parentId,
  }) async {
    if (commentText.trim().isEmpty) return;
    state = const AsyncValue.loading();
    try {
      await _service.addComment(
        articleId: articleId,
        commentText: commentText,
        parentId: parentId,
      );
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final commentWriteProvider =
    StateNotifierProvider<CommentWriteNotifier, AsyncValue<void>>(
      (ref) => CommentWriteNotifier(ref.read(readPageServiceProvider)),
    );

// ─── Follow ───────────────────────────────────────────────────

class FollowNotifier extends StateNotifier<AsyncValue<bool>> {
  final ReadPageService _service;
  final String _targetUserId;

  FollowNotifier(this._service, this._targetUserId)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final following = await _service.isFollowing(_targetUserId);
      state = AsyncValue.data(following);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle() async {
    final current = state.asData?.value;
    if (current == null) return;

    // Optimistic update
    state = AsyncValue.data(!current);
    try {
      final result = await _service.toggleFollow(_targetUserId, current);
      state = AsyncValue.data(result);
    } catch (_) {
      // Rollback
      state = AsyncValue.data(current);
    }
  }
}

final followProvider =
    StateNotifierProvider.family<FollowNotifier, AsyncValue<bool>, String>(
      (ref, targetUserId) =>
          FollowNotifier(ref.read(readPageServiceProvider), targetUserId),
    );

// ─── Report ───────────────────────────────────────────────────

class ReportNotifier extends StateNotifier<AsyncValue<void>> {
  final ReadPageService _service;

  ReportNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> submit({
    required String targetId,
    required String targetType,
    required String reasonCategory,
    String? description,
    Map<String, dynamic>? contentSnapshot,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.submitReport(
        targetId: targetId,
        targetType: targetType,
        reasonCategory: reasonCategory,
        description: description,
        contentSnapshot: contentSnapshot,
      );
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<void>>(
  (ref) => ReportNotifier(ref.read(readPageServiceProvider)),
);
