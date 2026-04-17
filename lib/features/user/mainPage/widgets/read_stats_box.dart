import 'package:flutter/material.dart';

class ReadStatsBox extends StatelessWidget {
  final int likeCount;
  final int viewCount;
  final int commentCount;
  const ReadStatsBox({
    super.key,
    required this.likeCount,
    required this.viewCount,
    required this.commentCount,
  });

  static String fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        _StatCell(value: fmt(likeCount), label: 'Suka'),
        Container(width: 1, height: 36, color: const Color(0xFF1F2937)),
        _StatCell(value: fmt(viewCount), label: 'Dilihat'),
        Container(width: 1, height: 36, color: const Color(0xFF1F2937)),
        _StatCell(value: fmt(commentCount), label: 'Komentar'),
      ],
    ),
  );
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
      ],
    ),
  );
}
