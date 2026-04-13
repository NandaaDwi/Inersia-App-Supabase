import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageArticle/providers/admin_article_provider.dart';
import 'package:inersia_supabase/features/admin/manageArticle/widgets/editor_rich_text.dart';
import 'package:inersia_supabase/features/admin/manageArticle/widgets/editor_category_tag_section.dart';
import 'package:inersia_supabase/features/admin/manageArticle/widgets/thumbnail_picker.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_category_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';
import 'package:inersia_supabase/utils/moderation_client.dart';
import 'package:inersia_supabase/utils/word_filter.dart';

const int _maxTags = 5;

class ArticleEditorScreen extends HookConsumerWidget {
  final ArticleModel? article;
  const ArticleEditorScreen({super.key, this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleCtrl = useTextEditingController(text: article?.title ?? '');
    final categoryCtrl = useTextEditingController();
    final selectedCategoryId = useState<String?>(article?.categoryId);
    final selectedTags = useState<List<TagModel>>(article?.tags ?? const []);
    final isCategoryLoading = useState(false);
    final isSaving = useState(false);
    final isChecking = useState(false);
    final thumbnail = useState<File?>(null);

    final editorFocusNode = useMemoized(() => FocusNode());
    final editorScrollCtrl = useMemoized(() => ScrollController());

    final quillCtrl = useMemoized(() {
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

    useEffect(() => quillCtrl.dispose, const []);

    useEffect(() {
      if (article != null && article!.categoryId.isNotEmpty) {
        isCategoryLoading.value = true;
        AdminCategoryService()
            .getCategoryById(article!.categoryId)
            .then((cat) {
              if (cat != null) categoryCtrl.text = cat.name;
            })
            .whenComplete(() => isCategoryLoading.value = false);
      }
      return null;
    }, [article?.categoryId]);

    Future<void> handleSave(String status) async {
      if (selectedCategoryId.value == null) {
        _snack(context, 'Pilih kategori terlebih dahulu!');
        return;
      }
      final title = titleCtrl.text.trim();
      final plain = quillCtrl.document.toPlainText().trim();

      if (title.isEmpty || plain.isEmpty) {
        _snack(context, 'Judul dan isi artikel tidak boleh kosong!');
        return;
      }

      if (status == 'published') {
        final fullText = '$title $plain';

        final bad = WordFilter.checkFirst(fullText);
        if (bad != null) {
          _snackError(
            context,
            'Konten mengandung kata tidak pantas. Hapus sebelum dipublikasi.',
          );
          return;
        }

        isChecking.value = true;
        try {
          final r = await ModerationClient.moderateArticle(fullText);
          if (!r.allowed) {
            if (context.mounted) {
              _snackError(
                context,
                r.reason ?? 'Konten tidak dapat dipublikasi.',
              );
            }
            return;
          }
        } finally {
          isChecking.value = false;
        }
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
              title: title,
              content: jsonEncode(quillCtrl.document.toDelta().toJson()),
              categoryId: selectedCategoryId.value!,
              tagIds: selectedTags.value.map((e) => e.id).toList(),
              thumbnail: imageUrl,
              status: status,
            );

        ref.invalidate(adminArticlesProvider);
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        if (context.mounted) {
          _snackError(context, 'Gagal menyimpan: $e');
        }
      } finally {
        isSaving.value = false;
      }
    }

    final isProcessing = isSaving.value || isChecking.value;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      bottomSheet: QuillKeyboardToolbar(controller: quillCtrl),
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
          article == null ? 'Buat Artikel' : 'Edit Artikel',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          if (!isProcessing) ...[
            TextButton(
              onPressed: () => handleSave('draft'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9CA3AF),
              ),
              child: const Text(
                'Draft',
                style: TextStyle(fontWeight: FontWeight.w500),
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
                  elevation: 0,
                ),
                child: const Text(
                  'Publish',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isChecking.value)
                    const Text(
                      'Memeriksa...',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThumbnailPicker(thumbnail: thumbnail, article: article),
            const SizedBox(height: 24),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Judul Artikel',
                hintStyle: TextStyle(color: Color(0xFF4B5563)),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Color(0xFF1F2937)),
            const SizedBox(height: 20),
            EditorCategoryTagSection(
              categoryController: categoryCtrl,
              selectedCategoryId: selectedCategoryId,
              selectedTags: selectedTags,
              isCategoryLoading: isCategoryLoading.value,
              maxTags: _maxTags,
            ),
            const SizedBox(height: 24),
            EditorRichText(
              controller: quillCtrl,
              scrollController: editorScrollCtrl,
              focusNode: editorFocusNode,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void _snack(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF374151),
        ),
      );

  static void _snackError(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );
}
