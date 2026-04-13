import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/services/read_page_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/comment_model.dart';

final readPageServiceProvider = Provider<ReadPageService>(
  (_) => ReadPageService(),
);

final _viewedProvider = StateProvider<Set<String>>((_) => const {});

final articleDetailProvider = FutureProvider.family<ArticleModel, String>((
  ref,
  id,
) async {
  final svc = ref.read(readPageServiceProvider);
  final article = await svc.getArticleById(id);

  final viewed = ref.read(_viewedProvider);
  if (!viewed.contains(id)) {
    svc.incrementViewCount(id);
    ref.read(_viewedProvider.notifier).update((s) => {...s, id});
  }

  return article;
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
        final r = rows.first;
        return ArticleStats(
          likeCount: r['like_count'] as int? ?? 0,
          viewCount: r['view_count'] as int? ?? 0,
          commentCount: r['comment_count'] as int? ?? 0,
        );
      });
});

class LikeState {
  final bool isLiked;
  const LikeState({required this.isLiked});
}

class LikeNotifier extends StateNotifier<AsyncValue<LikeState>> {
  final ReadPageService _svc;
  final String _articleId;

  LikeNotifier(this._svc, this._articleId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final liked = await _svc.isLiked(_articleId);
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
      final result = await _svc.toggleLike(_articleId, current.isLiked);
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
  final ReadPageService _svc;
  final String _articleId;

  BookmarkNotifier(this._svc, this._articleId)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = AsyncValue.data(await _svc.isBookmarked(_articleId));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue.data(!current);
    try {
      await _svc.toggleBookmark(_articleId, current);
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
          .order('created_at', ascending: false);

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

          final comments = filtered.map((r) {
            final u = userMap[r['user_id'] as String];
            return CommentModel(
              id: r['id'] as String,
              articleId: r['article_id'] as String,
              userId: r['user_id'] as String,
              userName: u?['name'] as String? ?? 'Pengguna',
              userPhoto: u?['photo_url'] as String?,
              parentId: r['parent_id'] as String?,
              commentText: r['comment_text'] as String? ?? '',
              createdAt: DateTime.parse(r['created_at'] as String),
            );
          }).toList();

          comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          yield comments;
        } catch (_) {
          final comments = filtered
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
          comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          yield comments;
        }
      }
    });

class CommentWriteNotifier extends StateNotifier<AsyncValue<void>> {
  final ReadPageService _svc;
  CommentWriteNotifier(this._svc) : super(const AsyncValue.data(null));

  Future<void> addComment({
    required String articleId,
    required String commentText,
    String? parentId,
  }) async {
    if (commentText.trim().isEmpty) return;
    state = const AsyncValue.loading();
    try {
      await _svc.addComment(
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
  final ReadPageService _svc;
  final String _targetUserId;

  FollowNotifier(this._svc, this._targetUserId)
    : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = AsyncValue.data(await _svc.isFollowing(_targetUserId));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue.data(!current);
    try {
      final result = await _svc.toggleFollow(_targetUserId, current);
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
  final ReadPageService _svc;
  ReportNotifier(this._svc) : super(const AsyncValue.data(null));

  Future<void> submit({
    required String targetId,
    required String targetType,
    required String reasonCategory,
    String? description,
    Map<String, dynamic>? contentSnapshot,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _svc.submitReport(
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
