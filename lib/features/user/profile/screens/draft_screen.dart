import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/profile/providers/draft_provider.dart';
import 'package:inersia_supabase/features/user/profile/widgets/article_filter_bar.dart';
import 'package:inersia_supabase/features/user/profile/widgets/empty_state_widget.dart';
import 'package:inersia_supabase/features/user/profile/widgets/error_state_widget.dart';
import 'package:inersia_supabase/features/user/profile/widgets/my_article_card.dart';
import 'package:inersia_supabase/features/user/profile/widgets/my_article_search_bar.dart';
import 'package:inersia_supabase/models/article_model.dart';

class MyArticlesScreen extends ConsumerStatefulWidget {
  const MyArticlesScreen({super.key});

  @override
  ConsumerState<MyArticlesScreen> createState() => _MyArticlesScreenState();
}

class _MyArticlesScreenState extends ConsumerState<MyArticlesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(draftProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _MyArticlesAppBar(),
      body: Column(
        children: [
          const MyArticleSearchBar(),
          const ArticleFilterBar(),
          Expanded(child: _MyArticlesBody(
            state: state,
            scrollController: _scrollController,
            onRetry: () => ref.read(draftProvider.notifier).refresh(),
            onDelete: (article) => _confirmDelete(context, article),
          )),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ArticleModel article) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DeleteConfirmSheet(
        article: article,
        onConfirm: () {
          ref.read(draftProvider.notifier).deleteArticle(article.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artikel berhasil dihapus.'),
              backgroundColor: Color(0xFF374151),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _MyArticlesAppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Artikel Saya',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => context.push('/create-article'),
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: Color(0xFF2563EB)),
                label: const Text(
                  'Baru',
                  style: TextStyle(
                      color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        Container(height: 0.5, color: const Color(0xFF1F2937)),
      ],
    );
  }
}

class _MyArticlesBody extends StatelessWidget {
  final DraftState state;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final ValueChanged<ArticleModel> onDelete;

  const _MyArticlesBody({
    required this.state,
    required this.scrollController,
    required this.onRetry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (state.error != null) {
      return ErrorStateWidget(message: state.error!, onRetry: onRetry);
    }

    if (state.articles.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.article_outlined,
        title: 'Belum ada artikel',
        subtitle: 'Mulai menulis artikel baru\ndan publikasikan karya Anda.',
        actionLabel: 'Buat Artikel',
        onAction: () => context.push('/create-article'),
      );
    }

    return Consumer(
      builder: (context, ref, _) => RefreshIndicator(
        color: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFF161616),
        onRefresh: () => ref.read(draftProvider.notifier).refresh(),
        child: ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: state.articles.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            if (i == state.articles.length) {
              return state.isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2563EB), strokeWidth: 2),
                      ),
                    )
                  : const SizedBox(height: 8);
            }
            final article = state.articles[i];
            return MyArticleCard(
              article: article,
              onTap: () {
                context.push('/create-article', extra: article);
              },
              onDelete: () => onDelete(article),
            );
          },
        ),
      ),
    );
  }
}


class _DeleteConfirmSheet extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onConfirm;

  const _DeleteConfirmSheet({required this.article, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final title =
        article.title.trim().isEmpty ? 'Tanpa judul' : article.title;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hapus Artikel?',
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '"$title"',
            style: const TextStyle(
                color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Artikel yang dihapus tidak bisa dikembalikan.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9CA3AF),
                    side: const BorderSide(color: Color(0xFF374151)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hapus',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}