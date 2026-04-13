import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/admin/manageArticle/providers/admin_article_provider.dart';
import 'package:inersia_supabase/features/admin/manageArticle/screens/admin_article_editor_screen.dart';
import 'package:inersia_supabase/features/admin/manageArticle/screens/admin_article_view_screen.dart';
import 'package:inersia_supabase/features/admin/manageArticle/widgets/admin_article_search_bar.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class AdminArticleManagementScreen extends ConsumerWidget {
  const AdminArticleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(adminArticlesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manajemen Artikel',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF1F2937)),
        ),
        actions: [
          // Tombol tambah artikel admin (bukan edit artikel user)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ArticleEditorScreen()),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Tulis',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const AdminArticleSearchBar(),
          // Filter status
          _StatusFilter(ref: ref),
          Expanded(
            child: articlesAsync.when(
              data: (list) => list.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _AdminArticleCard(article: list[i]),
                    ),
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Color(0xFF6B7280))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Filter ────────────────────────────────────────────

class _StatusFilter extends StatelessWidget {
  final WidgetRef ref;
  const _StatusFilter({required this.ref});

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(articleStatusFilterProvider);
    const options = [
      (null, 'Semua'),
      ('published', 'Published'),
      ('draft', 'Draft'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: options.map((opt) {
          final isSelected = current == opt.$1;
          return GestureDetector(
            onTap: () => ref.read(articleStatusFilterProvider.notifier).state =
                opt.$1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF161616),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF1F2937),
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Article Card Modern ──────────────────────────────────────

class _AdminArticleCard extends ConsumerWidget {
  final ArticleModel article;
  const _AdminArticleCard({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAdminId =
        supabaseConfig.client.auth.currentUser?.id ?? '';
    // Artikel milik admin sendiri → bisa edit
    // Artikel milik user lain → hanya bisa lihat, hapus, peringatkan, ban
    final isOwnArticle = article.authorId == currentAdminId;
    final isPublished = article.status == 'published';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail + info overlay ──────────────────────
          GestureDetector(
            onTap: () => _openArticle(context, isOwnArticle),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: article.thumbnail != null
                      ? Image.network(
                          article.thumbnail!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF78350F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPublished
                              ? Icons.public_rounded
                              : Icons.drafts_rounded,
                          size: 11,
                          color: isPublished
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPublished ? 'Published' : 'Draft',
                          style: TextStyle(
                            color: isPublished
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Admin badge jika artikel milik admin sendiri
                if (isOwnArticle)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 12, color: Color(0xFF60A5FA)),
                          SizedBox(width: 3),
                          Text('Admin',
                              style: TextStyle(
                                  color: Color(0xFF60A5FA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openArticle(context, isOwnArticle),
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Penulis
                    const Icon(Icons.person_outline,
                        size: 13, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      article.authorName,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    // Views
                    const Icon(Icons.remove_red_eye_outlined,
                        size: 13, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      '${article.viewCount}',
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      AppDateUtils.formatDate(article.createdAt),
                      style: const TextStyle(
                          color: Color(0xFF4B5563), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────
                Row(
                  children: [
                    if (isOwnArticle) ...[
                      // Edit (hanya artikel milik admin sendiri)
                      _ActionButton(
                        label: 'Edit',
                        icon: Icons.edit_rounded,
                        color: const Color(0xFF2563EB),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ArticleEditorScreen(article: article),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Lihat (artikel user)
                      _ActionButton(
                        label: 'Lihat',
                        icon: Icons.visibility_rounded,
                        color: const Color(0xFF374151),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AdminArticleViewScreen(article: article),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Peringatkan
                      _ActionButton(
                        label: 'Peringatkan',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFF78350F),
                        textColor: const Color(0xFFFBBF24),
                        onTap: () =>
                            _showWarnDialog(context, ref, article),
                      ),
                    ],
                    const Spacer(),
                    // Hapus (semua artikel)
                    _ActionButton(
                      label: 'Hapus',
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFF3F0F0F),
                      textColor: const Color(0xFFEF4444),
                      onTap: () =>
                          _showDeleteDialog(context, ref, article),
                    ),
                  ],
                ),

                // Ban user (khusus artikel user lain)
                if (!isOwnArticle) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showBanDialog(context, ref, article),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F0000),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF7F1D1D), width: 0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block_rounded,
                              size: 14, color: Color(0xFFEF4444)),
                          SizedBox(width: 6),
                          Text(
                            'Ban Pengguna',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openArticle(BuildContext context, bool isOwnArticle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isOwnArticle
            ? ArticleEditorScreen(article: article)
            : AdminArticleViewScreen(article: article),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, ArticleModel article) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Hapus Artikel?',
        message:
            'Artikel "${article.title}" akan dihapus permanen dan tidak dapat dikembalikan.',
        confirmLabel: 'Hapus',
        confirmColor: const Color(0xFFEF4444),
        icon: Icons.delete_forever_rounded,
        iconColor: const Color(0xFFEF4444),
        onConfirm: () async {
          try {
            await supabaseConfig.client
                .from('articles')
                .delete()
                .eq('id', article.id);
            ref.invalidate(adminArticlesProvider);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Gagal menghapus: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showWarnDialog(
      BuildContext context, WidgetRef ref, ArticleModel article) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _InputDialog(
        title: 'Peringatkan Pengguna',
        message:
            'Kirim peringatan kepada ${article.authorName} terkait artikel ini.',
        hintText: 'Tulis alasan peringatan...',
        controller: controller,
        confirmLabel: 'Kirim Peringatan',
        confirmColor: const Color(0xFFD97706),
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFBBF24),
        onConfirm: () async {
          final reason = controller.text.trim();
          if (reason.isEmpty) return;
          try {
            // Kirim notifikasi peringatan ke user
            await supabaseConfig.client.from('notifications').insert({
              'receiver_id': article.authorId,
              'sender_id':
                  supabaseConfig.client.auth.currentUser?.id,
              'type': 'warning',
              'article_id': article.id,
              'is_read': false,
              'message':
                  '⚠️ Peringatan Admin: Artikel "${article.title}" melanggar ketentuan. Alasan: $reason',
            });
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Peringatan berhasil dikirim.'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Gagal mengirim: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showBanDialog(
      BuildContext context, WidgetRef ref, ArticleModel article) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _InputDialog(
        title: 'Ban Pengguna',
        message:
            'Pengguna ${article.authorName} akan dinonaktifkan dan tidak dapat login.',
        hintText: 'Tulis alasan ban...',
        controller: controller,
        confirmLabel: 'Ban Pengguna',
        confirmColor: const Color(0xFFEF4444),
        icon: Icons.block_rounded,
        iconColor: const Color(0xFFEF4444),
        onConfirm: () async {
          final reason = controller.text.trim();
          if (reason.isEmpty) return;
          try {
            // Set status user menjadi 'banned'
            await supabaseConfig.client
                .from('users')
                .update({'status': 'banned'}).eq('id', article.authorId);

            // Kirim notifikasi ban
            await supabaseConfig.client.from('notifications').insert({
              'receiver_id': article.authorId,
              'sender_id':
                  supabaseConfig.client.auth.currentUser?.id,
              'type': 'ban',
              'is_read': false,
              'message':
                  '🚫 Akun kamu telah dinonaktifkan oleh Admin. Alasan: $reason',
            });

            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Pengguna berhasil di-ban.'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
              ref.invalidate(adminArticlesProvider);
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Gagal ban: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 140,
        width: double.infinity,
        color: const Color(0xFF111827),
        child: const Center(
          child: Icon(Icons.image_outlined,
              color: Color(0xFF374151), size: 36),
        ),
      );
}

// ─── Action Button ────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = textColor ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fgColor),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: fgColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm Dialog ───────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
    required this.iconColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161616),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9CA3AF),
                      side: const BorderSide(color: Color(0xFF1F2937)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input Dialog ─────────────────────────────────────────────

class _InputDialog extends StatelessWidget {
  final String title;
  final String message;
  final String hintText;
  final TextEditingController controller;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onConfirm;

  const _InputDialog({
    required this.title,
    required this.message,
    required this.hintText,
    required this.controller,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
    required this.iconColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161616),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(message,
                          style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                    color: Color(0xFF4B5563), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F2937)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F2937)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2563EB), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9CA3AF),
                      side: const BorderSide(color: Color(0xFF1F2937)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, color: Color(0xFF374151), size: 56),
          SizedBox(height: 12),
          Text('Belum ada artikel',
              style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}