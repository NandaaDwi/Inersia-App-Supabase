import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:inersia_supabase/features/admin/dashboard/services/admin_dashboard_service.dart';

class WeeklyChart extends StatelessWidget {
  final List<WeeklyPoint> points;
  const WeeklyChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return _EmptyState();

    final maxVal = points.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal < 3 ? 5 : maxVal + 2).toDouble();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFF1F2937), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: maxY / 4,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  int i = v.toInt();
                  if (i < 0 || i >= points.length || i % 2 != 0)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[i].label,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()),
                  )
                  .toList(),
              isCurved: true,
              color: const Color(0xFF3F7AF6),
              barWidth: 2,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3F7AF6).withOpacity(0.18),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Text(
          'Belum ada data',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
