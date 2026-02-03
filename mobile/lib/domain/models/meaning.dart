import 'dart:convert';

/// Meaning entity - distinct sense for a vocabulary word
class MeaningModel {
  const MeaningModel({
    required this.id,
    required this.userId,
    required this.vocabularyId,
    required this.languageCode,
    required this.primaryTranslation,
    required this.englishDefinition,
    this.alternativeTranslations = const [],
    this.extendedDefinition,
    this.partOfSpeech,
    this.synonyms = const [],
    this.confidence = 1.0,
    this.isPrimary = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.source = 'ai',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory MeaningModel.fromJson(Map<String, dynamic> json) {
    return MeaningModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vocabularyId: json['vocabulary_id'] as String,
      languageCode: json['language_code'] as String,
      primaryTranslation: json['primary_translation'] as String,
      englishDefinition: json['english_definition'] as String,
      alternativeTranslations: _parseJsonList(json['alternative_translations']),
      extendedDefinition: json['extended_definition'] as String?,
      partOfSpeech: json['part_of_speech'] as String?,
      synonyms: _parseJsonList(json['synonyms']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      isPrimary: json['is_primary'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      source: json['source'] as String? ?? 'ai',
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
  final String languageCode;
  final String primaryTranslation;
  final String englishDefinition;
  final List<String> alternativeTranslations;
  final String? extendedDefinition;
  final String? partOfSpeech;
  final List<String> synonyms;
  final double confidence;
  final bool isPrimary;
  final bool isActive;
  final int sortOrder;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  static List<String> _parseJsonList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) {
      if (value.isEmpty || value == '[]') return [];
      try {
        final parsed = jsonDecode(value);
        if (parsed is List) return parsed.cast<String>();
      } catch (_) {}
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vocabulary_id': vocabularyId,
      'language_code': languageCode,
      'primary_translation': primaryTranslation,
      'english_definition': englishDefinition,
      'alternative_translations': alternativeTranslations,
      'extended_definition': extendedDefinition,
      'part_of_speech': partOfSpeech,
      'synonyms': synonyms,
      'confidence': confidence,
      'is_primary': isPrimary,
      'is_active': isActive,
      'sort_order': sortOrder,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  MeaningModel copyWith({
    String? id,
    String? userId,
    String? vocabularyId,
    String? languageCode,
    String? primaryTranslation,
    String? englishDefinition,
    List<String>? alternativeTranslations,
    String? extendedDefinition,
    String? partOfSpeech,
    List<String>? synonyms,
    double? confidence,
    bool? isPrimary,
    bool? isActive,
    int? sortOrder,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MeaningModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      languageCode: languageCode ?? this.languageCode,
      primaryTranslation: primaryTranslation ?? this.primaryTranslation,
      englishDefinition: englishDefinition ?? this.englishDefinition,
      alternativeTranslations:
          alternativeTranslations ?? this.alternativeTranslations,
      extendedDefinition: extendedDefinition ?? this.extendedDefinition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      synonyms: synonyms ?? this.synonyms,
      confidence: confidence ?? this.confidence,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
