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

class UserArticleEditorScreen extends HookConsumerWidget {
  /// Null = buat baru, non-null = edit artikel yang sudah ada
  final ArticleModel? article;

  const UserArticleEditorScreen({super.key, this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(
      text: article?.title ?? '',
    );
    final categoryController = useTextEditingController();
    final selectedCategoryId = useState<String?>(article?.categoryId);
    final selectedTags = useState<List<TagModel>>(
      const [],
    );
    final isCategoryLoading = useState(false);
    final isSaving = useState(false);
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
        } catch (_) {
          return quill.QuillController.basic();
        }
      }
      return quill.QuillController.basic();
    });

    useEffect(() => quillController.dispose, const []);

    useEffect(() {
      void onContentChange() => hasChanges.value = true;
      void onTitleChange() => hasChanges.value = true;

      quillController.addListener(onContentChange);
      titleController.addListener(onTitleChange);

      return () {
        quillController.removeListener(onContentChange);
        titleController.removeListener(onTitleChange);
      };
    }, const []);

    useEffect(() {
      if (article != null && article!.categoryId.isNotEmpty) {
        isCategoryLoading.value = true;
        ref
            .read(userArticleServiceProvider)
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          content: const Text(
            'Artikel yang belum disimpan akan hilang. Yakin ingin keluar?',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9CA3AF),
              ),
              child: const Text(
                'Lanjut Edit',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    Future<void> handleSave(String status) async {
      if (titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judul artikel tidak boleh kosong!')),
        );
        return;
      }
      if (selectedCategoryId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
        );
        return;
      }

      final plainText = quillController.document.toPlainText().trim();
      if (plainText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Isi konten artikel tidak boleh kosong!'),
          ),
        );
        return;
      }

      final contentRaw = jsonEncode(
        quillController.document.toDelta().toJson(),
      );

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
              title: titleController.text.trim(),
              content: contentRaw,
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
            ),
          );
          Navigator.pop(
            context,
            true,
          ); 
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        isSaving.value = false;
      }
    }

    return PopScope(
      // canPop: false mencegat tombol back Android & gesture swipe iOS
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await confirmDiscard();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
            onPressed: () async {
              final canLeave = await confirmDiscard();
              if (canLeave && context.mounted) Navigator.of(context).pop();
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
            if (!isSaving.value) ...[
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
              // ─── Thumbnail picker ──────────────────────────
              GestureDetector(
                onTap: () async {
                  final xfile = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (xfile != null) {
                    thumbnail.value = File(xfile.path);
                    hasChanges.value = true;
                  }
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
                          child: Image.file(
                            thumbnail.value!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (article?.thumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  article!.thumbnail!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _thumbnailEmpty(),
                                ),
                              )
                            : _thumbnailEmpty()),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Judul ────────────────────────────────────
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

              // ─── Kategori ─────────────────────────────────
              const _SectionLabel(label: 'KATEGORI'),
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
                            'Memuat kategori...',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    )
                  : TypeAheadField<CategoryModel>(
                      controller: categoryController,
                      builder: (context, ctrl, focusNode) => TextField(
                        controller: ctrl,
                        focusNode: focusNode,
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

              // ─── Tag ──────────────────────────────────────
              const _SectionLabel(label: 'TAG'),
              const SizedBox(height: 8),
              TypeAheadField<String>(
                builder: (context, ctrl, focusNode) => TextField(
                  controller: ctrl,
                  focusNode: focusNode,
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
                      .read(userArticleServiceProvider)
                      .getOrCreateTag(tagName.trim());

                  if (!selectedTags.value.any((e) => e.id == tag.id)) {
                    selectedTags.value = [...selectedTags.value, tag];
                    hasChanges.value = true;
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

              // ─── Konten (toolbar sticky + editor auto-expand) ──
              const _SectionLabel(label: 'KONTEN'),
              const SizedBox(height: 8),

              // Toolbar
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

              // Editor — TIDAK fixed height, mengikuti isi konten
              Container(
                constraints: const BoxConstraints(
                  minHeight: 240, // minimal nyaman untuk mulai menulis
                  // tidak ada maxHeight → tumbuh sesuai konten
                ),
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
                    // scrollController: TIDAK diberikan → editor tidak scroll sendiri
                    // sehingga ia akan expand dan parent SingleChildScrollView yang scroll
                    scrollController: editorScrollController,
                    focusNode: editorFocusNode,
                    config: quill.QuillEditorConfig(
                      // scrollable: false agar editor tidak scroll sendiri
                      // dan menyerahkan scroll ke parent SingleChildScrollView
                      scrollable: false,
                      // expands: true membuat editor mengisi container parent
                      expands: false,
                      autoFocus: false,
                      placeholder: 'Mulai menulis konten artikel...',
                      padding: EdgeInsets.zero,
                      customStyles: quill.DefaultStyles(
                        paragraph: quill.DefaultTextBlockStyle(
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.7,
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
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
          'Pilih Thumbnail',
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}
