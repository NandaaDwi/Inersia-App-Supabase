import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageUser/providers/admin_user_provider.dart';

class AdminUserPagination extends ConsumerWidget {
  final int currentPage;
  const AdminUserPagination({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1F2937), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 0,
            onTap: () =>
                ref.read(userPageProvider.notifier).state = currentPage - 1,
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Hal. ${currentPage + 1}',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: true,
            onTap: () =>
                ref.read(userPageProvider.notifier).state = currentPage + 1,
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF161616) : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFF1F2937) : const Color(0xFF111827),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
        ),
      ),
    );
  }
}
