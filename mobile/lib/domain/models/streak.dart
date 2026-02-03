/// Streak entity - tracks learning streaks per user
class StreakModel {
  const StreakModel({
    required this.id,
    required this.userId,
    this.currentCount = 0,
    this.longestCount = 0,
    this.lastCompletedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currentCount: json['current_count'] as int? ?? 0,
      longestCount: json['longest_count'] as int? ?? 0,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String userId;
  final int currentCount;
  final int longestCount;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_count': currentCount,
      'longest_count': longestCount,
      'last_completed_date': lastCompletedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StreakModel copyWith({
    String? id,
    String? userId,
    int? currentCount,
    int? longestCount,
    DateTime? lastCompletedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StreakModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentCount: currentCount ?? this.currentCount,
      longestCount: longestCount ?? this.longestCount,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
