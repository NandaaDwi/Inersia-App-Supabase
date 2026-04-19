import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/article/providers/user_article_provider.dart';
import 'package:inersia_supabase/features/user/article/widgets/editor_load_row.dart';
import 'package:inersia_supabase/features/user/article/widgets/editor_suggest_tile.dart';
import 'package:inersia_supabase/models/category_model.dart';

class EditorCategoryInput extends StatelessWidget {
  final TextEditingController categoryCtrl;
  final ValueNotifier<String?> selectedCategoryId;
  final bool isLoading;
  final VoidCallback onChanged;
  final WidgetRef ref;
  const EditorCategoryInput({
    required this.categoryCtrl,
    required this.selectedCategoryId,
    required this.isLoading,
    required this.onChanged,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const LoadRow(text: 'Memuat kategori...');
    return TypeAheadField<CategoryModel>(
      controller: categoryCtrl,
      builder: (_, ctrl, fn) => TextField(
        controller: ctrl,
        focusNode: fn,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => onChanged(),
        decoration: _inputDeco('Pilih kategori...'),
      ),
      onSelected: (s) {
        categoryCtrl.text = s.name;
        selectedCategoryId.value = s.id;
        onChanged();
      },
      suggestionsCallback: (p) async {
        try {
          return await ref
              .read(userArticleServiceProvider)
              .getCategories(query: p);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Gagal memuat kategori.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return [];
        }
      },
      itemBuilder: (_, s) => SuggestTile(text: s.name),
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
