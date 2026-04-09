import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/comments/services/admin_comment_service.dart';

final adminCommentServiceProvider = Provider.autoDispose(
  (_) => AdminCommentService(),
);

final commentSearchRawProvider = StateProvider.autoDispose<String>((ref) => '');

final commentSearchProvider =
    StateNotifierProvider.autoDispose<_DebounceNotifier, String>(
      (ref) => _DebounceNotifier(ref),
    );

class _DebounceNotifier extends StateNotifier<String> {
  final Ref _ref;
  Timer? _timer;

  _DebounceNotifier(this._ref) : super('') {
    _ref.listen<String>(commentSearchRawProvider, (_, next) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) state = next;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class CommentAdminState {
  final List<AdminCommentItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int page;
  final Set<String> selectedIds;
  final bool isSelectMode;

  const CommentAdminState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.page = 0,
    this.selectedIds = const {},
    this.isSelectMode = false,
  });

  CommentAdminState copyWith({
    List<AdminCommentItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? page,
    Set<String>? selectedIds,
    bool? isSelectMode,
  }) {
    return CommentAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectMode: isSelectMode ?? this.isSelectMode,
    );
  }
}

class CommentAdminNotifier extends StateNotifier<CommentAdminState> {
  final AdminCommentService _service;
  final Ref _ref;

  CommentAdminNotifier(this._service, this._ref)
    : super(const CommentAdminState()) {
    _ref.listen<String>(commentSearchProvider, (_, __) => _reset());
    _fetchInitial();
  }

  void _reset() {
    state = const CommentAdminState(isLoading: true);
    _fetch(0);
  }

  Future<void> _fetchInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetch(0);
  }

  Future<void> _fetch(int page) async {
    try {
      final results = await _service.getComments(
        page: page,
        query: _ref.read(commentSearchProvider),
      );
      final newList = page == 0 ? results : [...state.items, ...results];
      state = state.copyWith(
        items: newList,
        isLoading: false,
        isLoadingMore: false,
        hasMore: results.length == 20,
        page: page,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => _fetchInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetch(state.page + 1);
  }


  Future<void> deleteComment(String commentId) async {
    try {
      await _service.deleteComment(commentId);
      state = state.copyWith(
        items: state.items.where((c) => c.id != commentId).toList(),
        selectedIds: {...state.selectedIds}..remove(commentId),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> banUser(String userId) async {
    await _service.banUser(userId);
  }

  Future<void> sendWarning({
    required String targetUserId,
    required String commentText,
    required String articleTitle,
  }) async {
    await _service.sendWarning(
      targetUserId: targetUserId,
      commentText: commentText,
      articleTitle: articleTitle,
    );
  }

  void enterSelectMode() {
    state = state.copyWith(isSelectMode: true, selectedIds: {});
  }

  void exitSelectMode() {
    state = state.copyWith(isSelectMode: false, selectedIds: {});
  }

  void toggleSelection(String id) {
    final newSet = Set<String>.from(state.selectedIds);
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = state.copyWith(selectedIds: newSet);
  }

  void selectAll() {
    state = state.copyWith(selectedIds: state.items.map((c) => c.id).toSet());
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> bulkDelete() async {
    if (state.selectedIds.isEmpty) return;
    final ids = state.selectedIds.toList();
    try {
      await _service.bulkDeleteComments(ids);
      state = state.copyWith(
        items: state.items
            .where((c) => !state.selectedIds.contains(c.id))
            .toList(),
        selectedIds: {},
        isSelectMode: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final commentAdminProvider =
    StateNotifierProvider.autoDispose<CommentAdminNotifier, CommentAdminState>(
      (ref) => CommentAdminNotifier(ref.read(adminCommentServiceProvider), ref),
    );
