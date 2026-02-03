/// Encounter entity - a vocabulary word seen in a source, with context
class EncounterModel {
  const EncounterModel({
    required this.id,
    required this.userId,
    required this.vocabularyId,
    this.sourceId,
    this.context,
    this.locatorJson,
    this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory EncounterModel.fromJson(Map<String, dynamic> json) {
    return EncounterModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vocabularyId: json['vocabulary_id'] as String,
      sourceId: json['source_id'] as String?,
      context: json['context'] as String?,
      locatorJson: json['locator_json'] as String?,
      occurredAt: json['occurred_at'] != null
          ? DateTime.parse(json['occurred_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  final String id;
  final String userId;
  final String vocabularyId;
  final String? sourceId;
  final String? context;
  final String? locatorJson;
  final DateTime? occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vocabulary_id': vocabularyId,
      'source_id': sourceId,
      'context': context,
      'locator_json': locatorJson,
      'occurred_at': occurredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  EncounterModel copyWith({
    String? id,
    String? userId,
    String? vocabularyId,
    String? sourceId,
    String? context,
    String? locatorJson,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EncounterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      sourceId: sourceId ?? this.sourceId,
      context: context ?? this.context,
      locatorJson: locatorJson ?? this.locatorJson,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
