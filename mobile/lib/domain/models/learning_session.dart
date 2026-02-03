/// Learning session entity - tracks each time-boxed practice session
class LearningSessionModel {
  const LearningSessionModel({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.expiresAt,
    required this.plannedMinutes,
    this.elapsedSeconds = 0,
    this.bonusSeconds = 0,
    this.itemsPresented = 0,
    this.itemsCompleted = 0,
    this.newWordsPresented = 0,
    this.reviewsPresented = 0,
    this.accuracyRate,
    this.avgResponseTimeMs,
    this.outcome = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearningSessionModel.fromJson(Map<String, dynamic> json) {
    return LearningSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      plannedMinutes: json['planned_minutes'] as int,
      elapsedSeconds: json['elapsed_seconds'] as int? ?? 0,
      bonusSeconds: json['bonus_seconds'] as int? ?? 0,
      itemsPresented: json['items_presented'] as int? ?? 0,
      itemsCompleted: json['items_completed'] as int? ?? 0,
      newWordsPresented: json['new_words_presented'] as int? ?? 0,
      reviewsPresented: json['reviews_presented'] as int? ?? 0,
      accuracyRate: (json['accuracy_rate'] as num?)?.toDouble(),
      avgResponseTimeMs: json['avg_response_time_ms'] as int?,
      outcome: json['outcome'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final int plannedMinutes;
  final int elapsedSeconds;
  final int bonusSeconds;
  final int itemsPresented;
  final int itemsCompleted;
  final int newWordsPresented;
  final int reviewsPresented;
  final double? accuracyRate;
  final int? avgResponseTimeMs;
  final int outcome; // 0=in_progress, 1=complete, 2=partial, 3=expired
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'planned_minutes': plannedMinutes,
      'elapsed_seconds': elapsedSeconds,
      'bonus_seconds': bonusSeconds,
      'items_presented': itemsPresented,
      'items_completed': itemsCompleted,
      'new_words_presented': newWordsPresented,
      'reviews_presented': reviewsPresented,
      'accuracy_rate': accuracyRate,
      'avg_response_time_ms': avgResponseTimeMs,
      'outcome': outcome,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LearningSessionModel copyWith({
    String? id,
    String? userId,
    DateTime? startedAt,
    DateTime? expiresAt,
    int? plannedMinutes,
    int? elapsedSeconds,
    int? bonusSeconds,
    int? itemsPresented,
    int? itemsCompleted,
    int? newWordsPresented,
    int? reviewsPresented,
    double? accuracyRate,
    int? avgResponseTimeMs,
    int? outcome,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      bonusSeconds: bonusSeconds ?? this.bonusSeconds,
      itemsPresented: itemsPresented ?? this.itemsPresented,
      itemsCompleted: itemsCompleted ?? this.itemsCompleted,
      newWordsPresented: newWordsPresented ?? this.newWordsPresented,
      reviewsPresented: reviewsPresented ?? this.reviewsPresented,
      accuracyRate: accuracyRate ?? this.accuracyRate,
      avgResponseTimeMs: avgResponseTimeMs ?? this.avgResponseTimeMs,
      outcome: outcome ?? this.outcome,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
