import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageArticle/providers/admin_article_provider.dart';
import 'package:inersia_supabase/features/admin/manageArticle/widgets/thumbnail_picker.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_category_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';
import 'package:inersia_supabase/utils/word_filter_utils.dart';
import '../widgets/editor_category_tag_section.dart';
import '../widgets/editor_rich_text.dart';

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

    final quillController = useMemoized(() {
      if (article != null && article!.content.isNotEmpty) {
        try {
          return quill.QuillController(
            document: quill.Document.fromJson(jsonDecode(article!.content)),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (_) {}
      }
      return quill.QuillController.basic();
    });

    useEffect(() {
      if (article != null && article!.categoryId.isNotEmpty) {
        isCategoryLoading.value = true;
        AdminCategoryService()
            .getCategoryById(article!.categoryId)
            .then((cat) {
              if (cat != null) categoryController.text = cat.name;
            })
            .whenComplete(() => isCategoryLoading.value = false);
      }
      return null;
    }, [article?.categoryId]);

    Future<void> handleSave(String status) async {
      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih kategori terlebih dahulu!")),
        );
        return;
      }

      final title = titleController.text.trim();
      final plainText = quillController.document.toPlainText().trim();

      if (title.isEmpty || plainText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Judul dan isi artikel tidak boleh kosong!"),
          ),
        );
        return;
      }

      final combinedText = "$title $plainText";
      final badWordsFound = WordFilterUtils.checkBadWords(combinedText);

      if (badWordsFound.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ditemukan kata terlarang (${badWordsFound.join(", ")})',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
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
              content: jsonEncode(quillController.document.toDelta().toJson()),
              categoryId: selectedCategoryId.value!,
              tagIds: selectedTags.value.map((e) => e.id).toList(),
              thumbnail: imageUrl,
              status: status,
            );

        ref.invalidate(adminArticlesProvider);

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
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
              child: const Text(
                "Draft",
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: () => handleSave('published'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Publish"),
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
            ThumbnailPicker(thumbnail: thumbnail, article: article),
            const SizedBox(height: 24),
            TextField(
              controller: titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Judul Artikel",
                hintStyle: TextStyle(color: Color(0xFF4B5563)),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Color(0xFF1F2937)),
            const SizedBox(height: 20),
            EditorCategoryTagSection(
              categoryController: categoryController,
              selectedCategoryId: selectedCategoryId,
              selectedTags: selectedTags,
              isCategoryLoading: isCategoryLoading.value,
            ),
            const SizedBox(height: 24),
            EditorRichText(
              controller: quillController,
              scrollController: editorScrollController,
              focusNode: editorFocusNode,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
