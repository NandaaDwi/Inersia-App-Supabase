import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileMenuSection extends StatelessWidget {
  final int articleCount;
  const ProfileMenuSection({super.key, required this.articleCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Aktivitas',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _ProfileMenuItem(
          icon: Icons.article_outlined,
          color: const Color(0xFF2563EB),
          label: 'Artikel Saya',
          subtitle: articleCount > 0
              ? '$articleCount artikel (draft & published)'
              : 'Belum ada artikel',
          badge: articleCount > 0 ? '$articleCount' : null,
          onTap: () => context.push('/profile/drafts'),
        ),
        const SizedBox(height: 8),
        _ProfileMenuItem(
          icon: Icons.edit_outlined,
          color: const Color(0xFF7C3AED),
          label: 'Edit Profil',
          subtitle: 'Nama, username, bio, foto',
          onTap: () => context.push('/profile/edit'),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF374151),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
