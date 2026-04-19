import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/bookmark/providers/bookmark_provider.dart';
import 'package:inersia_supabase/features/user/bookmark/widgets/bookmark_card.dart';
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
      appBar: _BookmarkAppBar(
        totalCount: state.allArticles.length,
        isLoading: state.isLoading,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _BookmarkSearchBar(
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
            _CategoryFilter(
              categories: state.categories,
              selectedId: state.selectedCategoryId,
              onSelect: (id) =>
                  ref.read(bookmarkListProvider.notifier).selectCategory(id),
            ),

          Expanded(
            child: _BookmarkBody(
              state: state,
              onRetry: () => ref.read(bookmarkListProvider.notifier).load(),
              onRemove: (article) => _confirmRemove(context, ref, article),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus dari Tersimpan?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${article.title}" akan dihapus dari daftar tersimpan kamu.',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(bookmarkListProvider.notifier)
                  .removeBookmark(article.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Artikel dihapus dari Tersimpan.'),
                  backgroundColor: Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int totalCount;
  final bool isLoading;
  const _BookmarkAppBar({required this.totalCount, required this.isLoading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
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
      if (!isLoading)
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalCount artikel',
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
  );
}

class _BookmarkSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _BookmarkSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Cari artikel tersimpan...',
      hintStyle: const TextStyle(color: Color(0xFF4B5563)),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: Color(0xFF6B7280),
        size: 20,
      ),
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF6B7280),
                size: 18,
              ),
              onPressed: onClear,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFF161616),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _CategoryFilter extends StatelessWidget {
  final List categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  const _CategoryFilter({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: categories.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        if (i == 0) {
          final isAll = selectedId == null;
          return _FilterChip(
            label: 'Semua',
            isSelected: isAll,
            onTap: () => onSelect(null),
          );
        }
        final cat = categories[i - 1];
        final isSelected = selectedId == cat.id;
        return _FilterChip(
          label: cat.name,
          isSelected: isSelected,
          onTap: () => onSelect(isSelected ? null : cat.id),
        );
      },
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF161616),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
}

class _BookmarkBody extends StatelessWidget {
  final BookmarkState state;
  final VoidCallback onRetry;
  final void Function(ArticleModel) onRemove;
  const _BookmarkBody({
    required this.state,
    required this.onRetry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2563EB),
          strokeWidth: 2,
        ),
      );
    }

    if (state.error != null) {
      return _ErrorView(message: state.error!, onRetry: onRetry);
    }

    if (state.allArticles.isEmpty) {
      return _EmptyView();
    }

    if (state.isEmpty) {
      return _NoResultsView(query: state.query);
    }

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF161616),
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final article = state.filtered[i];
          return BookmarkCard(
            article: article,
            onRemove: () => onRemove(article),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFF374151),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak dapat memuat data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _friendlyMessage(message),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _friendlyMessage(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('socket') ||
        r.contains('network') ||
        r.contains('connection') ||
        r.contains('timeout') ||
        r.contains('unreachable')) {
      return 'Periksa koneksi internet kamu, lalu coba lagi.';
    }
    if (r.contains('unauthorized') || r.contains('401')) {
      return 'Sesi kamu telah berakhir. Silakan masuk kembali.';
    }
    if (r.contains('not found') || r.contains('404')) {
      return 'Data tidak ditemukan. Coba muat ulang.';
    }
    return 'Terjadi kesalahan. Periksa koneksi internet dan coba lagi.';
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
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
              border: Border.all(color: const Color(0xFF161616)),
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              color: Color(0xFF374151),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada artikel tersimpan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tekan ikon bookmark saat membaca artikel\nuntuk menyimpannya di sini.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Jelajahi Artikel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _NoResultsView extends StatelessWidget {
  final String query;
  const _NoResultsView({required this.query});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFF374151),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada hasil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada artikel tersimpan yang cocok\ndengan "$query"',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
