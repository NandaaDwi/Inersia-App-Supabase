import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/admin_report_provider.dart';

class ReportFilterBar extends ConsumerWidget {
  const ReportFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(reportStatusFilterProvider);
    final typeFilter = ref.watch(reportTypeFilterProvider);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildIconLabel(Icons.tune_rounded),
            _FilterChip(
              label: 'Semua',
              value: null,
              current: statusFilter,
              onChanged: (v) =>
                  ref.read(reportStatusFilterProvider.notifier).state = v,
            ),
            _FilterChip(
              label: 'Menunggu',
              value: 'pending',
              current: statusFilter,
              onChanged: (v) =>
                  ref.read(reportStatusFilterProvider.notifier).state = v,
              color: const Color(0xFFFBBF24),
            ),
            _FilterChip(
              label: 'Ditindak',
              value: 'resolved',
              current: statusFilter,
              onChanged: (v) =>
                  ref.read(reportStatusFilterProvider.notifier).state = v,
              color: const Color(0xFF34D399),
            ),
            _FilterChip(
              label: 'Ditolak',
              value: 'rejected',
              current: statusFilter,
              onChanged: (v) =>
                  ref.read(reportStatusFilterProvider.notifier).state = v,
              color: const Color(0xFFF87171),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: 1,
                height: 20,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            _buildIconLabel(Icons.layers_outlined),
            _FilterChip(
              label: 'Semua Konten',
              value: null,
              current: typeFilter,
              onChanged: (v) =>
                  ref.read(reportTypeFilterProvider.notifier).state = v,
            ),
            _FilterChip(
              label: 'Artikel',
              value: 'article',
              current: typeFilter,
              onChanged: (v) =>
                  ref.read(reportTypeFilterProvider.notifier).state = v,
            ),
            _FilterChip(
              label: 'Komentar',
              value: 'comment',
              current: typeFilter,
              onChanged: (v) =>
                  ref.read(reportTypeFilterProvider.notifier).state = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconLabel(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.2)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? current;
  final ValueChanged<String?> onChanged;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    final activeColor = color ?? const Color(0xFF3F7AF6);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? activeColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
