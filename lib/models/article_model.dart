import 'package:equatable/equatable.dart';
import 'package:inersia_supabase/models/tag_model.dart';

class ArticleModel extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String title;
  final String content;
  final String? thumbnail;
  final String status;
  final String categoryId;
  final String? categoryName;
  final int estimatedReading;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final List<TagModel> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArticleModel({
    required this.id,
    required this.authorId,
    this.authorName = '',
    this.authorPhoto,
    required this.title,
    required this.content,
    this.thumbnail,
    required this.status,
    required this.categoryId,
    this.categoryName,
    required this.estimatedReading,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final author = json['users'] as Map<String, dynamic>?;
    final category = json['categories'] as Map<String, dynamic>?;

    List<TagModel> parsedTags = [];
    try {
      if (json['article_tags'] is List) {
        parsedTags = (json['article_tags'] as List)
            .map((e) {
              final tagData = e['tags'];
              return tagData != null ? TagModel.fromJson(tagData) : null;
            })
            .whereType<TagModel>()
            .toList();
      } else if (json['tags'] is List) {
        parsedTags = (json['tags'] as List)
            .map((e) => e is Map<String, dynamic> ? TagModel.fromJson(e) : null)
            .whereType<TagModel>()
            .toList();
      }
    } catch (e, stack) {
      print('Error parsing tags: $e');
      print(stack.toString());
    }

    return ArticleModel(
      id: json['id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      authorName: author?['name'] as String? ?? 'Anonim',
      authorPhoto: author?['photo_url'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      thumbnail: json['thumbnail'] as String?,
      status: json['status'] as String? ?? 'draft',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: category?['name'] as String?,
      estimatedReading: json['estimated_reading'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      tags: parsedTags,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'content': content,
      'thumbnail': thumbnail,
      'status': status,
      'category_id': categoryId,
      'estimated_reading': estimatedReading,
      'like_count': likeCount,
      'comment_count': commentCount,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, content, likeCount, commentCount];
}
