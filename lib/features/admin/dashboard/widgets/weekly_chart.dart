import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:inersia_supabase/features/admin/dashboard/services/admin_dashboard_service.dart';

class WeeklyChart extends StatelessWidget {
  final List<DailyPoint> points;
  const WeeklyChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const _EmptyChart();

    final maxVal = points.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal < 4 ? 5 : maxVal + 2).toDouble();
    final gridInterval = (maxY / 4).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeeklySummary(points: points),
        const SizedBox(height: 10),

        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
          ),
          child: LineChart(
            _buildChart(maxY, gridInterval),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChart(double maxY, double gridInterval) {
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return LineChartData(
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),

      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: gridInterval,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFF1F2937), strokeWidth: 0.8),
      ),

      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: gridInterval,
            getTitlesWidget: (v, _) {
              if (v == 0) return const SizedBox.shrink();
              return Text(
                v.toInt().toString(),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 28,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= points.length) {
                return const SizedBox.shrink();
              }
              final p = points[i];
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  p.label,
                  style: TextStyle(
                    color: p.isToday
                        ? const Color(0xFF3F7AF6)
                        : const Color(0xFF6B7280),
                    fontSize: p.isToday ? 9.5 : 9,
                    fontWeight: p.isToday ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),

      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1F2937),
          getTooltipItems: (spots) => spots.map((s) {
            final i = s.spotIndex;
            if (i < 0 || i >= points.length) return null;
            final p = points[i];
            return LineTooltipItem(
              '${p.count} artikel\n${p.label}',
              const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: const Color(0xFF3F7AF6),
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, i) {
              final isToday = i < points.length && points[i].isToday;
              return FlDotCirclePainter(
                radius: isToday ? 5 : 3,
                color: isToday
                    ? const Color(0xFF3F7AF6)
                    : const Color(0xFF3F7AF6).withOpacity(0.6),
                strokeWidth: isToday ? 2 : 1,
                strokeColor: isToday ? Colors.white : const Color(0xFF3F7AF6),
              );
            },
          ),
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
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  final List<DailyPoint> points;
  const _WeeklySummary({required this.points});

  @override
  Widget build(BuildContext context) {
    final total = points.fold(0, (s, p) => s + p.count);
    final todayCount = points.isNotEmpty ? points.last.count : 0;

    return Row(
      children: [
        _SummaryChip(
          label: '7 hari terakhir',
          value: '$total artikel',
          color: const Color(0xFF3F7AF6),
        ),
        const SizedBox(width: 8),
        _SummaryChip(
          label: 'Hari ini',
          value: '$todayCount artikel',
          color: todayCount > 0
              ? const Color(0xFF059669)
              : const Color(0xFF374151),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3), width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label  ',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) => Container(
    height: 160,
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
    ),
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, color: Color(0xFF374151), size: 36),
          SizedBox(height: 8),
          Text('Belum ada data', style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    ),
  );
}
