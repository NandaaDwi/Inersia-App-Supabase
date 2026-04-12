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
import 'package:inersia_supabase/utils/moderation_client.dart';
import 'package:inersia_supabase/utils/word_filter.dart';
import '../widgets/editor_category_tag_section.dart';

/// Batas maksimal tag per artikel
const int _maxTags = 5;

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
    final isChecking = useState(false);
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
          const SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
        );
        return;
      }

      final title = titleController.text.trim();
      final plainText = quillController.document.toPlainText().trim();

      if (title.isEmpty || plainText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Judul dan isi artikel tidak boleh kosong!'),
          ),
        );
        return;
      }

      // Filter konten — hanya saat Publish
      if (status == 'published') {
        final fullText = '$title $plainText';

        // Layer 1: Filter lokal (SELALU bekerja)
        final badWords = WordFilter.check(fullText);
        if (badWords.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Konten mengandung kata tidak pantas: ${badWords.take(3).join(", ")}',
              ),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
          return;
        }

        // Layer 2: Edge Function → OpenAI
        isChecking.value = true;
        try {
          final result = await ModerationClient.moderateArticle(fullText);
          if (!result.allowed && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.reason ?? 'Konten tidak dapat dipublikasi.',
                ),
                backgroundColor: const Color(0xFFDC2626),
                duration: const Duration(seconds: 4),
              ),
            );
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
              title: titleController.text,
              content: jsonEncode(quillController.document.toDelta().toJson()),
              categoryId: selectedCategoryId.value!,
              tagIds: selectedTags.value.map((e) => e.id).toList(),
              thumbnail: imageUrl,
              status: status,
            );

        ref.invalidate(adminArticlesProvider);
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
        }
      } finally {
        isSaving.value = false;
      }
    }

    final isProcessing = isSaving.value || isChecking.value;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      // Toolbar sticky di atas keyboard
      bottomSheet: _AdminKeyboardToolbar(controller: quillController),
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                hintText: 'Judul Artikel',
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
              maxTags: _maxTags,
            ),
            const SizedBox(height: 24),

            // Editor konten
            const Text(
              'KONTEN',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _AdminEditorBody(
              controller: quillController,
              scrollController: editorScrollController,
              focusNode: editorFocusNode,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Editor Body ────────────────────────────────────────

class _AdminEditorBody extends StatelessWidget {
  final quill.QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;

  const _AdminEditorBody({
    required this.controller,
    required this.scrollController,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: quill.QuillEditor(
        controller: controller,
        scrollController: scrollController,
        focusNode: focusNode,
        config: quill.QuillEditorConfig(
          scrollable: false,
          expands: false,
          autoFocus: false,
          placeholder: 'Mulai menulis konten artikel...',
          padding: EdgeInsets.zero,
          customStyles: quill.DefaultStyles(
            paragraph: quill.DefaultTextBlockStyle(
              const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
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
            h1: quill.DefaultTextBlockStyle(
              const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(8, 4),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h2: quill.DefaultTextBlockStyle(
              const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(6, 4),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            quote: quill.DefaultTextBlockStyle(
              const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
                height: 1.7,
                fontStyle: FontStyle.italic,
              ),
              const quill.HorizontalSpacing(16, 0),
              const quill.VerticalSpacing(6, 6),
              const quill.VerticalSpacing(0, 0),
              BoxDecoration(
                border: const Border(
                  left: BorderSide(color: Color(0xFF2563EB), width: 3),
                ),
                color: const Color(0xFF111827),
              ),
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
    );
  }
}

// ─── Toolbar Admin (identik dengan user) ─────────────────────

class _AdminKeyboardToolbar extends StatelessWidget {
  final quill.QuillController controller;
  const _AdminKeyboardToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111827),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF1F2937), width: 0.5),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                _AHeadBtn(c: controller, level: 1, label: 'H1'),
                _AHeadBtn(c: controller, level: 2, label: 'H2'),
                _AHeadBtn(c: controller, level: 3, label: 'H3'),
                _ASep(),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.bold,
                  icon: Icons.format_bold,
                ),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.italic,
                  icon: Icons.format_italic,
                ),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.underline,
                  icon: Icons.format_underline,
                ),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.strikeThrough,
                  icon: Icons.format_strikethrough,
                ),
                _ASep(),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.ul,
                  icon: Icons.format_list_bulleted,
                ),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.ol,
                  icon: Icons.format_list_numbered,
                ),
                _ASep(),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.blockQuote,
                  icon: Icons.format_quote,
                ),
                _ATogBtn(
                  c: controller,
                  attr: quill.Attribute.codeBlock,
                  icon: Icons.code,
                ),
                _ASep(),
                _AActBtn(
                  icon: Icons.format_align_left,
                  onTap: () =>
                      controller.formatSelection(quill.Attribute.leftAlignment),
                ),
                _AActBtn(
                  icon: Icons.format_align_center,
                  onTap: () => controller.formatSelection(
                    quill.Attribute.centerAlignment,
                  ),
                ),
                _AActBtn(
                  icon: Icons.format_align_right,
                  onTap: () => controller.formatSelection(
                    quill.Attribute.rightAlignment,
                  ),
                ),
                _ASep(),
                _AActBtn(
                  icon: Icons.undo,
                  onTap: () {
                    if (controller.hasUndo) controller.undo();
                  },
                ),
                _AActBtn(
                  icon: Icons.redo,
                  onTap: () {
                    if (controller.hasRedo) controller.redo();
                  },
                ),
                _ASep(),
                _AActBtn(
                  icon: Icons.format_clear,
                  onTap: () {
                    controller.formatSelection(
                      quill.Attribute.clone(quill.Attribute.bold, null),
                    );
                    controller.formatSelection(
                      quill.Attribute.clone(quill.Attribute.italic, null),
                    );
                    controller.formatSelection(
                      quill.Attribute.clone(quill.Attribute.underline, null),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ASep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    color: const Color(0xFF1F2937),
  );
}

class _AHeadBtn extends StatelessWidget {
  final quill.QuillController c;
  final int level;
  final String label;
  const _AHeadBtn({required this.c, required this.level, required this.label});
  @override
  Widget build(BuildContext context) {
    bool isActive = false;
    try {
      isActive = c.getSelectionStyle().attributes['header']?.value == level;
    } catch (_) {}
    return GestureDetector(
      onTap: () {
        if (isActive) {
          c.formatSelection(quill.Attribute.header);
        } else {
          c.formatSelection(quill.Attribute.fromKeyValue('header', level));
        }
      },
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        alignment: Alignment.center,
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(5),
              )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ATogBtn extends StatelessWidget {
  final quill.QuillController c;
  final quill.Attribute attr;
  final IconData icon;
  const _ATogBtn({required this.c, required this.attr, required this.icon});
  @override
  Widget build(BuildContext context) {
    bool isActive = false;
    try {
      final attrs = c.getSelectionStyle().attributes;
      final val = attrs[attr.key];
      isActive = attr.key == 'list'
          ? val?.value == attr.value
          : val?.value == true;
    } catch (_) {}
    return GestureDetector(
      onTap: () => c.formatSelection(
        isActive ? quill.Attribute.clone(attr, null) : attr,
      ),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        alignment: Alignment.center,
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(5),
              )
            : null,
        child: Icon(
          icon,
          size: 17,
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _AActBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AActBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: const Color(0xFF9CA3AF)),
    ),
  );
}
