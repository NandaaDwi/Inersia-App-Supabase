import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/profile/services/draft_service.dart';
import 'package:inersia_supabase/models/article_model.dart';

final draftServiceProvider =
    Provider.autoDispose((_) => DraftService());


class DraftState {
  final List<ArticleModel> drafts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int page;

  const DraftState({
    this.drafts = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
  });

  DraftState copyWith({
    List<ArticleModel>? drafts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? page,
    bool clearError = false,
  }) {
    return DraftState(
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
    );
  }
}


class DraftNotifier extends StateNotifier<DraftState> {
  final DraftService _service;

  DraftNotifier(this._service) : super(const DraftState()) {
    _fetch(0);
  }

  Future<void> _fetch(int page) async {
    try {
      final results = await _service.getDrafts(page: page);
      if (!mounted) return;

      final newList =
          page == 0 ? results : [...state.drafts, ...results];
      state = state.copyWith(
        drafts: newList,
        isLoading: false,
        isLoadingMore: false,
        hasMore: results.length == 15,
        page: page,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Gagal memuat draft.',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetch(0);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetch(state.page + 1);
  }

  Future<void> deleteDraft(String articleId) async {
    final backup = state.drafts;
    state = state.copyWith(
      drafts: state.drafts.where((a) => a.id != articleId).toList(),
    );

    try {
      await _service.deleteDraft(articleId);
    } catch (_) {
      if (mounted) state = state.copyWith(drafts: backup);
    }
  }
}

final draftProvider =
    StateNotifierProvider.autoDispose<DraftNotifier, DraftState>(
  (ref) => DraftNotifier(ref.read(draftServiceProvider)),
);