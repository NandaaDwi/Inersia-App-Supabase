import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/admin_user_provider.dart';

class UserSearchField extends ConsumerWidget {
  final TextEditingController controller;

  const UserSearchField({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: controller,
        onChanged: (val) => ref.read(userSearchProvider.notifier).state = val,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Cari nama, username, atau email...",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF3F7AF6),
            size: 20,
          ),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
