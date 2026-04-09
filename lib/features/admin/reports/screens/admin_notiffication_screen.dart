import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/admin/dashboard/providers/admin_dashboard_provider.dart';
import 'package:inersia_supabase/models/notification_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class AdminNotificationScreen extends ConsumerWidget {
  const AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(adminNotificationsStreamProvider);
    final adminId = supabaseConfig.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifikasi',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () {
              if (adminId.isNotEmpty) {
                ref
                    .read(adminDashboardServiceProvider)
                    .markAllNotificationsRead(adminId);
              }
            },
            child: const Text('Tandai Semua',
                style: TextStyle(
                    color: Color(0xFF60A5FA), fontSize: 13)),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) => notifs.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        color: Color(0xFF374151), size: 56),
                    SizedBox(height: 12),
                    Text('Belum ada notifikasi',
                        style: TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _NotifCard(
                  notif: notifs[i],
                  adminId: adminId,
                ),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3F7AF6)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Color(0xFF6B7280))),
        ),
      ),
    );
  }
}

class _NotifCard extends ConsumerWidget {
  final NotificationModel notif;
  final String adminId;

  const _NotifCard({required this.notif, required this.adminId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeInfo = _typeInfo(notif.type);

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          ref
              .read(adminDashboardServiceProvider)
              .markNotificationRead(notif.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead
              ? const Color(0xFF111827)
              : const Color(0xFF1E3A5F).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead
                ? const Color(0xFF1F2937)
                : const Color(0xFF2563EB).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeInfo.$2.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(typeInfo.$1, color: typeInfo.$2, size: 20),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          typeInfo.$3,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3F7AF6),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppDateUtils.timeAgo(notif.createdAt),
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // (icon, color, label)
  (IconData, Color, String) _typeInfo(String type) {
    return switch (type) {
      'report_new' => (
          Icons.report_problem_outlined,
          const Color(0xFFEF4444),
          'Laporan baru masuk dari pengguna'
        ),
      'warning' => (
          Icons.warning_amber_rounded,
          const Color(0xFFD97706),
          'Peringatan dikirim ke pengguna'
        ),
      'follow' => (
          Icons.person_add_outlined,
          const Color(0xFF3F7AF6),
          'Pengguna baru mengikuti'
        ),
      'like' => (
          Icons.favorite_outline,
          const Color(0xFFEF4444),
          'Artikel disukai'
        ),
      'comment' => (
          Icons.chat_bubble_outline_rounded,
          const Color(0xFF7C3AED),
          'Komentar baru pada artikel'
        ),
      _ => (
          Icons.notifications_none_rounded,
          const Color(0xFF6B7280),
          'Notifikasi baru'
        ),
    };
  }
}