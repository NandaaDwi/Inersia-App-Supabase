import 'package:equatable/equatable.dart';

class CommentLikeModel extends Equatable {
  final String userId;
  final String commentId;
  final DateTime createdAt;

  const CommentLikeModel({
    required this.userId,
    required this.commentId,
    required this.createdAt,
  });

  factory CommentLikeModel.fromJson(Map<String, dynamic> json) {
    return CommentLikeModel(
      userId: json['user_id'],
      commentId: json['comment_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'comment_id': commentId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, commentId];
}
