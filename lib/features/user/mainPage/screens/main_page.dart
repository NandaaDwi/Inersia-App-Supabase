import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/main_page_provider.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/app_bottom_bar.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/article_card.dart';
import 'package:inersia_supabase/features/user/notification/providers/user_notification_provider.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';
import 'package:inersia_supabase/utils/nav_utils.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(articleListProvider.notifier).loadMore();
    }
  }

  void _navigateToArticle(ArticleModel article) {
    context.push('/article/${article.id}', extra: article);
  }

  @override
  Widget build(BuildContext context) {
    final articleState = ref.watch(articleListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final location = GoRouterState.of(context).matchedLocation;

    final unreadCountAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: RefreshIndicator(
        color: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFF161616),
        onRefresh: () => ref.read(articleListProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0D0D0D),
              floating: true,
              snap: true,
              elevation: 0,
              title: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Beranda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                unreadCountAsync.when(
                  data: (count) => IconButton(
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        if (count > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: count > 9 ? 16 : 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: count > 9
                                  ? const Center(
                                      child: Text(
                                        '9+',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => context.push('/notifications'),
                  ),
                  loading: () => IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => context.push('/notifications'),
                  ),
                  error: (_, __) => IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => context.push('/notifications'),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (cats) => _CategoryList(
                  categories: cats,
                  selectedId: selectedCategory,
                  onSelect: (id) =>
                      ref.read(selectedCategoryProvider.notifier).state = id,
                ),
                loading: () => const SizedBox(height: 56),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Terbaru',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            if (articleState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
              )
            else if (articleState.error != null)
              _ErrorSliver(
                onRetry: () => ref.read(articleListProvider.notifier).refresh(),
              )
            else if (articleState.articles.isEmpty)
              const _EmptySliver()
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    if (i < articleState.articles.length) {
                      final article = articleState.articles[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ArticleCard(
                          article: article,
                          onTap: () => _navigateToArticle(article),
                        ),
                      );
                    }
                    return articleState.isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2563EB),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const SizedBox(height: 20);
                  }, childCount: articleState.articles.length + 1),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: NavUtils.getCurrentIndex(location),
        onTap: (index) => NavUtils.onItemTapped(context, index),
      ),
    );
  }
}

class _ErrorSliver extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorSliver({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
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
  }
}

class _EmptySliver extends StatelessWidget {
  const _EmptySliver();

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, color: Color(0xFF374151), size: 56),
            SizedBox(height: 12),
            Text(
              'Belum ada artikel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _CategoryList({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          _CategoryChip(
            label: 'Semua',
            isSelected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                label: cat.name,
                isSelected: selectedId == cat.id,
                onTap: () => onSelect(cat.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFF1F2937),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
