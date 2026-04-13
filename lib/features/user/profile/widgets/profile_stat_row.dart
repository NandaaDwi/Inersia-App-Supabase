import 'package:flutter/material.dart';

class ProfileStatsRow extends StatelessWidget {
  final int publishedCount;
  final int draftCount;
  final int followersCount;
  final int followingCount;

  const ProfileStatsRow({
    super.key,
    required this.publishedCount,
    required this.draftCount,
    required this.followersCount,
    required this.followingCount,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: Row(
        children: [
          _StatItem(value: _fmt(publishedCount), label: 'Artikel'),
          _StatDivider(),
          _StatItem(value: _fmt(followersCount), label: 'Pengikut'),
          _StatDivider(),
          _StatItem(value: _fmt(followingCount), label: 'Mengikuti'),
          _StatDivider(),
          _StatItem(value: _fmt(draftCount), label: 'Draft'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: const Color(0xFF1F2937));
}
