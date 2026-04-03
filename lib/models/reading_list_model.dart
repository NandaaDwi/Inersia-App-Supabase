import 'package:equatable/equatable.dart';

class ReadingListModel extends Equatable {
  final String id;
  final String userId;
  final String articleId;
  final DateTime savedAt;

  const ReadingListModel({
    required this.id,
    required this.userId,
    required this.articleId,
    required this.savedAt,
  });

  factory ReadingListModel.fromJson(Map<String, dynamic> json) {
    return ReadingListModel(
      id: json['id'],
      userId: json['user_id'],
      articleId: json['article_id'],
      savedAt: DateTime.parse(json['saved_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'article_id': articleId,
      'saved_at': savedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, articleId];
}
