import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/main_page_provider.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/app_bottom_bar.dart';
import 'package:inersia_supabase/features/user/search/providers/search_provider.dart';
import 'package:inersia_supabase/features/user/search/services/search_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/nav_utils.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final controller = useTextEditingController(text: state.query);
    final focusNode = useFocusNode();
    final layerLink = useMemoized(() => LayerLink());
    final location = GoRouterState.of(context).matchedLocation;

    useEffect(() {
      if (controller.text != state.query) {
        controller.text = state.query;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: state.query.length),
        );
      }
      return null;
    }, [state.query]);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      // ─── App Bar ─────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        titleSpacing: 16,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Inersia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: '.',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: const Color(0xFF1F2937)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── Search Bar ─────────────────────────────────
            _SearchBar(
              controller: controller,
              focusNode: focusNode,
              layerLink: layerLink,
              hasQuery: state.hasQuery,
              isSuggesting: state.isSuggesting,
              onChanged: (v) =>
                  ref.read(searchProvider.notifier).onQueryChanged(v),
              onSubmit: (v) {
                focusNode.unfocus();
                ref.read(searchProvider.notifier).search(v);
              },
              onClear: () {
                controller.clear();
                ref.read(searchProvider.notifier).clearSearch();
                focusNode.requestFocus();
              },
            ),

            // ─── Autocomplete overlay ────────────────────────
            if (state.showSuggestions && focusNode.hasFocus)
              _SuggestionList(
                suggestions: state.suggestions,
                onTap: (s) {
                  controller.text = s.label;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: s.label.length),
                  );
                  focusNode.unfocus();
                  ref.read(searchProvider.notifier).search(s.label);
                },
              ),

            // ─── Tab filter ─────────────────────────────────
            if (state.hasResults)
              _TabBar(
                activeTab: state.activeTab,
                results: state.results!,
                onTabChanged: (t) =>
                    ref.read(searchProvider.notifier).setTab(t),
              ),

            // ─── Body ────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => focusNode.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: _Body(state: state, focusNode: focusNode),
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

