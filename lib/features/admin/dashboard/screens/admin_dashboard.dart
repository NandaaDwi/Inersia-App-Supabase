import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/dashboard/providers/admin_dashboard_provider.dart';
import 'package:inersia_supabase/features/admin/dashboard/widgets/admin_app_bar.dart';
import 'package:inersia_supabase/features/admin/dashboard/widgets/quick_navlist.dart';
import 'package:inersia_supabase/features/admin/dashboard/widgets/stats_grid.dart';
import 'package:inersia_supabase/features/admin/dashboard/widgets/weekly_chart.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: const AdminAppBar(),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          color: const Color(0xFF3F7AF6),
          backgroundColor: const Color(0xFF1A1A2E),
          strokeWidth: 2.5,
          onRefresh: () async {
            return ref.refresh(dashboardStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const _SectionLabel('Statistik'),
                const SizedBox(height: 10),
                StatsGrid(stats: stats),
                const SizedBox(height: 24),
                const _SectionLabel('Artikel Dibuat (Per Minggu)'),
                const SizedBox(height: 10),
                WeeklyChart(points: stats.weeklyArticles),
                const SizedBox(height: 24),
                const _SectionLabel('Kelola'),
                const SizedBox(height: 10),
                const QuickNavList(),
                const SizedBox(height: 16),
                const LogoutButton(),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3F7AF6)),
        ),
        error: (e, _) =>
            _ErrorState(onRetry: () => ref.refresh(dashboardStatsProvider)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF6B7280), size: 48),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat data',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F7AF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
