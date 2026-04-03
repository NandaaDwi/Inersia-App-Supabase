import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? photoUrl;
  final String role;
  final String status;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.status,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      bio: json['bio'] ?? '',
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'photo_url': photoUrl,
      'role': role,
      'status': status,
      'bio': bio,
      'followers_count': followersCount,
      'following_count': followingCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? username,
    String? email,
    String? photoUrl,
    String? role,
    String? status,
    String? bio,
    int? followersCount,
    int? followingCount,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, username, email];
}
