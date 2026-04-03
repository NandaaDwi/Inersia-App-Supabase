import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inersia_supabase/features/admin/manageArticle/providers/admin_article_provider.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_category_service.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_tag_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';

class ArticleEditorScreen extends HookConsumerWidget {
  final ArticleModel? article;
  const ArticleEditorScreen({super.key, this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(text: article?.title);
    final categoryController = useTextEditingController();
    final selectedCategoryId = useState<String?>(article?.categoryId);
    final selectedTags = useState<List<TagModel>>(article?.tags ?? []);
    final isCategoryLoading = useState(false);
    final isSaving = useState(false);
    final thumbnail = useState<File?>(null);

    final editorScrollController = useMemoized(() => ScrollController());
    final editorFocusNode = useMemoized(() => FocusNode());

    useEffect(() {
      return () {
        editorScrollController.dispose();
        editorFocusNode.dispose();
      };
    }, const []);

    final quillController = useMemoized(() {
      if (article != null && article!.content.isNotEmpty) {
        try {
          return quill.QuillController(
            document: quill.Document.fromJson(jsonDecode(article!.content)),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (_) {
          return quill.QuillController.basic();
        }
      }
      return quill.QuillController.basic();
    });

    useEffect(() {
      return quillController.dispose;
    }, const []);

    useEffect(() {
      if (article != null && article!.categoryId.isNotEmpty) {
        isCategoryLoading.value = true;
        AdminCategoryService()
            .getCategoryById(article!.categoryId)
            .then((cat) {
              if (cat != null) categoryController.text = cat.name;
            })
            .catchError((_) {
              categoryController.text = '';
            })
            .whenComplete(() {
              isCategoryLoading.value = false;
            });
      }
      return null;
    }, [article?.categoryId]);

    bool hasProfanity(String text) {
      const badWords = ['kasar1', 'kasar2', 'spam'];
      return badWords.any((w) => text.toLowerCase().contains(w));
    }

    Future<void> handleSave(String status) async {
      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih kategori terlebih dahulu!")),
        );
        return;
      }

      final contentRaw = jsonEncode(
        quillController.document.toDelta().toJson(),
      );
      final plainText = quillController.document.toPlainText();

      if (hasProfanity(titleController.text) || hasProfanity(plainText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konten mengandung kata tidak pantas!")),
        );
        return;
      }

      isSaving.value = true;
      try {
        String? imageUrl = article?.thumbnail;

        if (thumbnail.value != null) {
          imageUrl = await ref
              .read(adminArticleServiceProvider)
              .uploadThumbnail(thumbnail.value!);
        }

        await ref
            .read(adminArticleServiceProvider)
            .saveArticle(
              id: article?.id,
              title: titleController.text,
              content: contentRaw,
              categoryId: selectedCategoryId.value!,
              tagIds: selectedTags.value.map((e) => e.id).toList(),
              thumbnail: imageUrl,
              status: status,
            );

        ref.invalidate(adminArticlesProvider);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          article == null ? "Buat Artikel" : "Edit Artikel",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          if (!isSaving.value) ...[
            TextButton(
              onPressed: () => handleSave('draft'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9CA3AF),
              ),
              child: const Text(
                "Draft",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: () => handleSave('published'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Publish",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final xfile = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (xfile != null) thumbnail.value = File(xfile.path);
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1F2937),
                    width: 1.5,
                  ),
                ),
                child: thumbnail.value != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(thumbnail.value!, fit: BoxFit.cover),
                      )
                    : (article?.thumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                article!.thumbnail!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _thumbnailEmpty(),
                              ),
                            )
                          : _thumbnailEmpty()),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Judul Artikel",
                hintStyle: TextStyle(color: Color(0xFF4B5563), fontSize: 22),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1F2937), height: 1),
            const SizedBox(height: 20),

            const _SectionLabel(label: "Kategori"),
            const SizedBox(height: 8),
            isCategoryLoading.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Memuat kategori...",
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : TypeAheadField<CategoryModel>(
                    controller: categoryController,
                    builder: (context, controller, focusNode) => TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Pilih kategori..."),
                    ),
                    onSelected: (s) {
                      categoryController.text = s.name;
                      selectedCategoryId.value = s.id;
                    },
                    suggestionsCallback: (p) =>
                        AdminCategoryService().getCategories(query: p),
                    itemBuilder: (context, s) => Container(
                      color: const Color(0xFF1F2937),
                      child: ListTile(
                        title: Text(
                          s.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),

            const _SectionLabel(label: "Tag"),
            const SizedBox(height: 8),
            TypeAheadField<String>(
              builder: (context, controller, focusNode) => TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Cari atau tambah tag...")
                    .copyWith(
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
                if (!list.any(
                  (n) => n.toLowerCase() == pattern.toLowerCase(),
                )) {
                  list.add("+ Tambah \"$pattern\"");
                }
                return list;
              },
              itemBuilder: (context, suggestion) => Container(
                color: const Color(0xFF1F2937),
                child: ListTile(
                  title: Text(
                    suggestion,
                    style: TextStyle(
                      color: suggestion.startsWith('+ ')
                          ? const Color(0xFF60A5FA)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              onSelected: (val) async {
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
            const SizedBox(height: 24),

            const _SectionLabel(label: "Konten"),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: quill.QuillSimpleToolbar(
                controller: quillController,
                config: const quill.QuillSimpleToolbarConfig(
                  showFontFamily: false,
                  showFontSize: false,
                  multiRowsDisplay: false,
                  toolbarIconAlignment: WrapAlignment.start,
                ),
              ),
            ),

            Container(
              height: 400,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, fontSize: 15),
                child: quill.QuillEditor(
                  controller: quillController,
                  scrollController: editorScrollController,
                  focusNode: editorFocusNode,
                  config: quill.QuillEditorConfig(
                    placeholder: 'Mulai menulis konten artikel...',
                    padding: EdgeInsets.zero,
                    autoFocus: false,
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        const quill.HorizontalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        null,
                      ),
                      bold: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      italic: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontStyle: FontStyle.italic,
                      ),
                      placeHolder: quill.DefaultTextBlockStyle(
                        const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 15,
                          height: 1.6,
                        ),
                        const quill.HorizontalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        const quill.VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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

  Widget _thumbnailEmpty() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: Color(0xFF374151),
          size: 40,
        ),
        SizedBox(height: 8),
        Text(
          "Pilih Thumbnail",
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
