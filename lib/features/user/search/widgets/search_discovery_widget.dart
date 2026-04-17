import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/search/providers/search_provider.dart';
import 'package:inersia_supabase/features/user/search/services/search_service.dart';
import 'package:inersia_supabase/features/user/search/widgets/search_results_card.dart';

class SearchDiscoveryWidget extends ConsumerWidget {
  final ValueChanged<TagResult> onTagTap;
  final ValueChanged<CategoryResult> onCategoryTap;

  const SearchDiscoveryWidget({
    super.key,
    required this.onTagTap,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(discoveryProvider);

    return discoveryAsync.when(
      data: (data) => CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              if (data.categories.isNotEmpty) ...[
                const _SectionTitle('Jelajahi Kategori'),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.categories.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => SearchCategoryChip(
                      category: data.categories[i],
                      onTap: () => onCategoryTap(data.categories[i]),
                    ),
                  ),
                ),
              ],

              if (data.popularTags.isNotEmpty) ...[
                const _SectionTitle('Tag Populer'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.popularTags
                        .take(7)
                        .map(
                          (t) =>
                              SearchTagChip(tag: t, onTap: () => onTagTap(t)),
                        )
                        .toList(),
                  ),
                ),
              ],

              if (data.trending.isNotEmpty) ...[
                const _TrendingTitle(),
                ...data.trending
                    .take(6)
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SearchArticleCard(article: a, compact: true),
                      ),
                    ),
              ],

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _TrendingTitle extends StatelessWidget {
  const _TrendingTitle();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
    child: Row(
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: Color(0xFFEF4444),
          size: 18,
        ),
        SizedBox(width: 6),
        Text(
          'Trending',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
