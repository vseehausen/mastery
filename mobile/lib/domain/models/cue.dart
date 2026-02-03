import 'dart:convert';

/// Cue entity - pre-generated prompt triggers for learning sessions
class CueModel {
  const CueModel({
    required this.id,
    required this.userId,
    required this.meaningId,
    required this.cueType,
    required this.promptText,
    required this.answerText,
    this.hintText,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory CueModel.fromJson(Map<String, dynamic> json) {
    return CueModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      meaningId: json['meaning_id'] as String,
      cueType: json['cue_type'] as String,
      promptText: json['prompt_text'] as String,
      answerText: json['answer_text'] as String,
      hintText: json['hint_text'] as String?,
      metadata: _parseMetadata(json['metadata']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  final String id;
  final String userId;
  final String meaningId;
  final String cueType; // 'translation', 'definition', 'synonym', 'context_cloze', 'disambiguation'
  final String promptText;
  final String answerText;
  final String? hintText;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  static Map<String, dynamic> _parseMetadata(dynamic value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      if (value.isEmpty || value == '{}') return {};
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meaning_id': meaningId,
      'cue_type': cueType,
      'prompt_text': promptText,
      'answer_text': answerText,
      'hint_text': hintText,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  CueModel copyWith({
    String? id,
    String? userId,
    String? meaningId,
    String? cueType,
    String? promptText,
    String? answerText,
    String? hintText,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CueModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      meaningId: meaningId ?? this.meaningId,
      cueType: cueType ?? this.cueType,
      promptText: promptText ?? this.promptText,
      answerText: answerText ?? this.answerText,
      hintText: hintText ?? this.hintText,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
