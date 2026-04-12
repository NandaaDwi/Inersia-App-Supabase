import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageArticle/providers/admin_article_provider.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_category_service.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_tag_service.dart';
import 'package:inersia_supabase/models/category_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';

class EditorCategoryTagSection extends ConsumerWidget {
  final TextEditingController categoryController;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueNotifier<List<TagModel>> selectedTags;
  final bool isCategoryLoading;

  final int maxTags;

  const EditorCategoryTagSection({
    super.key,
    required this.categoryController,
    required this.selectedCategoryId,
    required this.selectedTags,
    required this.isCategoryLoading,
    this.maxTags = 5,
  });

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4B5563)),
      filled: true,
      fillColor: const Color(0xFF111827),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1F2937)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1F2937)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagCount = selectedTags.value.length;
    final isTagFull = tagCount >= maxTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label(label: 'Kategori'),
        const SizedBox(height: 8),
        isCategoryLoading
            ? const _LoadingIndicator(text: 'Memuat kategori...')
            : TypeAheadField<CategoryModel>(
                controller: categoryController,
                builder: (context, controller, focusNode) => TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Pilih kategori...'),
                ),
                onSelected: (s) {
                  categoryController.text = s.name;
                  selectedCategoryId.value = s.id;
                },
                suggestionsCallback: (p) =>
                    AdminCategoryService().getCategories(query: p),
                itemBuilder: (context, s) => _SuggestionTile(text: s.name),
              ),
        const SizedBox(height: 20),

        Row(
          children: [
            const _Label(label: 'Tag'),
            const SizedBox(width: 8),
            Text(
              '$tagCount/$maxTags',
              style: TextStyle(
                color: isTagFull
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (!isTagFull)
          TypeAheadField<String>(
            builder: (context, controller, focusNode) => TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Cari atau tambah tag...').copyWith(
                prefixIcon: const Icon(
                  Icons.tag,
                  color: Color(0xFF6B7280),
                  size: 18,
                ),
              ),
            ),
            suggestionsCallback: (pattern) async {
              if (pattern.trim().isEmpty) return [];
              final tags = await AdminTagService().getTags(query: pattern);
              final list = tags.map((e) => e.name).toList();
              if (!list.any((n) => n.toLowerCase() == pattern.toLowerCase())) {
                list.add('+ Tambah "$pattern"');
              }
              return list;
            },
            itemBuilder: (context, suggestion) => _SuggestionTile(
              text: suggestion,
              isAction: suggestion.startsWith('+ '),
            ),
            onSelected: (val) async {
              if (selectedTags.value.length >= maxTags) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maksimal $maxTags tag per artikel.'),
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
                  .read(adminArticleServiceProvider)
                  .getOrCreateTag(tagName.trim());

              if (!selectedTags.value.any((e) => e.id == tag.id)) {
                selectedTags.value = [...selectedTags.value, tag];
              }
            },
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF374151), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF6B7280),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Maksimal $maxTags tag tercapai. Hapus tag untuk menambah.',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
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
                    onDeleted: () => selectedTags.value = selectedTags.value
                        .where((e) => e.id != t.id)
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );
}

class _SuggestionTile extends StatelessWidget {
  final String text;
  final bool isAction;
  const _SuggestionTile({required this.text, this.isAction = false});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF1F2937),
    child: ListTile(
      title: Text(
        text,
        style: TextStyle(
          color: isAction ? const Color(0xFF60A5FA) : Colors.white,
        ),
      ),
    ),
  );
}

class _LoadingIndicator extends StatelessWidget {
  final String text;
  const _LoadingIndicator({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF6B7280))),
      ],
    ),
  );
}
