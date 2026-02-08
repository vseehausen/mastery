import '../../core/theme/color_tokens.dart';

/// Learning card entity - FSRS state for each vocabulary item
class LearningCardModel {
  const LearningCardModel({
    required this.id,
    required this.userId,
    required this.vocabularyId,
    required this.state,
    required this.due,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    this.lastReview,
    required this.isLeech,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
  });

  factory LearningCardModel.fromJson(Map<String, dynamic> json) {
    return LearningCardModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vocabularyId: json['vocabulary_id'] as String,
      state: json['state'] as int,
      due: DateTime.parse(json['due'] as String),
      stability: (json['stability'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      reps: json['reps'] as int,
      lapses: json['lapses'] as int,
      lastReview: json['last_review'] != null
          ? DateTime.parse(json['last_review'] as String)
          : null,
      isLeech: json['is_leech'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      version: json['version'] as int? ?? 1,
    );
  }

  final String id;
  final String userId;
  final String vocabularyId;
  final int state; // 0=new, 1=learning, 2=review, 3=relearning
  final DateTime due;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final DateTime? lastReview;
  final bool isLeech;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;

  /// Convert FSRS state to LearningStatus
  /// state: 0=new, 1=learning, 2=review, 3=relearning
  LearningStatus get status {
    if (state == 2) {
      // review state = known
      return LearningStatus.known;
    } else if (state == 1 || state == 3) {
      // learning or relearning = learning
      return LearningStatus.learning;
    } else {
      // new = unknown
      return LearningStatus.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vocabulary_id': vocabularyId,
      'state': state,
      'due': due.toIso8601String(),
      'stability': stability,
      'difficulty': difficulty,
      'reps': reps,
      'lapses': lapses,
      'last_review': lastReview?.toIso8601String(),
      'is_leech': isLeech,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'version': version,
    };
  }

  LearningCardModel copyWith({
    String? id,
    String? userId,
    String? vocabularyId,
    int? state,
    DateTime? due,
    double? stability,
    double? difficulty,
    int? reps,
    int? lapses,
    DateTime? lastReview,
    bool? isLeech,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? version,
  }) {
    return LearningCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      state: state ?? this.state,
      due: due ?? this.due,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReview: lastReview ?? this.lastReview,
      isLeech: isLeech ?? this.isLeech,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
    );
  }
}
