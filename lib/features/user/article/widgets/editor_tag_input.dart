import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/article/providers/user_article_provider.dart';
import 'package:inersia_supabase/features/user/article/widgets/editor_suggest_tile.dart';
import 'package:inersia_supabase/models/tag_model.dart';

const int _maxTags = 5;

class EditorTagInput extends StatelessWidget {
  final ValueNotifier<List<TagModel>> selectedTags;
  final VoidCallback onChanged;
  final WidgetRef ref;
  final BuildContext context;
  const EditorTagInput({
    required this.selectedTags,
    required this.onChanged,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    final isFull = selectedTags.value.length >= _maxTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFull)
          TypeAheadField<String>(
            builder: (_, ctrl, fn) => TextField(
              controller: ctrl,
              focusNode: fn,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Cari atau tambah tag...').copyWith(
                prefixIcon: const Icon(
                  Icons.tag,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
              ),
            ),
            suggestionsCallback: (p) async {
              if (p.trim().isEmpty) return [];
              final tags = await ref
                  .read(userArticleServiceProvider)
                  .getTags(query: p);
              final list = tags.map((e) => e.name).toList();
              if (!list.any((n) => n.toLowerCase() == p.toLowerCase())) {
                list.add('+ Tambah "$p"');
              }
              return list;
            },
            itemBuilder: (_, s) =>
                SuggestTile(text: s, isAction: s.startsWith('+ ')),
            onSelected: (val) async {
              if (selectedTags.value.length >= _maxTags) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maksimal $_maxTags tag per artikel.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF374151),
                  ),
                );
                return;
              }
              final tagName = val.startsWith('+ Tambah "')
                  ? val.substring(10, val.length - 1)
                  : val;
              if (tagName.trim().isEmpty) return;
              final tag = await ref
                  .read(userArticleServiceProvider)
                  .getOrCreateTag(tagName.trim());
              if (!selectedTags.value.any((e) => e.id == tag.id)) {
                selectedTags.value = [...selectedTags.value, tag];
                onChanged();
              }
            },
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF374151), width: 0.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF6B7280), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maksimal 5 tag. Hapus tag untuk menambah.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        if (selectedTags.value.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: selectedTags.value
                .map(
                  (t) => Chip(
                    label: Text(
                      t.name,
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 12,
                      ),
                    ),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    backgroundColor: const Color(0xFF1E3A5F),
                    side: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onDeleted: () {
                      selectedTags.value = selectedTags.value
                          .where((e) => e.id != t.id)
                          .toList();
                      onChanged();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

InputDecoration _inputDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF4B5563)),
  filled: true,
  fillColor: const Color(0xFF161616),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF161616)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF161616)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
  ),
);
