import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/admin/dashboard/services/admin_dashboard_service.dart';
import 'package:inersia_supabase/models/notification_model.dart';

final adminDashboardServiceProvider = Provider((_) => AdminDashboardService());

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) {
  return ref.read(adminDashboardServiceProvider).getStats();
});

final adminNotificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final adminId = supabaseConfig.client.auth.currentUser?.id;
      if (adminId == null) return const Stream.empty();

      return supabaseConfig.client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('receiver_id', adminId)
          .order('created_at', ascending: false)
          .limit(30)
          .map(
            (rows) => rows.map((r) => NotificationModel.fromJson(r)).toList(),
          );
    });

final unreadAdminNotifCountProvider = Provider.autoDispose<int>((ref) {
  final notifs = ref.watch(adminNotificationsStreamProvider).value;
  if (notifs == null) return 0;
  return notifs.where((n) => !n.isRead).length;
});
