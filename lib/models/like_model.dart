import 'package:equatable/equatable.dart';

class LikeModel extends Equatable {
  final String userId;
  final String articleId;
  final DateTime createdAt;

  const LikeModel({
    required this.userId,
    required this.articleId,
    required this.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      userId: json['user_id'],
      articleId: json['article_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'article_id': articleId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, articleId];
}