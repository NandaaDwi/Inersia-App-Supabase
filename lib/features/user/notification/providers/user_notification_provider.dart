import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/notification/services/user_notification_service.dart';
import 'package:inersia_supabase/models/notification_model.dart';

final userNotificationServiceProvider = Provider(
  (ref) => UserNotificationService(),
);

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final uid = supabaseConfig.client.auth.currentUser?.id;
      if (uid == null) return const Stream.empty();

      return supabaseConfig.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('receiver_id', uid)
          .order('created_at', ascending: false)
          .map(
            (rows) => rows.map((r) => NotificationModel.fromJson(r)).toList(),
          );
    });

final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);

  return notificationsAsync.when(
    data: (notifications) =>
        Stream.value(notifications.where((n) => !n.isRead).length),
    error: (err, stack) => Stream.error(err, stack),
    loading: () => const Stream.empty(),
  );
});
