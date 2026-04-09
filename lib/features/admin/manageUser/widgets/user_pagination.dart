import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/admin_user_provider.dart';

class UserPagination extends ConsumerWidget {
  final int currentPage;

  const UserPagination({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 0
                ? () => ref.read(userPageProvider.notifier).state--
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            "Halaman ${currentPage + 1}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          _buildPageButton(
            icon: Icons.chevron_right,
            onPressed: () => ref.read(userPageProvider.notifier).state++,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.grey,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
