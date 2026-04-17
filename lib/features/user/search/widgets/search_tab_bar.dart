import 'package:flutter/material.dart';
import 'package:inersia_supabase/features/user/search/providers/search_provider.dart';
import 'package:inersia_supabase/features/user/search/services/search_service.dart';

class SearchTabBar extends StatelessWidget {
  final SearchTab activeTab;
  final SearchResults results;
  final ValueChanged<SearchTab> onTabChanged;

  const SearchTabBar({
    super.key,
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
            _Tab(
              'Artikel (${results.articles.length})',
              SearchTab.articles,
              activeTab,
              onTabChanged,
            ),
          if (results.users.isNotEmpty)
            _Tab(
              'User (${results.users.length})',
              SearchTab.users,
              activeTab,
              onTabChanged,
            ),
          if (results.tags.isNotEmpty)
            _Tab(
              'Tag (${results.tags.length})',
              SearchTab.tags,
              activeTab,
              onTabChanged,
            ),
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
