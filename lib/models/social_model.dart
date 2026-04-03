import 'package:equatable/equatable.dart';

class SocialModel extends Equatable {
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  const SocialModel({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory SocialModel.fromJson(Map<String, dynamic> json) {
    return SocialModel(
      followerId: json['follower_id'],
      followingId: json['following_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [followerId, followingId];
}
