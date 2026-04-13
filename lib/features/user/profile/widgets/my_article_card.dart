import 'package:flutter/material.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class MyArticleCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MyArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = article.title.trim().isEmpty ? 'Tanpa judul' : article.title;
    final hasTitle = article.title.trim().isNotEmpty;
    final isDraft = article.status == 'draft';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────
            _ArticleThumbnail(url: article.thumbnail),
            const SizedBox(width: 14),

            // ── Info ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + kategori
                  _BadgeRow(
                    isDraft: isDraft,
                    categoryName: article.categoryName,
                  ),
                  const SizedBox(height: 6),

                  // Judul
                  Text(
                    title,
                    style: TextStyle(
                      color: hasTitle ? Colors.white : const Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      fontStyle: hasTitle ? FontStyle.normal : FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Footer: waktu update + tombol hapus
                  _CardFooter(updatedAt: article.updatedAt, onDelete: onDelete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thumbnail ─────────────────────────────────────────────────

class _ArticleThumbnail extends StatelessWidget {
  final String? url;
  const _ArticleThumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url != null
          ? Image.network(
              url!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.article_outlined,
      color: Color(0xFF374151),
      size: 28,
    ),
  );
}

// ── Badge Row ─────────────────────────────────────────────────

class _BadgeRow extends StatelessWidget {
  final bool isDraft;
  final String? categoryName;

  const _BadgeRow({required this.isDraft, this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _StatusBadge(isDraft: isDraft),
        if (categoryName != null) _CategoryBadge(name: categoryName!),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isDraft;
  const _StatusBadge({required this.isDraft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDraft
            ? const Color(0xFFD97706).withOpacity(0.12)
            : const Color(0xFF059669).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDraft
              ? const Color(0xFFD97706).withOpacity(0.3)
              : const Color(0xFF059669).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDraft ? Icons.drafts_rounded : Icons.public_rounded,
            size: 9,
            color: isDraft ? const Color(0xFFFBBF24) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 3),
          Text(
            isDraft ? 'Draft' : 'Published',
            style: TextStyle(
              color: isDraft
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String name;
  const _CategoryBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Color(0xFF60A5FA),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Card Footer ───────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  final DateTime updatedAt;
  final VoidCallback onDelete;

  const _CardFooter({required this.updatedAt, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.edit_outlined, color: Color(0xFF4B5563), size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Diperbarui ${AppDateUtils.timeAgo(updatedAt)}',
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFEF4444),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}
