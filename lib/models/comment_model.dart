import 'package:equatable/equatable.dart';

class CommentModel extends Equatable {
  final String id;
  final String articleId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String? parentId;
  final String commentText;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    this.parentId,
    required this.commentText,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return CommentModel(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      userId: json['user_id'] as String,
      userName: user?['name'] as String? ?? 'Anonim',
      userPhoto: user?['photo_url'] as String?,
      parentId: json['parent_id'] as String?,
      commentText: json['comment_text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory CommentModel.fromJsonStream(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      userId: json['user_id'] as String,
      userName: 'Pengguna',
      userPhoto: null,
      parentId: json['parent_id'] as String?,
      commentText: json['comment_text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  CommentModel copyWith({String? userName, String? userPhoto}) {
    return CommentModel(
      id: id,
      articleId: articleId,
      userId: userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      parentId: parentId,
      commentText: commentText,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, commentText, createdAt];
}
