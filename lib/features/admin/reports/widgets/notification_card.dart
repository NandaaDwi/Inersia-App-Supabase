import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/dashboard/providers/admin_dashboard_provider.dart';
import 'package:inersia_supabase/models/notification_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationModel notif;
  final String adminId;

  const NotificationCard({
    super.key,
    required this.notif,
    required this.adminId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeInfo = _getTypeInfo(notif.type);

    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          ref
              .read(adminDashboardServiceProvider)
              .markNotificationRead(notif.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead
              ? const Color(0xFF111827)
              : const Color(0xFF1E3A5F).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFF3F7AF6).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeInfo.icon, color: typeInfo.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          typeInfo.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 4, left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3F7AF6),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppDateUtils.timeAgo(notif.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotifTypeData _getTypeInfo(String type) {
    return switch (type) {
      'report_new' => const _NotifTypeData(
        Icons.report_gmailerrorred_rounded,
        Color(0xFFEF4444),
        'Laporan baru perlu ditinjau',
      ),
      'warning' => const _NotifTypeData(
        Icons.warning_amber_rounded,
        Color(0xFFF59E0B),
        'Peringatan dikirim ke pengguna',
      ),
      'follow' => const _NotifTypeData(
        Icons.person_add_rounded,
        Color(0xFF3F7AF6),
        'Seseorang mengikuti profil Anda',
      ),
      'like' => const _NotifTypeData(
        Icons.favorite_rounded,
        Color(0xFFF43F5E),
        'Artikel Anda mendapatkan apresiasi',
      ),
      'comment' => const _NotifTypeData(
        Icons.mode_comment_rounded,
        Color(0xFF8B5CF6),
        'Komentar baru pada diskusi',
      ),
      _ => const _NotifTypeData(
        Icons.notifications_active_rounded,
        Color(0xFF6B7280),
        'Aktivitas sistem terbaru',
      ),
    };
  }
}

class _NotifTypeData {
  final IconData icon;
  final Color color;
  final String label;
  const _NotifTypeData(this.icon, this.color, this.label);
}
