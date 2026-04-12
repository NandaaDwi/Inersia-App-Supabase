import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inersia_supabase/features/user/article/providers/user_article_provider.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';
import 'package:inersia_supabase/utils/moderation_client.dart';
import 'package:inersia_supabase/utils/word_filter.dart';

/// Batas maksimal tag per artikel
const int _maxTags = 5;

class UserArticleEditorScreen extends HookConsumerWidget {
  final ArticleModel? article;
  const UserArticleEditorScreen({super.key, this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(
      text: article?.title ?? '',
    );
    final categoryController = useTextEditingController();
    final selectedCategoryId = useState<String?>(article?.categoryId);
    final selectedTags = useState<List<TagModel>>(article?.tags ?? const []);
    final isCategoryLoading = useState(false);
    final isSaving = useState(false);
    final isChecking = useState(false);
    final thumbnail = useState<File?>(null);
    final hasChanges = useState(false);

    final editorFocusNode = useMemoized(() => FocusNode());
    final editorScrollController = useMemoized(() => ScrollController());

    useEffect(() {
      return () {
        editorFocusNode.dispose();
        editorScrollController.dispose();
      };
    }, const []);

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

    useEffect(() => quillController.dispose, const []);

    useEffect(() {
      void onChange() => hasChanges.value = true;
      quillController.addListener(onChange);
      titleController.addListener(onChange);
      return () {
        quillController.removeListener(onChange);
        titleController.removeListener(onChange);
      };
    }, const []);

    // Pre-fill kategori saat edit
    useEffect(() {
      if (article != null && article!.categoryId.isNotEmpty) {
        isCategoryLoading.value = true;
        ref
            .read(userArticleServiceProvider)
            .getCategoryById(article!.categoryId)
            .then((cat) {
              if (cat != null) categoryController.text = cat.name;
            })
            .catchError((_) => categoryController.text = '')
            .whenComplete(() => isCategoryLoading.value = false);
      }
      return null;
    }, [article?.categoryId]);

    Future<bool> confirmDiscard() async {
      if (!hasChanges.value) return true;
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar dari Editor?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Perubahan yang belum disimpan akan hilang.',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Lanjut Edit',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    Future<void> handleSave(String status) async {
      final title = titleController.text.trim();
      final plainText = quillController.document.toPlainText().trim();

      // ── Validasi dasar ────────────────────────────────────────
      if (title.isEmpty) {
        _snack(context, 'Judul artikel tidak boleh kosong!');
        return;
      }
      if (selectedCategoryId.value == null) {
        _snack(context, 'Pilih kategori terlebih dahulu!');
        return;
      }
      if (plainText.isEmpty) {
        _snack(context, 'Isi konten artikel tidak boleh kosong!');
        return;
      }

      // ── Filter konten — HANYA saat Publish ───────────────────
      if (status == 'published') {
        final fullText = '$title $plainText';

        // Layer 1: Filter lokal (SELALU bekerja, instan)
        // Ini adalah filter utama yang reliable
        final badWords = WordFilter.check(fullText);
        if (badWords.isNotEmpty) {
          _snackError(
            context,
            'Artikel mengandung kata tidak pantas: ${badWords.take(3).join(", ")}.\n'
            'Hapus kata tersebut sebelum dipublikasi.',
          );
          return;
        }

        // Layer 2: OpenAI via Edge Function (opsional, menangkap konteks)
        isChecking.value = true;
        try {
          final result = await ModerationClient.moderateArticle(fullText);
          if (!result.allowed) {
            if (context.mounted) {
              _snackError(
                context,
                result.reason ?? 'Konten tidak dapat dipublikasi.',
              );
            }
            return;
          }
        } finally {
          isChecking.value = false;
        }
      }

      // ── Simpan ke DB ─────────────────────────────────────────
      isSaving.value = true;
      try {
        String? imageUrl = article?.thumbnail;
        if (thumbnail.value != null) {
          imageUrl = await ref
              .read(userArticleServiceProvider)
              .uploadThumbnail(thumbnail.value!);
        }

        await ref
            .read(userArticleServiceProvider)
            .saveArticle(
              id: article?.id,
              title: title,
              content: jsonEncode(quillController.document.toDelta().toJson()),
              categoryId: selectedCategoryId.value!,
              tagIds: selectedTags.value.map((e) => e.id).toList(),
              thumbnail: imageUrl,
              status: status,
            );

        hasChanges.value = false;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'published'
                    ? 'Artikel berhasil dipublikasi!'
                    : 'Artikel disimpan sebagai draft.',
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          _snackError(context, 'Gagal menyimpan: $e');
        }
      } finally {
        isSaving.value = false;
      }
    }

    final isProcessing = isSaving.value || isChecking.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await confirmDiscard();
        if (canLeave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        // ── Toolbar sticky di atas keyboard ─────────────────
        // bottomSheet lebih reliable daripada bottomNavigationBar
        // untuk sticky toolbar Quill
        bottomSheet: _KeyboardToolbar(controller: quillController),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () async {
              final canLeave = await confirmDiscard();
              if (canLeave && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            article == null ? 'Tulis Artikel' : 'Edit Artikel',
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
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
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
          // 100px bottom padding untuk toolbar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _ThumbnailPicker(
                thumbnail: thumbnail,
                article: article,
                onChanged: () => hasChanges.value = true,
              ),
              const SizedBox(height: 24),

              // Judul
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
                  hintText: 'Judul Artikel',
                  hintStyle: TextStyle(color: Color(0xFF4B5563), fontSize: 22),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF1F2937), height: 1),
              const SizedBox(height: 20),

              // Kategori
              const _SectionLabel('KATEGORI'),
              const SizedBox(height: 8),
              isCategoryLoading.value
                  ? const _LoadingRow(text: 'Memuat kategori...')
                  : TypeAheadField<CategoryModel>(
                      controller: categoryController,
                      builder: (_, ctrl, fn) => TextField(
                        controller: ctrl,
                        focusNode: fn,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Pilih kategori...'),
                        onChanged: (_) => hasChanges.value = true,
                      ),
                      onSelected: (s) {
                        categoryController.text = s.name;
                        selectedCategoryId.value = s.id;
                        hasChanges.value = true;
                      },
                      suggestionsCallback: (p) => ref
                          .read(userArticleServiceProvider)
                          .getCategories(query: p),
                      itemBuilder: (_, s) => _SuggestionTile(text: s.name),
                    ),
              const SizedBox(height: 20),

              // Tag — maksimal 5
              Row(
                children: [
                  const _SectionLabel('TAG'),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedTags.value.length}/$_maxTags',
                    style: TextStyle(
                      color: selectedTags.value.length >= _maxTags
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Input tag — disembunyikan jika sudah 5
              if (selectedTags.value.length < _maxTags)
                TypeAheadField<String>(
                  builder: (_, ctrl, fn) => TextField(
                    controller: ctrl,
                    focusNode: fn,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Cari atau tambah tag...')
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
                    final tags = await ref
                        .read(userArticleServiceProvider)
                        .getTags(query: pattern);
                    final list = tags.map((e) => e.name).toList();
                    if (!list.any(
                      (n) => n.toLowerCase() == pattern.toLowerCase(),
                    )) {
                      list.add('+ Tambah "$pattern"');
                    }
                    return list;
                  },
                  itemBuilder: (_, suggestion) => _SuggestionTile(
                    text: suggestion,
                    isAction: suggestion.startsWith('+ '),
                  ),
                  onSelected: (val) async {
                    // Guard maksimal 5 tag
                    if (selectedTags.value.length >= _maxTags) {
                      _snack(context, 'Maksimal $_maxTags tag per artikel.');
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
                      hasChanges.value = true;
                    }
                  },
                )
              else
                // Tampilkan info sudah mencapai batas
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF374151),
                      width: 0.5,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Maksimal 5 tag tercapai. Hapus tag untuk menambah.',
                        style: TextStyle(
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
                          onDeleted: () {
                            selectedTags.value = selectedTags.value
                                .where((e) => e.id != t.id)
                                .toList();
                            hasChanges.value = true;
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),

              // ─── Editor konten ──────────────────────────────
              const _SectionLabel('KONTEN'),
              const SizedBox(height: 8),
              _EditorBody(
                controller: quillController,
                scrollController: editorScrollController,
                focusNode: editorFocusNode,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF374151),
      ),
    );
  }

  static void _snackError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 4),
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
}

