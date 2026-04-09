import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/notification/providers/user_notification_provider.dart';
import 'package:inersia_supabase/models/notification_model.dart';
import 'package:inersia_supabase/utils/dateUtills.dart';

class UserNotificationScreen extends ConsumerWidget {
  const UserNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final service = ref.read(userNotificationServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => service.markAllNotificationsRead(),
                child: const Text(
                  'Tandai Semua Dibaca',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 12),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF1F2937)),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
        error: (e, _) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: Color(0xFF374151),
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Gagal memuat notifikasi',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF374151),
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
                    'Notifikasi akan muncul saat ada yang\nmenyukai, mengikuti, atau berkomentar',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Color(0xFF1F2937), height: 1),
            itemBuilder: (context, i) {
              final notif = notifications[i];
              return _NotificationItem(
                notification: notif,
                onTap: () async {
                  if (!notif.isRead) {
                    await service.markNotificationRead(notif.id);
                  }
                  if (notif.articleId != null && context.mounted) {
                    try {
                      final articleRes = await service.fetchArticleDetails(
                        notif.articleId!,
                      );
                      if (context.mounted) {
                        context.push(
                          '/article/${notif.articleId}',
                          extra: articleRes,
                        );
                      }
                    } catch (_) {}
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = _iconData(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : const Color(0xFF1E3A5F).withOpacity(0.15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: notification.isRead
                          ? const Color(0xFFD1D5DB)
                          : Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.timeAgo(notification.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconData(String type) {
    return switch (type) {
      'like' => (
        Icons.favorite_rounded,
        const Color(0xFFEF4444),
        const Color(0xFFEF4444).withOpacity(0.15),
      ),
      'comment' => (
        Icons.chat_bubble_rounded,
        const Color(0xFF2563EB),
        const Color(0xFF2563EB).withOpacity(0.15),
      ),
      'follow' => (
        Icons.person_add_rounded,
        const Color(0xFF059669),
        const Color(0xFF059669).withOpacity(0.15),
      ),
      _ => (
        Icons.notifications_rounded,
        const Color(0xFF6B7280),
        const Color(0xFF1F2937),
      ),
    };
  }
}