// ─── Search Bar ───────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final LayerLink layerLink;
  final bool hasQuery;
  final bool isSuggesting;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.layerLink,
    required this.hasQuery,
    required this.isSuggesting,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: CompositedTransformTarget(
              link: layerLink,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focusNode.hasFocus
                        ? const Color(0xFF2563EB).withOpacity(0.6)
                        : const Color(0xFF1F2937),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmit,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Cari artikel, user, tag...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                    ),
                    prefixIcon: isSuggesting
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
                        : const Icon(Icons.search_rounded,
                            color: Color(0xFF4B5563), size: 22),
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF6B7280), size: 20),
                            onPressed: onClear,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          if (hasQuery) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                focusNode.unfocus();
                onSubmit(controller.text);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text('Cari',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Autocomplete List ────────────────────────────────────────

class _SuggestionList extends StatelessWidget {
  final List<SuggestionItem> suggestions;
  final ValueChanged<SuggestionItem> onTap;

  const _SuggestionList({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return InkWell(
            onTap: () => onTap(s),
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? const Radius.circular(14) : Radius.zero,
              bottom: i == suggestions.length - 1
                  ? const Radius.circular(14)
                  : Radius.zero,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _SuggestionIcon(type: s.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (s.subtitle != null)
                          Text(
                            s.subtitle!,
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.north_west_rounded,
                      color: Color(0xFF374151), size: 16),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SuggestionIcon extends StatelessWidget {
  final SearchResultType type;
  const _SuggestionIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      SearchResultType.article => (
        Icons.article_outlined,
        const Color(0xFF2563EB),
      ),
      SearchResultType.user => (
        Icons.person_outline_rounded,
        const Color(0xFF7C3AED),
      ),
      SearchResultType.tag => (Icons.tag_rounded, const Color(0xFF059669)),
      SearchResultType.category => (
        Icons.category_outlined,
        const Color(0xFFD97706),
      ),
    };

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final SearchTab activeTab;
  final SearchResults results;
  final ValueChanged<SearchTab> onTabChanged;

  const _TabBar({
    required this.activeTab,
    required this.results,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Tab('Semua', SearchTab.all, activeTab, onTabChanged),
          if (results.articles.isNotEmpty)
            _Tab('Artikel (${results.articles.length})', SearchTab.articles,
                activeTab, onTabChanged),
          if (results.users.isNotEmpty)
            _Tab('User (${results.users.length})', SearchTab.users, activeTab,
                onTabChanged),
          if (results.tags.isNotEmpty)
            _Tab('Tag (${results.tags.length})', SearchTab.tags, activeTab,
                onTabChanged),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final SearchTab tab;
  final SearchTab active;
  final ValueChanged<SearchTab> onTap;

  const _Tab(this.label, this.tab, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isActive = tab == active;
    return GestureDetector(
      onTap: () => onTap(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF1F2937),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final SearchState state;
  final FocusNode focusNode;

  const _Body({required this.state, required this.focusNode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Color(0xFF374151), size: 48),
            const SizedBox(height: 12),
            Text(state.error!,
                style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(searchProvider.notifier).search(state.query),
              child: const Text('Coba lagi',
                  style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        ),
      );
    }

    if (state.hasResults) {
      return _SearchResults(state: state);
    }

    if (state.hasQuery && state.results != null && state.results!.isEmpty) {
      return _NoResults(query: state.query);
    }

    return _Discovery(
      history: state.history,
      onHistoryTap: (h) => ref.read(searchProvider.notifier).search(h),
      onHistoryRemove: (h) =>
          ref.read(searchProvider.notifier).removeFromHistory(h),
      onClearHistory: () => ref.read(searchProvider.notifier).clearHistory(),
      onTagTap: (t) => ref.read(searchProvider.notifier).searchByTag(t),
      onCategoryTap: (c) =>
          ref.read(searchProvider.notifier).searchByCategory(c),
    );
  }
}

// ─── Search Results ───────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final SearchState state;
  const _SearchResults({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = state.results!;
    final tab = state.activeTab;

    return CustomScrollView(
      slivers: [
        if ((tab == SearchTab.all || tab == SearchTab.articles) &&
            results.articles.isNotEmpty) ...[
          if (tab == SearchTab.all)
            _SliverHeader('Artikel', results.articles.length),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ArticleCard(article: results.articles[i]),
                childCount: tab == SearchTab.all
                    ? results.articles.length.clamp(0, 4)
                    : results.articles.length,
              ),
            ),
          ),
        ],

        if ((tab == SearchTab.all || tab == SearchTab.users) &&
            results.users.isNotEmpty) ...[
          if (tab == SearchTab.all)
            _SliverHeader('Pengguna', results.users.length),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _UserCard(user: results.users[i]),
                childCount: results.users.length,
              ),
            ),
          ),
        ],

        if ((tab == SearchTab.all || tab == SearchTab.tags) &&
            results.tags.isNotEmpty) ...[
          if (tab == SearchTab.all)
            _SliverHeader('Tag', results.tags.length),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: results.tags
                    .map((t) => _TagChip(
                          tag: t,
                          onTap: () =>
                              ref.read(searchProvider.notifier).searchByTag(t),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],

        if (tab == SearchTab.all && results.categories.isNotEmpty) ...[
          _SliverHeader('Kategori', results.categories.length),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: results.categories
                    .map((c) => _CategoryChip(
                          category: c,
                          onTap: () => ref
                              .read(searchProvider.notifier)
                              .searchByCategory(c),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

class _SliverHeader extends SliverToBoxAdapter {
  _SliverHeader(String title, int count)
      : super(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
}

// ─── Discovery ────────────────────────────────────────────────

class _Discovery extends ConsumerWidget {
  final List<String> history;
  final ValueChanged<String> onHistoryTap;
  final ValueChanged<String> onHistoryRemove;
  final VoidCallback onClearHistory;
  final ValueChanged<TagResult> onTagTap;
  final ValueChanged<CategoryResult> onCategoryTap;

  const _Discovery({
    required this.history,
    required this.onHistoryTap,
    required this.onHistoryRemove,
    required this.onClearHistory,
    required this.onTagTap,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(discoveryProvider);

    return CustomScrollView(
      slivers: [
        if (history.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Pencarian Terakhir',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClearHistory,
                    child: const Text('Hapus Semua',
                        style:
                            TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _HistoryItem(
                  query: history[i],
                  onTap: () => onHistoryTap(history[i]),
                  onRemove: () => onHistoryRemove(history[i]),
                ),
                childCount: history.length,
              ),
            ),
          ),
        ],

        discoveryAsync.when(
          data: (data) => _DiscoveryContent(
            data: data,
            onTagTap: onTagTap,
            onCategoryTap: onCategoryTap,
          ),
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF2563EB), strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) =>
              const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

class _DiscoveryContent extends ConsumerWidget {
  final DiscoveryData data;
  final ValueChanged<TagResult> onTagTap;
  final ValueChanged<CategoryResult> onCategoryTap;

  const _DiscoveryContent({
    required this.data,
    required this.onTagTap,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (data.categories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text('Jelajahi Kategori',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: data.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _CategoryChip(
                category: data.categories[i],
                onTap: () => onCategoryTap(data.categories[i]),
              ),
            ),
          ),
        ],

        if (data.popularTags.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text('Tag Populer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.popularTags
                  .map((t) => _TagChip(tag: t, onTap: () => onTagTap(t)))
                  .toList(),
            ),
          ),
        ],

        if (data.trending.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 6),
                Text('Trending',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          ...data.trending
              .map((a) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ArticleCard(article: a, compact: true),
                  ))
              .toList(),
        ],
      ]),
    );
  }
}

// ─── Article Card dengan like status realtime ─────────────────

class _ArticleCard extends ConsumerWidget {
  final ArticleResult article;
  final bool compact;

  const _ArticleCard({required this.article, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        supabaseConfig.client.auth.currentUser?.id ?? '';

    // Watch like status realtime dari provider yang sama dengan main page
    final likeStatusAsync = ref.watch(
      cardLikeStatusProvider((article.id, currentUserId)),
    );
    final likeCountAsync = ref.watch(
      articleLikeCountStreamProvider(article.id),
    );

    final isLiked = likeStatusAsync.when(
      data: (v) => v,
      loading: () => false,
      error: (_, __) => false,
    );
    final likeCount = likeCountAsync.when(
      data: (c) => c,
      loading: () => article.likeCount,
      error: (_, __) => article.likeCount,
    );

    return GestureDetector(
      onTap: () {
        // Navigasi ke read screen, data lengkap akan di-fetch di sana
        final minimalArticle = ArticleModel(
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
        );
        context.push('/article/${article.id}', extra: minimalArticle);
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: article.thumbnail != null
                  ? Image.network(
                      article.thumbnail!,
                      width: compact ? 64 : 80,
                      height: compact ? 64 : 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _thumbPlaceholder(compact ? 64 : 80),
                    )
                  : _thumbPlaceholder(compact ? 64 : 80),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.categoryName!,
                        style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  Text(
                    article.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(article.authorName,
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 11)),
                      const Text(' · ',
                          style: TextStyle(
                              color: Color(0xFF374151), fontSize: 11)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          key: ValueKey(isLiked),
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6B7280),
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$likeCount',
                        style: TextStyle(
                          color: isLiked
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6B7280),
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
      ),
    );
  }

  Widget _thumbPlaceholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined,
            color: Color(0xFF374151), size: 24),
      );
}

// ─── User Card dengan follow + navigasi ke profil ─────────────

class _UserCard extends ConsumerWidget {
  final UserResult user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId =
        supabaseConfig.client.auth.currentUser?.id ?? '';
    final followKey = (user.id, currentUserId);
    final isOwnProfile = currentUserId == user.id;

    final followState =
        isOwnProfile ? null : ref.watch(followProvider(followKey));

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
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/user/${user.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Row(
                    children: [
                      Text('@${user.username}',
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                      if (user.followersCount > 0) ...[
                        const Text(' · ',
                            style: TextStyle(
                                color: Color(0xFF374151), fontSize: 12)),
                        Text('${_fmtCount(user.followersCount)} pengikut',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12)),
                      ],
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Text(user.bio!,
                        style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 12,
                            height: 1.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tombol Follow atau Lihat Profil
          if (isOwnProfile)
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1F2937)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Profil',
                    style:
                        TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              ),
            )
          else if (followState != null)
            followState.when(
              data: (isFollowing) => GestureDetector(
                onTap: () =>
                    ref.read(followProvider(followKey).notifier).toggle(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                width: 60,
                height: 28,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF2563EB)),
                  ),
                ),
              ),
              error: (_, __) => GestureDetector(
                onTap: () => context.push('/user/${user.id}'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1F2937)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Lihat',
                      style: TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12)),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─── Tag & Category Chips ─────────────────────────────────────

class _TagChip extends StatelessWidget {
  final TagResult tag;
  final VoidCallback onTap;

  const _TagChip({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F).withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1E3A5F).withOpacity(0.6),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('#',
                style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            Text(tag.name,
                style: const TextStyle(
                    color: Color(0xFF93C5FD), fontSize: 13)),
            if (tag.articleCount > 0) ...[
              const SizedBox(width: 5),
              Text('${tag.articleCount}',
                  style: const TextStyle(
                      color: Color(0xFF2D5282), fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryResult category;
  final VoidCallback onTap;

  const _CategoryChip({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.name,
                style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            if (category.articleCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${category.articleCount}',
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 10)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── History Item ─────────────────────────────────────────────

class _HistoryItem extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryItem({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            const Icon(Icons.history_rounded,
                color: Color(0xFF374151), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(query,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 14)),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFF374151), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No Results ───────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: const Icon(Icons.search_off_rounded,
                  color: Color(0xFF374151), size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Tidak ada hasil untuk',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
            const SizedBox(height: 4),
            Text('"$query"',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text(
              'Coba kata kunci lain atau telusuri kategori di bawah',
              style: TextStyle(
                  color: Color(0xFF4B5563), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}