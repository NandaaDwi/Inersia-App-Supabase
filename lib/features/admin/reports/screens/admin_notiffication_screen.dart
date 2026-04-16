import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/admin/dashboard/providers/admin_dashboard_provider.dart';
import '../widgets/notification_list.dart';

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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          notifsAsync.when(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (!hasUnread || adminId.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => ref
                    .read(adminDashboardServiceProvider)
                    .markAllNotificationsRead(adminId),
                child: const Text(
                  'Tandai Semua',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: Colors.white.withOpacity(0.05)),
        ),
      ),
      body: notifsAsync.when(
        data: (notifs) => notifs.isEmpty
            ? const _EmptyNotifView()
            : NotificationList(notifications: notifs, adminId: adminId),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3F7AF6),
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifView extends StatelessWidget {
  const _EmptyNotifView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF1F2937),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kami akan mengabari Anda jika ada pembaruan.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
