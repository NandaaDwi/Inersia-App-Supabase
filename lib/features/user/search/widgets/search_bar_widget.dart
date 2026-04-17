import 'package:flutter/material.dart';
import 'package:inersia_supabase/features/user/search/services/search_service.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasQuery;
  final bool isSuggesting;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
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
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2937), width: 1.5),
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
                      : const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF4B5563),
                          size: 22,
                        ),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: onClear,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
              child: const Text(
                'Cari',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SuggestionListWidget extends StatelessWidget {
  final List<SuggestionItem> suggestions;
  final ValueChanged<SuggestionItem> onTap;

  const SuggestionListWidget({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Container(
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
          child: SingleChildScrollView(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        _SuggestIcon(type: s.type),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (s.subtitle != null)
                                Text(
                                  s.subtitle!,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.north_west_rounded,
                          color: Color(0xFF374151),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestIcon extends StatelessWidget {
  final SearchResultType type;
  const _SuggestIcon({required this.type});

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