// ─── Editor Body ──────────────────────────────────────────────

class _EditorBody extends StatelessWidget {
  final quill.QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;

  const _EditorBody({
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
              const TextStyle(color: Colors.white, fontSize: 15, height: 1.7),
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
            underline: const TextStyle(
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
            strikeThrough: const TextStyle(
              color: Color(0xFF9CA3AF),
              decoration: TextDecoration.lineThrough,
              decorationColor: Color(0xFF9CA3AF),
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
            h3: quill.DefaultTextBlockStyle(
              const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(4, 2),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            lists: quill.DefaultListBlockStyle(
              // Ganti di bagian ini
              const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 15,
                height: 1.6,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              const quill.VerticalSpacing(6, 0),
              null,
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
            code: quill.DefaultTextBlockStyle(
              const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.6,
              ),
              const quill.HorizontalSpacing(12, 12),
              const quill.VerticalSpacing(6, 6),
              const quill.VerticalSpacing(0, 0),
              BoxDecoration(
                color: const Color(0xFF0D1F0F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF1F4730), width: 0.5),
              ),
            ),
            placeHolder: quill.DefaultTextBlockStyle(
              const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 15,
                height: 1.7,
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

// ─── Toolbar Sticky Keyboard ─────────────────────────────────
// Menggunakan bottomSheet agar otomatis naik saat keyboard muncul

class _KeyboardToolbar extends StatelessWidget {
  final quill.QuillController controller;
  const _KeyboardToolbar({required this.controller});

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
                // Heading
                _HeadBtn(controller: controller, level: 1, label: 'H1'),
                _HeadBtn(controller: controller, level: 2, label: 'H2'),
                _HeadBtn(controller: controller, level: 3, label: 'H3'),
                _Sep(),

                // Format teks
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.bold,
                  icon: Icons.format_bold,
                ),
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.italic,
                  icon: Icons.format_italic,
                ),
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.underline,
                  icon: Icons.format_underline,
                ),
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.strikeThrough,
                  icon: Icons.format_strikethrough,
                ),
                _Sep(),

                // List
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.ul,
                  icon: Icons.format_list_bulleted,
                ),
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.ol,
                  icon: Icons.format_list_numbered,
                ),
                _Sep(),

