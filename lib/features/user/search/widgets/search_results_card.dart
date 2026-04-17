import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/main_page_provider.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';
import 'package:inersia_supabase/features/user/search/services/search_service.dart';
import 'package:inersia_supabase/models/article_model.dart';

class SearchSectionHeader extends SliverToBoxAdapter {
  SearchSectionHeader(String title, int count)
    : super(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class SearchArticleCard extends ConsumerWidget {
  final ArticleResult article;
  final bool compact;
  const SearchArticleCard({
    super.key,
    required this.article,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = supabaseConfig.client.auth.currentUser?.id ?? '';
    final likeKey = (article.id, uid);

    final isLikedAsync = ref.watch(cardLikeStatusProvider(likeKey));

    final likeCountAsync = ref.watch(
      articleLikeCountStreamProvider(article.id),
    );

    final isLiked = isLikedAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    final likeCount = likeCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => article.likeCount,
    );

    final size = compact ? 64.0 : 80.0;

    return GestureDetector(
      onTap: () {
        ref.invalidate(cardLikeStatusProvider(likeKey));

        context.push(
          '/article/${article.id}',
          extra: ArticleModel(
            id: article.id,
            authorId: '',
            authorName: article.authorName,
            title: article.title,
            content: '',
            thumbnail: article.thumbnail,
            status: 'published',
            categoryId: '',
            categoryName: article.categoryName,
            estimatedReading: article.estimatedReading,
            likeCount: article.likeCount,
            commentCount: 0,
            viewCount: article.viewCount,
            createdAt: article.createdAt,
            updatedAt: article.createdAt,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
        ),
        child: Row(
          children: [
            _ArticleThumbnail(url: article.thumbnail, size: size),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.categoryName != null)
                    _CategoryBadge(name: article.categoryName!),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _ArticleMeta(
                    authorName: article.authorName,
                    isLiked: isLiked,
                    likeCount: likeCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleThumbnail extends StatelessWidget {
  final String? url;
  final double size;
  const _ArticleThumbnail({this.url, required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: url != null
        ? Image.network(
            url!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          )
        : _placeholder(),
  );

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.image_outlined, color: Color(0xFF374151), size: 24),
  );
}

class _CategoryBadge extends StatelessWidget {
  final String name;
  const _CategoryBadge({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    margin: const EdgeInsets.only(bottom: 5),
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

class _ArticleMeta extends StatelessWidget {
  final String authorName;
  final bool isLiked;
  final int likeCount;
  const _ArticleMeta({
    required this.authorName,
    required this.isLiked,
    required this.likeCount,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: Text(
          authorName,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const Text(
        ' · ',
        style: TextStyle(color: Color(0xFF374151), fontSize: 11),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          key: ValueKey(isLiked),
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
          size: 12,
        ),
      ),
      const SizedBox(width: 3),
      Text(
        '$likeCount',
        style: TextStyle(
          color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
          fontSize: 11,
        ),
      ),
    ],
  );
}

class SearchUserCard extends ConsumerWidget {
  final UserResult user;
  const SearchUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = supabaseConfig.client.auth.currentUser?.id ?? '';
    final isOwn = uid == user.id;
    final followKey = (user.id, uid);
    final followState = isOwn ? null : ref.watch(followProvider(followKey));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/user/${user.id}'),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1F2937),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
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
            child: GestureDetector(
              onTap: () => context.push('/user/${user.id}'),
              child: _UserInfo(user: user),
            ),
          ),
          const SizedBox(width: 8),
          if (isOwn)
            _ProfileBtn(onTap: () => context.push('/profile'))
          else if (followState != null)
            followState.when(
              data: (isFollowing) => _FollowBtn(
                isFollowing: isFollowing,
                onTap: () =>
                    ref.read(followProvider(followKey).notifier).toggle(),
              ),
              loading: () => const SizedBox(
                width: 60,
                height: 28,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final UserResult user;
  const _UserInfo({required this.user});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        user.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      Row(
        children: [
          Text(
            '@${user.username}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          if (user.followersCount > 0) ...[
            const Text(
              ' · ',
              style: TextStyle(color: Color(0xFF374151), fontSize: 12),
            ),
            Text(
              '${_fmt(user.followersCount)} pengikut',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
      if (user.bio != null && user.bio!.isNotEmpty)
        Text(
          user.bio!,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 12,
            height: 1.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
    ],
  );
}

class _ProfileBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1F2937)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Profil',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      ),
    ),
  );
}

class _FollowBtn extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;
  const _FollowBtn({required this.isFollowing, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class SearchTagChip extends StatelessWidget {
  final TagResult tag;
  final VoidCallback onTap;
  const SearchTagChip({super.key, required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag_rounded, color: Color(0xFF059669), size: 13),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          if (tag.articleCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${tag.articleCount}',
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 11),
            ),
          ],
        ],
      ),
    ),
  );
}

class SearchCategoryChip extends StatelessWidget {
  final CategoryResult category;
  final VoidCallback onTap;
  const SearchCategoryChip({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Text(
        category.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

class SearchNoResults extends StatelessWidget {
  final String query;
  const SearchNoResults({super.key, required this.query});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.search_off_rounded,
          color: Color(0xFF374151),
          size: 56,
        ),
        const SizedBox(height: 12),
        Text(
          'Tidak ada hasil untuk "$query"',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
