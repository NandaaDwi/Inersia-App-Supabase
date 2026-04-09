import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String receiverId;
  final String senderId;
  final String type;
  final String? articleId;
  final bool isRead;
  final String message;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.type,
    this.articleId,
    required this.isRead,
    required this.message,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      receiverId: json['receiver_id'],
      senderId: json['sender_id'],
      type: json['type'],
      articleId: json['article_id'],
      isRead: json['is_read'] ?? false,
      message: json['message'] ?? [''],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiver_id': receiverId,
      'sender_id': senderId,
      'type': type,
      'article_id': articleId,
      'is_read': isRead,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [id];
}