                // Blockquote & Code
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.blockQuote,
                  icon: Icons.format_quote,
                ),
                _TogBtn(
                  controller: controller,
                  attr: quill.Attribute.codeBlock,
                  icon: Icons.code,
                ),
                _Sep(),

                // Alignment
                _AlnBtn(
                  controller: controller,
                  align: quill.Attribute.leftAlignment,
                  icon: Icons.format_align_left,
                ),
                _AlnBtn(
                  controller: controller,
                  align: quill.Attribute.centerAlignment,
                  icon: Icons.format_align_center,
                ),
                _AlnBtn(
                  controller: controller,
                  align: quill.Attribute.rightAlignment,
                  icon: Icons.format_align_right,
                ),
                _Sep(),

                // Indent
                _ActBtn(
                  icon: Icons.format_indent_decrease,
                  onTap: () => controller.indentSelection(false),
                ),
                _ActBtn(
                  icon: Icons.format_indent_increase,
                  onTap: () => controller.indentSelection(true),
                ),
                _Sep(),

                // Undo / Redo
                _ActBtn(
                  icon: Icons.undo,
                  onTap: () {
                    if (controller.hasUndo) controller.undo();
                  },
                ),
                _ActBtn(
                  icon: Icons.redo,
                  onTap: () {
                    if (controller.hasRedo) controller.redo();
                  },
                ),
                _Sep(),

                // Clear format
                _ActBtn(
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

// Compact toolbar widgets untuk bottomSheet

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    color: const Color(0xFF1F2937),
  );
}

class _HeadBtn extends StatelessWidget {
  final quill.QuillController controller;
  final int level;
  final String label;
  const _HeadBtn({
    required this.controller,
    required this.level,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = false;
    try {
      isActive =
          controller.getSelectionStyle().attributes['header']?.value == level;
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        if (isActive) {
          controller.formatSelection(
            quill.Attribute.clone(quill.Attribute.header, null),
          );
        } else {
          controller.formatSelection(
            quill.Attribute.fromKeyValue('header', level),
          );
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

class _TogBtn extends StatelessWidget {
  final quill.QuillController controller;
  final quill.Attribute attr;
  final IconData icon;
  const _TogBtn({
    required this.controller,
    required this.attr,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = false;
    try {
      final attrs = controller.getSelectionStyle().attributes;
      final val = attrs[attr.key];
      if (attr.key == 'list') {
        isActive = val?.value == attr.value;
      } else {
        isActive = val?.value == true;
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        controller.formatSelection(
          isActive ? quill.Attribute.clone(attr, null) : attr,
        );
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
        child: Icon(
          icon,
          size: 17,
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _AlnBtn extends StatelessWidget {
  final quill.QuillController controller;
  final quill.Attribute align;
  final IconData icon;
  const _AlnBtn({
    required this.controller,
    required this.align,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = false;
    try {
      isActive =
          controller.getSelectionStyle().attributes['align']?.value ==
          align.value;
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        controller.formatSelection(
          isActive ? quill.Attribute.clone(quill.Attribute.align, null) : align,
        );
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
        child: Icon(
          icon,
          size: 17,
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActBtn({required this.icon, required this.onTap});

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

// ─── Shared Widgets ───────────────────────────────────────────

class _ThumbnailPicker extends StatelessWidget {
  final ValueNotifier<File?> thumbnail;
  final ArticleModel? article;
  final VoidCallback onChanged;

  const _ThumbnailPicker({
    required this.thumbnail,
    this.article,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final xfile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (xfile != null) {
          thumbnail.value = File(xfile.path);
          onChanged();
        }
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2937), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: thumbnail.value != null
              ? Image.file(thumbnail.value!, fit: BoxFit.cover)
              : article?.thumbnail != null
              ? Image.network(
                  article!.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _empty(),
                )
              : _empty(),
        ),
      ),
    );
  }

  Widget _empty() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.add_photo_alternate_outlined,
        color: Color(0xFF374151),
        size: 40,
      ),
      SizedBox(height: 8),
      Text(
        'Pilih Thumbnail',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
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

class _LoadingRow extends StatelessWidget {
  final String text;
  const _LoadingRow({required this.text});

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
