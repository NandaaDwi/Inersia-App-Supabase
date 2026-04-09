import 'package:inersia_supabase/config/supabase_config.dart';

class DashboardStats {
  final int totalUsers;
  final int totalArticles;
  final int totalComments;
  final int totalTags;
  final int pendingReports;
  final List<WeeklyPoint> weeklyArticles;

  const DashboardStats({
    required this.totalUsers,
    required this.totalArticles,
    required this.totalComments,
    required this.totalTags,
    required this.pendingReports,
    required this.weeklyArticles,
  });
}

class WeeklyPoint {
  final String label;
  final DateTime weekStart;
  final int count;
  const WeeklyPoint({
    required this.label,
    required this.weekStart,
    required this.count,
  });
}

class AdminDashboardService {
  final _client = supabaseConfig.client;

  Future<DashboardStats> getStats() async {
    final results = await Future.wait([
      _count('users'),
      _count('articles'),
      _count('comments'),
      _count('tags'),
      _countWhere('reports', 'status', 'pending'),
      _getWeeklyArticles(),
    ]);

    return DashboardStats(
      totalUsers: results[0] as int,
      totalArticles: results[1] as int,
      totalComments: results[2] as int,
      totalTags: results[3] as int,
      pendingReports: results[4] as int,
      weeklyArticles: results[5] as List<WeeklyPoint>,
    );
  }

  Future<int> _count(String table) async {
    final res = await _client.from(table).select('id').count();
    return res.count;
  }

  Future<int> _countWhere(String table, String col, String val) async {
    final res = await _client.from(table).select('id').eq(col, val).count();
    return res.count;
  }

  Future<List<WeeklyPoint>> _getWeeklyArticles() async {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final startOfThisWeek = DateTime(
      thisMonday.year,
      thisMonday.month,
      thisMonday.day,
    );

    final cutoff = startOfThisWeek.subtract(const Duration(days: 42));
    final res = await _client
        .from('articles')
        .select('created_at')
        .gte('created_at', cutoff.toIso8601String())
        .lte('created_at', now.toIso8601String());

    final Map<int, int> countByWeekIndex = {};
    for (final row in res as List) {
      final dt = DateTime.parse(row['created_at'] as String).toLocal();
      final daysDiff = dt.difference(startOfThisWeek).inDays;
      final monday = dt.subtract(Duration(days: dt.weekday - 1));
      final mondayNormalized = DateTime(monday.year, monday.month, monday.day);
      final weekOffset =
          mondayNormalized.difference(startOfThisWeek).inDays ~/ 7;
      countByWeekIndex[weekOffset] = (countByWeekIndex[weekOffset] ?? 0) + 1;
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return List.generate(7, (i) {
      final offset = i - 6; // -6, -5, ..., 0
      final weekStart = startOfThisWeek.add(Duration(days: offset * 7));
      final label = '${weekStart.day} ${months[weekStart.month - 1]}';
      return WeeklyPoint(
        label: label,
        weekStart: weekStart,
        count: countByWeekIndex[offset] ?? 0,
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
}
