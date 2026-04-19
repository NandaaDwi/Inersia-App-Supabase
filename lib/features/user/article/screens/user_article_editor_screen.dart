// lib/features/user/article/screens/user_article_editor_screen.dart
//
// Widget yang dipisah dalam file ini (kamu bisa cut ke file terpisah):
//   3. _EditorTagInput      →
//   4. _EditorDiscardDialog → editor_discard_dialog.dart
//   5. _SuggestTile         → editor_suggest_tile.dart
//   6. _LoadRow             → editor_load_row.dart
//   7. _SLabel (function)   → editor_label.dart
//
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/article/providers/user_article_provider.dart';
import 'package:inersia_supabase/features/admin/manageArticle/widgets/editor_rich_text.dart';
import 'package:inersia_supabase/features/user/article/widgets/editor_category_input.dart';
import 'package:inersia_supabase/features/user/article/widgets/editor_discard_dialog.dart';
import 'package:inersia_supabase/features/user/article/widgets/editor_tag_input.dart';
import 'package:inersia_supabase/features/user/article/widgets/editor_thumbnail_picker.dart';
import 'package:inersia_supabase/features/user/article/widgets/s_label.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';
import 'package:inersia_supabase/utils/moderation_client.dart';

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
    useEffect(
      () => () {
        editorFocusNode.dispose();
        editorScrollCtrl.dispose();
      },
      const [],
    );

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
    useListenable(quillCtrl);
    useEffect(() => quillCtrl.dispose, const []);

    // Tandai ada perubahan
    useEffect(() {
      void onChange() => hasChanges.value = true;
      quillCtrl.addListener(onChange);
      titleCtrl.addListener(onChange);
      return () {
        quillCtrl.removeListener(onChange);
        titleCtrl.removeListener(onChange);
      };
    }, const []);

    // Load nama kategori saat edit
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

    // ── Konfirmasi keluar ───────────────────────────────────
    Future<bool> confirmDiscard() async {
      if (!hasChanges.value) return true;
      final r = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EditorDiscardDialog(),
      );
      return r ?? false;
    }

    // ── Simpan artikel ──────────────────────────────────────
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

      if (status == 'published') {
        isChecking.value = true;
        final result = await ModerationClient.moderateArticle('$title $plain');
        isChecking.value = false;
        if (!result.allowed) {
          if (context.mounted) _snackError(context, result.reason!);
          return;
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
        bottomSheet: QuillKeyboardToolbar(controller: quillCtrl),
        appBar: _EditorAppBar(
          isEdit: article != null,
          isProcessing: isProcessing,
          isChecking: isChecking.value,
          onBack: () async {
            final canLeave = await confirmDiscard();
            if (canLeave && context.mounted) Navigator.of(context).pop();
          },
          onDraft: () => handleSave('draft'),
          onPublish: () => handleSave('published'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ─────────────────────────────────
              EditorThumbPicker(
                thumbnail: thumbnail,
                article: article,
                onChanged: () => hasChanges.value = true,
              ),
              const SizedBox(height: 24),

              // ── Judul ─────────────────────────────────────
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
              const Divider(color: Color(0xFF161616), height: 1),
              const SizedBox(height: 20),

              // ── Kategori ──────────────────────────────────
              SLabel(label: 'KATEGORI'),
              const SizedBox(height: 8),
              EditorCategoryInput(
                categoryCtrl: categoryCtrl,
                selectedCategoryId: selectedCategoryId,
                isLoading: isCategoryLoading.value,
                onChanged: () => hasChanges.value = true,
                ref: ref,
              ),
              const SizedBox(height: 20),

              // ── Tag ───────────────────────────────────────
              Row(
                children: [
                  SLabel(label: 'TAG'),
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
              EditorTagInput(
                selectedTags: selectedTags,
                onChanged: () => hasChanges.value = true,
                ref: ref,
                context: context,
              ),
              const SizedBox(height: 24),

              // ── Editor konten ─────────────────────────────
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
}

// ═══════════════════════════════════════════════════════════════
// WIDGET TERPISAH — bisa di-cut ke file masing-masing
// ═══════════════════════════════════════════════════════════════

// ─── 1. AppBar ────────────────────────────────────────────────
// → Bisa jadi: editor_app_bar.dart

class _EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEdit;
  final bool isProcessing;
  final bool isChecking;
  final VoidCallback onBack;
  final VoidCallback onDraft;
  final VoidCallback onPublish;
  const _EditorAppBar({
    required this.isEdit,
    required this.isProcessing,
    required this.isChecking,
    required this.onBack,
    required this.onDraft,
    required this.onPublish,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: const Color(0xFF0D0D0D),
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
      onPressed: onBack,
    ),
    title: Text(
      isEdit ? 'Edit Artikel' : 'Tulis Artikel',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
    ),
    actions: [
      if (!isProcessing) ...[
        TextButton(
          onPressed: onDraft,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF9CA3AF)),
          child: const Text(
            'Draft',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: onPublish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              if (isChecking)
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
  );
}

// ─── 2. Thumb Picker ──────────────────────────────────────────
// → Bisa jadi: editor_thumb_picker.dart

// ─── 3. Category Input ────────────────────────────────────────
// → Bisa jadi: editor_category_input.dart

// ─── 4. Tag Input ─────────────────────────────────────────────
// → Bisa jadi: editor_tag_input.dart

// ─── 5. Discard Dialog ────────────────────────────────────────
// → Bisa jadi: editor_discard_dialog.dart

// ─── 6. Suggest Tile ──────────────────────────────────────────
// → Bisa jadi: editor_suggest_tile.dart

// ─── 7. Load Row ──────────────────────────────────────────────
// → Bisa jadi: editor_load_row.dart

// ─── Shared helpers ───────────────────────────────────────────

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
