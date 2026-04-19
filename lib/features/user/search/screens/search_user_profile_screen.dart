import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';
import 'package:inersia_supabase/features/user/search/providers/search_user_profile_provider.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class SearchUserProfileScreen extends ConsumerWidget {
  final String userId;
  const SearchUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = supabaseConfig.client.auth.currentUser?.id ?? '';
    final isOwnProfile = currentUserId == userId;

    final userAsync = ref.watch(userProfilesProvider(userId));
    final articlesAsync = ref.watch(userArticlesProvider(userId));

    final followKey = (userId, currentUserId);
    final followState = isOwnProfile
        ? null
        : ref.watch(followProvider(followKey));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                color: Color(0xFF6B7280),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Profil tidak ditemukan',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
        data: (user) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0D0D0D),
              pinned: true,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1F2937)),
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
              title: Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(height: 0.5, color: const Color(0xFF1F2937)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF1F2937),
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '@${user.username}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isOwnProfile)
                                OutlinedButton(
                                  onPressed: () => context.push('/profile'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFF1F2937),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Edit Profil',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                )
                              else if (followState != null)
                                followState.when(
                                  data: (isFollowing) => GestureDetector(
                                    onTap: () => ref
                                        .read(
                                          followProvider(followKey).notifier,
                                        )
                                        .toggle(),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFollowing
                                            ? Colors.transparent
                                            : const Color(0xFF2563EB),
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
                                          color: isFollowing
                                              ? const Color(0xFF9CA3AF)
                                              : Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  loading: () => const SizedBox(
                                    width: 80,
                                    height: 36,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (user.bio != null && user.bio!.isNotEmpty)
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Container(
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
                          _StatCell(
                            label: 'Mengikuti',
                            value: _fmt(user.followingCount),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xFF1F2937),
                          ),
                          _StatCell(
                            label: 'Pengikut',
                            value: _fmt(user.followersCount),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xFF1F2937),
                          ),
                          articlesAsync.when(
                            data: (articles) => _StatCell(
                              label: 'Artikel',
                              value: '${articles.length}',
                            ),
                            loading: () =>
                                const _StatCell(label: 'Artikel', value: '-'),
                            error: (_, __) =>
                                const _StatCell(label: 'Artikel', value: '0'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Artikel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            articlesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Gagal memuat artikel',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ),
              data: (articles) => articles.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                color: Color(0xFF374151),
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada artikel',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final article = articles[i];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/article/${article.id}',
                              extra: article,
                            ),
                            child: _ArticleListItem(article: article),
                          );
                        }, childCount: articles.length),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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

class _ArticleListItem extends StatelessWidget {
  final ArticleModel article;
  const _ArticleListItem({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: Row(
        children: [
          if (article.thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                article.thumbnail!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            )
          else
            _placeholder(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
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
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
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
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      color: Color(0xFF6B7280),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.viewCount}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppDateUtils.formatDate(article.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.image_outlined, color: Color(0xFF374151), size: 28),
  );
}
