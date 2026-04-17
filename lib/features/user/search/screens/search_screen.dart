import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/mainPage/widgets/app_bottom_bar.dart';
import 'package:inersia_supabase/features/user/search/providers/search_provider.dart';
import 'package:inersia_supabase/features/user/search/widgets/search_bar_widget.dart';
import 'package:inersia_supabase/features/user/search/widgets/search_discovery_widget.dart';
import 'package:inersia_supabase/features/user/search/widgets/search_results_card.dart';
import 'package:inersia_supabase/features/user/search/widgets/search_results_widget.dart';
import 'package:inersia_supabase/features/user/search/widgets/search_tab_bar.dart';
import 'package:inersia_supabase/utils/nav_utils.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final controller = useTextEditingController(text: state.query);
    final focusNode = useFocusNode();
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Text(
          'Pencarian',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF1F2937)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SearchBarWidget(
              controller: controller,
              focusNode: focusNode,
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

            if (state.showSuggestions && focusNode.hasFocus)
              SuggestionListWidget(
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

            if (state.hasResults)
              SearchTabBar(
                activeTab: state.activeTab,
                results: state.results!,
                onTabChanged: (t) =>
                    ref.read(searchProvider.notifier).setTab(t),
              ),

            Expanded(
              child: GestureDetector(
                onTap: () => focusNode.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: _SearchBody(state: state, ref: ref),
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

class _SearchBody extends ConsumerWidget {
  final SearchState state;
  final WidgetRef ref;
  const _SearchBody({required this.state, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
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
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF374151),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(searchProvider.notifier).search(state.query),
              child: const Text(
                'Coba lagi',
                style: TextStyle(color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
      );
    }

    if (state.hasResults) return SearchResultsWidget(state: state);

    if (state.hasQuery && state.results != null && state.results!.isEmpty) {
      return SearchNoResults(query: state.query);
    }

    return SearchDiscoveryWidget(
      onTagTap: (t) => ref.read(searchProvider.notifier).searchByTag(t),
      onCategoryTap: (c) =>
          ref.read(searchProvider.notifier).searchByCategory(c),
    );
  }
}
