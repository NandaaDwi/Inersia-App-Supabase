import 'package:equatable/equatable.dart';

class TagModel extends Equatable {
  final String id;
  final String name;
  final int articleCount;
  final DateTime createdAt;

  const TagModel({
    required this.id,
    required this.name,
    required this.articleCount,
    required this.createdAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'],
      name: json['name'] ?? '',
      articleCount: json['article_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'article_count': articleCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TagModel copyWith({String? name, int? articleCount}) {
    return TagModel(
      id: id,
      name: name ?? this.name,
      articleCount: articleCount ?? this.articleCount,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
