/// Vocabulary entity - word identity
class VocabularyModel {
  const VocabularyModel({
    required this.id,
    required this.userId,
    required this.word,
    this.stem,
    this.globalDictionaryId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      word: json['word'] as String,
      stem: json['stem'] as String?,
      globalDictionaryId: json['global_dictionary_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  final String id;
  final String userId;
  final String word;
  final String? stem;
  final String? globalDictionaryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Whether this vocabulary item has been enriched (has global dictionary data)
  bool get isEnriched => globalDictionaryId != null;

  /// The display form of the word: stem (base/lemma) if available, otherwise raw word.
  String get displayWord => stem ?? word;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'word': word,
      'stem': stem,
      'global_dictionary_id': globalDictionaryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  VocabularyModel copyWith({
    String? id,
    String? userId,
    String? word,
    String? stem,
    String? globalDictionaryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return VocabularyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      stem: stem ?? this.stem,
      globalDictionaryId: globalDictionaryId ?? this.globalDictionaryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
