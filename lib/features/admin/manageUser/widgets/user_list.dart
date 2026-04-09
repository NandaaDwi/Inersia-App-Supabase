import 'package:flutter/material.dart';
import 'package:inersia_supabase/models/user_model.dart';
import 'user_card.dart';

class UserList extends StatelessWidget {
  final List<UserModel> users;

  const UserList({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return UserCard(user: users[index]);
      },
    );
  }
}
