import 'package:equatable/equatable.dart';

class ReportModel extends Equatable {
  final String id;
  final String reporterId;
  final String targetId;
  final String targetType; 
  final String reasonCategory;
  final String? description;
  final Map<String, dynamic>? contentSnapshot; 
  final String status; 
  final String? adminId;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reasonCategory,
    this.description,
    this.contentSnapshot,
    required this.status,
    this.adminId,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      reporterId: json['reporter_id'],
      targetId: json['target_id'],
      targetType: json['target_type'] ?? 'article',
      reasonCategory: json['reason_category'] ?? '',
      description: json['description'],
      contentSnapshot: json['content_snapshot'] as Map<String, dynamic>?,
      status: json['status'] ?? 'pending',
      adminId: json['admin_id'],
      adminNote: json['admin_note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'target_id': targetId,
      'target_type': targetType,
      'reason_category': reasonCategory,
      'description': description,
      'content_snapshot': contentSnapshot,
      'status': status,
      'admin_id': adminId,
      'admin_note': adminNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReportModel copyWith({
    String? status,
    String? adminId,
    String? adminNote,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id,
      reporterId: reporterId,
      targetId: targetId,
      targetType: targetType,
      reasonCategory: reasonCategory,
      description: description,
      contentSnapshot: contentSnapshot,
      status: status ?? this.status,
      adminId: adminId ?? this.adminId,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    reporterId,
    targetId,
    targetType,
    status,
    adminId,
    createdAt,
    updatedAt,
  ];
}
