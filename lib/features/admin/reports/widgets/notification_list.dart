import 'package:flutter/material.dart';
import 'package:inersia_supabase/models/notification_model.dart';
import 'notification_card.dart';

class NotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final String adminId;

  const NotificationList({
    super.key,
    required this.notifications,
    required this.adminId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          NotificationCard(notif: notifications[i], adminId: adminId),
    );
  }
}
