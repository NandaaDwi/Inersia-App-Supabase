import 'package:inersia_supabase/config/supabase_config.dart';

class DashboardStats {
  final int totalUsers;
  final int totalArticles;
  final int totalComments;
  final int totalTags;
  final int pendingReports;
  final List<DailyPoint> dailyArticles;

  const DashboardStats({
    required this.totalUsers,
    required this.totalArticles,
    required this.totalComments,
    required this.totalTags,
    required this.pendingReports,
    required this.dailyArticles,
  });
}

class DailyPoint {
  final String label;

  final DateTime date;

  final int count;

  final bool isToday;

  const DailyPoint({
    required this.label,
    required this.date,
    required this.count,
    required this.isToday,
  });
}

typedef WeeklyPoint = DailyPoint;

class AdminDashboardService {
  final _client = supabaseConfig.client;

  Future<DashboardStats> getStats() async {
    final results = await Future.wait([
      _count('users'),
      _count('articles'),
      _count('comments'),
      _count('tags'),
      _countWhere('reports', 'status', 'pending'),
      getDailyArticles(),
    ]);

    return DashboardStats(
      totalUsers: results[0] as int,
      totalArticles: results[1] as int,
      totalComments: results[2] as int,
      totalTags: results[3] as int,
      pendingReports: results[4] as int,
      dailyArticles: results[5] as List<DailyPoint>,
    );
  }

  Future<List<DailyPoint>> getDailyArticles() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 6));
    final until = today.add(const Duration(days: 1));

    final rows = await _client
        .from('articles')
        .select('created_at')
        .gte('created_at', from.toUtc().toIso8601String())
        .lt('created_at', until.toUtc().toIso8601String());

    final Map<String, int> countByDate = {};
    for (final row in rows as List) {
      final dt = DateTime.parse(row['created_at'] as String).toLocal();
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      countByDate[key] = (countByDate[key] ?? 0) + 1;
    }

    return List.generate(7, (i) {
      final date = from.add(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isToday = i == 6;

      return DailyPoint(
        label: _dayLabel(date, isToday: isToday),
        date: date,
        count: countByDate[key] ?? 0,
        isToday: isToday,
      );
    });
  }

  Future<void> markNotificationRead(String notifId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notifId);
  }

  Future<void> markAllNotificationsRead(String adminId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', adminId)
        .eq('is_read', false);
  }

  Future<int> _count(String table) async {
    final res = await _client.from(table).select('id').count();
    return res.count;
  }

  Future<int> _countWhere(String table, String col, String val) async {
    final res = await _client.from(table).select('id').eq(col, val).count();
    return res.count;
  }

  static String _dayLabel(DateTime date, {required bool isToday}) {
    if (isToday) return 'Hari ini';
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final name = dayNames[date.weekday - 1];
    return '$name ${date.day}';
  }
}
