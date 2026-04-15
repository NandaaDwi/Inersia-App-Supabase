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
        automaticallyImplyLeading: false,
        title: const Text(
          'Manajemen Artikel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF1F2937)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArticleEditorScreen()),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 16),
              label: const Text(
                'Tulis',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const AdminArticleSearchBar(),
          Expanded(
            child: articlesAsync.when(
              data: (list) => list.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFF161616),
                      onRefresh: () =>
                          ref.read(adminArticlesProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ArticleCard(article: list[i]),
                      ),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFF374151),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat: $e',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(adminArticlesProvider.notifier).refresh(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ArticleCard extends ConsumerWidget {
  final ArticleModel article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminId = supabaseConfig.client.auth.currentUser?.id ?? '';
    final isOwnArticle = article.authorId == adminId;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openArticle(context, isOwnArticle),
            child: Stack(
              children: [
                article.thumbnail != null
                    ? Image.network(
                        article.thumbnail!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                      )
                    : _thumbPlaceholder(),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOwnArticle
                          ? const Color(0xFF1E3A5F)
                          : Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOwnArticle
                              ? Icons.verified_rounded
                              : Icons.person_outline_rounded,
                          size: 11,
                          color: isOwnArticle
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOwnArticle ? 'Admin' : 'User',
                          style: TextStyle(
                            color: isOwnArticle
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF9CA3AF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: const Color(0xFF1F2937),
                      backgroundImage: article.authorPhoto != null
                          ? NetworkImage(article.authorPhoto!)
                          : null,
                      child: article.authorPhoto == null
                          ? Text(
                              article.authorName.isNotEmpty
                                  ? article.authorName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        article.authorName,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 12,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${article.viewCount}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.formatDate(article.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (isOwnArticle)
                  Row(
                    children: [
                      Expanded(
                        child: _Btn(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          bg: const Color(0xFF1E3A5F),
                          fg: const Color(0xFF60A5FA),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArticleEditorScreen(article: article),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Btn(
                          label: 'Hapus',
                          icon: Icons.delete_outline_rounded,
                          bg: const Color(0xFF2A0000),
                          fg: const Color(0xFFEF4444),
                          onTap: () => _deleteDialog(context, ref),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Btn(
                              label: 'Lihat',
                              icon: Icons.visibility_rounded,
                              bg: const Color(0xFF1F2937),
                              fg: const Color(0xFF9CA3AF),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminArticleViewScreen(article: article),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Btn(
                              label: 'Peringatkan',
                              icon: Icons.warning_amber_rounded,
                              bg: const Color(0xFF2D1A00),
                              fg: const Color(0xFFFBBF24),
                              onTap: () => _warnDialog(context, ref),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Btn(
                              label: 'Hapus',
                              icon: Icons.delete_outline_rounded,
                              bg: const Color(0xFF2A0000),
                              fg: const Color(0xFFEF4444),
                              onTap: () => _deleteDialog(context, ref),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _Btn(
                        label: 'Ban Pengguna',
                        icon: Icons.block_rounded,
                        bg: const Color(0xFF1A0000),
                        fg: const Color(0xFFEF4444),
                        fullWidth: true,
                        onTap: () => _banDialog(context, ref),
                      ),
                    ],
                  ),
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

  void _deleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Hapus Artikel?',
        message:
            '"${article.title}" akan dihapus permanen beserta semua komentar dan data terkaitnya.',
        confirmLabel: 'Hapus',
        confirmColor: const Color(0xFFEF4444),
        icon: Icons.delete_forever_rounded,
        iconColor: const Color(0xFFEF4444),
        onConfirm: () async {
          final client = supabaseConfig.client;
          try {
            await Future.wait([
              client.from('article_tags').delete().eq('article_id', article.id),
              client.from('comments').delete().eq('article_id', article.id),
              client.from('likes').delete().eq('article_id', article.id),
              client.from('reading_list').delete().eq('article_id', article.id),
            ]);
            await client.from('articles').delete().eq('id', article.id);
            ref.invalidate(adminArticlesProvider);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) {
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Gagal menghapus: $e'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _warnDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _InputDialog(
        title: 'Kirim Peringatan',
        message: 'Kepada: ${article.authorName}',
        hintText: 'Alasan peringatan (opsional)...',
        controller: ctrl,
        confirmLabel: 'Kirim',
        confirmColor: const Color(0xFFD97706),
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFBBF24),
        onConfirm: () async {
          final reason = ctrl.text.trim();
          final msg = reason.isEmpty
              ? '⚠️ Peringatan Admin: Artikel "${article.title}" melanggar ketentuan komunitas.'
              : '⚠️ Peringatan Admin: Artikel "${article.title}" melanggar ketentuan. Alasan: $reason';
          try {
            await supabaseConfig.client.from('notifications').insert({
              'receiver_id': article.authorId,
              'sender_id': supabaseConfig.client.auth.currentUser?.id,
              'type': 'warning',
              'article_id': article.id,
              'is_read': false,
              'message': msg,
            });
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Peringatan berhasil dikirim.'),
                  backgroundColor: Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Gagal mengirim: $e'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _banDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _InputDialog(
        title: 'Ban Pengguna',
        message: '${article.authorName} tidak dapat login setelah di-ban.',
        hintText: 'Alasan ban (opsional)...',
        controller: ctrl,
        confirmLabel: 'Ban',
        confirmColor: const Color(0xFFEF4444),
        icon: Icons.block_rounded,
        iconColor: const Color(0xFFEF4444),
        onConfirm: () async {
          final reason = ctrl.text.trim();
          try {
            await supabaseConfig.client
                .from('users')
                .update({'status': 'banned'})
                .eq('id', article.authorId);

            final msg = reason.isEmpty
                ? '🚫 Akun kamu telah dinonaktifkan oleh Admin.'
                : '🚫 Akun kamu dinonaktifkan oleh Admin. Alasan: $reason';
            await supabaseConfig.client.from('notifications').insert({
              'receiver_id': article.authorId,
              'sender_id': supabaseConfig.client.auth.currentUser?.id,
              'type': 'ban',
              'is_read': false,
              'message': msg,
            });

            ref.invalidate(adminArticlesProvider);
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Pengguna berhasil di-ban.'),
                  backgroundColor: Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Gagal ban: $e'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    height: 150,
    width: double.infinity,
    color: const Color(0xFF1F2937),
    child: const Center(
      child: Icon(Icons.article_outlined, color: Color(0xFF374151), size: 40),
    ),
  );
}


class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool fullWidth;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}


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
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF161616),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

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
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF161616),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
              ),
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
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9CA3AF),
                    side: const BorderSide(color: Color(0xFF1F2937)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.article_outlined, color: Color(0xFF374151), size: 56),
        SizedBox(height: 12),
        Text('Belum ada artikel', style: TextStyle(color: Color(0xFF6B7280))),
      ],
    ),
  );
}
