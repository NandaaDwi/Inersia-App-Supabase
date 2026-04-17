import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/search/providers/search_provider.dart';
import 'package:inersia_supabase/features/user/search/widgets/search_results_card.dart';

class SearchResultsWidget extends ConsumerWidget {
  final SearchState state;
  const SearchResultsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = state.results!;
    final tab = state.activeTab;

    return CustomScrollView(
      slivers: [
        if ((tab == SearchTab.all || tab == SearchTab.articles) &&
            results.articles.isNotEmpty) ...[
          if (tab == SearchTab.all)
            SearchSectionHeader('Artikel', results.articles.length),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SearchArticleCard(article: results.articles[i]),
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
            SearchSectionHeader('Pengguna', results.users.length),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => SearchUserCard(user: results.users[i]),
                childCount: results.users.length,
              ),
            ),
          ),
        ],

        if ((tab == SearchTab.all || tab == SearchTab.tags) &&
            results.tags.isNotEmpty) ...[
          if (tab == SearchTab.all)
            SearchSectionHeader('Tag', results.tags.length),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (tab == SearchTab.all ? results.tags.take(7) : results.tags)
                        .map(
                          (t) => SearchTagChip(
                            tag: t,
                            onTap: () => ref
                                .read(searchProvider.notifier)
                                .searchByTag(t),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],

        if (tab == SearchTab.all && results.categories.isNotEmpty) ...[
          SearchSectionHeader('Kategori', results.categories.length),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: results.categories
                    .take(5)
                    .map(
                      (c) => SearchCategoryChip(
                        category: c,
                        onTap: () => ref
                            .read(searchProvider.notifier)
                            .searchByCategory(c),
                      ),
                    )
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
