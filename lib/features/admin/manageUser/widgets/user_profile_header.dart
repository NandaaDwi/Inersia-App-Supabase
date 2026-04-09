import 'package:flutter/material.dart';
import 'package:inersia_supabase/models/user_model.dart';
import 'user_stat_item.dart';

class UserProfileHeader extends StatelessWidget {
  final UserModel user;

  const UserProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "@${user.username}",
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserStatItem(count: user.followersCount, label: "Pengikut"),
              Container(
                width: 1,
                height: 30,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              UserStatItem(count: user.followingCount, label: "Mengikuti"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E1E1E),
        border: Border.all(
          color: const Color(0xFF3F7AF6).withOpacity(0.5),
          width: 3,
        ),
        image: user.photoUrl != null
            ? DecorationImage(
                image: NetworkImage(user.photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.photoUrl == null
          ? Center(
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
