import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inersia_supabase/features/user/article/providers/user_article_provider.dart';
import 'package:inersia_supabase/features/admin/manageArticle/widgets/editor_rich_text.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/category_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';
import 'package:inersia_supabase/utils/moderation_client.dart';
import 'package:inersia_supabase/utils/word_filter.dart';

const int _maxTags = 5;

class UserArticleEditorScreen extends HookConsumerWidget {
  final ArticleModel? article;
  const UserArticleEditorScreen({super.key, this.article});

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
    final hasChanges = useState(false);

    final editorFocusNode = useMemoized(() => FocusNode());
    final editorScrollCtrl = useMemoized(() => ScrollController());

    useEffect(() {
      return () {
        editorFocusNode.dispose();
        editorScrollCtrl.dispose();
      };
    }, const []);

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
      void onChange() => hasChanges.value = true;
      quillCtrl.addListener(onChange);
      titleCtrl.addListener(onChange);
      return () {
        quillCtrl.removeListener(onChange);
        titleCtrl.removeListener(onChange);
      };
    }, const []);

    useEffect(() {
      if (article != null && article!.categoryId.isNotEmpty) {
        isCategoryLoading.value = true;
        ref
            .read(userArticleServiceProvider)
            .getCategoryById(article!.categoryId)
            .then((cat) {
              if (cat != null) categoryCtrl.text = cat.name;
            })
            .catchError((_) => categoryCtrl.text = '')
            .whenComplete(() => isCategoryLoading.value = false);
      }
      return null;
    }, [article?.categoryId]);

    Future<bool> confirmDiscard() async {
      if (!hasChanges.value) return true;
      final r = await showDialog<bool>(
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
      return r ?? false;
    }

    Future<void> handleSave(String status) async {
      final title = titleCtrl.text.trim();
      final plain = quillCtrl.document.toPlainText().trim();

      if (title.isEmpty) {
        _snack(context, 'Judul artikel tidak boleh kosong!');
        return;
      }
      if (selectedCategoryId.value == null) {
        _snack(context, 'Pilih kategori terlebih dahulu!');
        return;
      }
      if (plain.isEmpty) {
        _snack(context, 'Isi konten artikel tidak boleh kosong!');
        return;
      }

      // Filter hanya saat Publish
      if (status == 'published') {
        final fullText = '$title $plain';

        // Layer 1 — lokal (substring match, instan)
        final bad = WordFilter.checkFirst(fullText);
        if (bad != null) {
          _snackError(
            context,
            'Artikel mengandung kata tidak pantas. Hapus sebelum dipublikasi.',
          );
          return;
        }

        // Layer 2 — OpenAI via Edge Function
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
              content: jsonEncode(quillCtrl.document.toDelta().toJson()),
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
                    : 'Draft disimpan.',
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) _snackError(context, 'Gagal menyimpan: $e');
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
        // Toolbar sticky di atas keyboard
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
          // 80px bawah = ruang toolbar sticky
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _ThumbPicker(
                thumbnail: thumbnail,
                article: article,
                onChanged: () => hasChanges.value = true,
              ),
              const SizedBox(height: 24),

              // Judul
              TextField(
                controller: titleCtrl,
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
              _SLabel('KATEGORI'),
              const SizedBox(height: 8),
              isCategoryLoading.value
                  ? const _LoadRow(text: 'Memuat kategori...')
                  : TypeAheadField<CategoryModel>(
                      controller: categoryCtrl,
                      builder: (_, ctrl, fn) => TextField(
                        controller: ctrl,
                        focusNode: fn,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('Pilih kategori...'),
                        onChanged: (_) => hasChanges.value = true,
                      ),
                      onSelected: (s) {
                        categoryCtrl.text = s.name;
                        selectedCategoryId.value = s.id;
                        hasChanges.value = true;
                      },
                      suggestionsCallback: (p) => ref
                          .read(userArticleServiceProvider)
                          .getCategories(query: p),
                      itemBuilder: (_, s) => _SuggestTile(text: s.name),
                    ),
              const SizedBox(height: 20),

              // Tag
              Row(
                children: [
                  _SLabel('TAG'),
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
              if (selectedTags.value.length < _maxTags)
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
                      _SuggestTile(text: s, isAction: s.startsWith('+ ')),
                  onSelected: (val) async {
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
                      Expanded(
                        child: Text(
                          'Maksimal 5 tag. Hapus tag untuk menambah.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
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

              // Editor konten — EditorRichText dari shared widget
              EditorRichText(
                controller: quillCtrl,
                scrollController: editorScrollCtrl,
                focusNode: editorFocusNode,
              ),
            ],
          ),
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
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

// ── Shared widgets ─────────────────────────────────────────────

class _ThumbPicker extends StatelessWidget {
  final ValueNotifier<File?> thumbnail;
  final ArticleModel? article;
  final VoidCallback onChanged;
  const _ThumbPicker({
    required this.thumbnail,
    this.article,
    required this.onChanged,
  });

  @override
  Widget build(_) => GestureDetector(
    onTap: () async {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x != null) {
        thumbnail.value = File(x.path);
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

Widget _SLabel(String label) => Text(
  label,
  style: const TextStyle(
    color: Color(0xFF9CA3AF),
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  ),
);

class _SuggestTile extends StatelessWidget {
  final String text;
  final bool isAction;
  const _SuggestTile({required this.text, this.isAction = false});
  @override
  Widget build(_) => Container(
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

class _LoadRow extends StatelessWidget {
  final String text;
  const _LoadRow({required this.text});
  @override
  Widget build(_) => Padding(
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
