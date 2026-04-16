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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
      itemBuilder: (_, i) =>
          NotificationCard(notif: notifications[i], adminId: adminId),
    );
  }
}
