import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/services/read_page_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';

final readPageServiceProvider = Provider<ReadPageService>(
  (_) => ReadPageService(),
);

final articleDetailProvider = FutureProvider.family<ArticleModel, String>((
  ref,
  id,
) {
  return ref.read(readPageServiceProvider).getArticleById(id);
});

class ArticleStats {
  final int likeCount;
  final int viewCount;
  final int commentCount;

  const ArticleStats({
    required this.likeCount,
    required this.viewCount,
    required this.commentCount,
  });
}

final articleStatsStreamProvider = StreamProvider.family<ArticleStats, String>((
  ref,
  articleId,
) {
  return supabaseConfig.client
      .from('articles')
      .stream(primaryKey: ['id'])
      .eq('id', articleId)
      .map((rows) {
        if (rows.isEmpty) {
          return const ArticleStats(
            likeCount: 0,
            viewCount: 0,
            commentCount: 0,
          );
        }
        final row = rows.first;
        return ArticleStats(
          likeCount: row['like_count'] as int? ?? 0,
          viewCount: row['view_count'] as int? ?? 0,
          commentCount: row['comment_count'] as int? ?? 0,
        );
      });
});

class LikeState {
  final bool isLiked;
  const LikeState({required this.isLiked});
}

class LikeNotifier extends StateNotifier<AsyncValue<LikeState>> {
  final ReadPageService _service;
  final String _articleId;

  LikeNotifier(this._service, this._articleId)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final liked = await _service.isLiked(_articleId);
      state = AsyncValue.data(LikeState(isLiked: liked));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle() async {
    final current = state.asData?.value;
    if (current == null) return;

    state = AsyncValue.data(LikeState(isLiked: !current.isLiked));
    try {
      final result = await _service.toggleLike(_articleId, current.isLiked);
      state = AsyncValue.data(LikeState(isLiked: result.isLiked));
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }
}

final likeProvider =
    StateNotifierProvider.family<
      LikeNotifier,
      AsyncValue<LikeState>,
      (String, String)
    >((ref, args) => LikeNotifier(ref.read(readPageServiceProvider), args.$1));

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

    state = AsyncValue.data(!current);
    try {
      await _service.toggleBookmark(_articleId, current);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }
}

final bookmarkProvider =
    StateNotifierProvider.family<
      BookmarkNotifier,
      AsyncValue<bool>,
      (String, String)
    >(
      (ref, args) =>
          BookmarkNotifier(ref.read(readPageServiceProvider), args.$1),
    );

final commentsRealtimeProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, articleId) async* {
      final client = supabaseConfig.client;

      final rawStream = client
          .from('comments')
          .stream(primaryKey: ['id'])
          .eq('article_id', articleId)
          .order('created_at', ascending: true);

      await for (final rows in rawStream) {
        final filtered = rows.where((r) => r['parent_id'] == null).toList();
        if (filtered.isEmpty) {
          yield [];
          continue;
        }

        final userIds = filtered
            .map((r) => r['user_id'] as String)
            .toSet()
            .toList();

        try {
          final usersRes = await client
              .from('users')
              .select('id,name,photo_url')
              .inFilter('id', userIds);

          final userMap = {
            for (final u in usersRes as List)
              u['id'] as String: u as Map<String, dynamic>,
          };

          yield filtered.map((r) {
            final userData = userMap[r['user_id'] as String];
            return CommentModel(
              id: r['id'] as String,
              articleId: r['article_id'] as String,
              userId: r['user_id'] as String,
              userName: userData?['name'] as String? ?? 'Pengguna',
              userPhoto: userData?['photo_url'] as String?,
              parentId: r['parent_id'] as String?,
              commentText: r['comment_text'] as String? ?? '',
              createdAt: DateTime.parse(r['created_at'] as String),
            );
          }).toList();
        } catch (_) {
          yield filtered
              .map(
                (r) => CommentModel(
                  id: r['id'] as String,
                  articleId: r['article_id'] as String,
                  userId: r['user_id'] as String,
                  userName: 'Pengguna',
                  parentId: r['parent_id'] as String?,
                  commentText: r['comment_text'] as String? ?? '',
                  createdAt: DateTime.parse(r['created_at'] as String),
                ),
              )
              .toList();
        }
      }
    });

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
        commentText: commentText.trim(),
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

    state = AsyncValue.data(!current);
    try {
      final result = await _service.toggleFollow(_targetUserId, current);
      state = AsyncValue.data(result);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }
}

final followProvider =
    StateNotifierProvider.family<
      FollowNotifier,
      AsyncValue<bool>,
      (String, String)
    >(
      (ref, args) => FollowNotifier(ref.read(readPageServiceProvider), args.$1),
    );

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
