import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/bookmark/providers/bookmark_provider.dart';
import 'package:inersia_supabase/features/user/bookmark/widgets/remove_confirmation.dart';
import 'package:inersia_supabase/features/user/bookmark/widgets/search_bar.dart';
import 'package:inersia_supabase/features/user/bookmark/widgets/category_filter.dart';
import 'package:inersia_supabase/features/user/bookmark/widgets/bookmark_card.dart';
import 'package:inersia_supabase/features/user/bookmark/widgets/state_view.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/app_bottom_bar.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/nav_utils.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key});

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarkListProvider);
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Text(
          'Tersimpan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.allArticles.length} artikel',
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(bookmarkListProvider.notifier).onQueryChanged(v),
              onClear: () {
                _searchController.clear();
                ref.read(bookmarkListProvider.notifier).onQueryChanged('');
              },
            ),
          ),
          if (!state.isLoading && state.categories.isNotEmpty)
            CategoryFilterWidget(
              categories: state.categories,
              selectedId: state.selectedCategoryId,
              onSelect: (id) =>
                  ref.read(bookmarkListProvider.notifier).selectCategory(id),
            ),
          Expanded(
            child: state.isLoading
                ? const LoadingViewWidget()
                : state.error != null
                ? ErrorViewWidget(
                    message: state.error!,
                    onRetry: () =>
                        ref.read(bookmarkListProvider.notifier).load(),
                  )
                : state.allArticles.isEmpty
                ? const EmptyViewWidget()
                : state.isEmpty
                ? NoResultsViewWidget(query: state.query)
                : RefreshIndicator(
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFF161616),
                    onRefresh: () =>
                        ref.read(bookmarkListProvider.notifier).load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final article = state.filtered[i];
                        return BookmarkCardWidget(
                          article: article,
                          onTap: () => context.push(
                            '/article/${article.id}',
                            extra: article,
                          ),
                          onRemove: () => _confirmRemove(context, ref, article),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: NavUtils.getCurrentIndex(location),
        onTap: (i) => NavUtils.onItemTapped(context, i),
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    ArticleModel article,
  ) {
    showRemoveConfirmationDialog(
      context: context,
      articleTitle: article.title,
      onConfirm: () {
        ref.read(bookmarkListProvider.notifier).removeBookmark(article.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikel dihapus dari Tersimpan.'),
            backgroundColor: Color(0xFF2563EB),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
