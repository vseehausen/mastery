import '../../core/app_defaults.dart';

/// User learning preferences entity
class UserPreferencesModel {
  const UserPreferencesModel({
    required this.id,
    required this.userId,
    this.dailyTimeTargetMinutes = AppDefaults.sessionDefault,
    this.targetRetention = AppDefaults.retentionDefault,
    this.newWordsPerSession = AppDefaults.newWordsDefault,
    this.newWordSuppressionActive = false,
    this.nativeLanguageCode = AppDefaults.nativeLanguageCode,
    this.meaningDisplayMode = AppDefaults.meaningDisplayMode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyTimeTargetMinutes:
          json['daily_time_target_minutes'] as int? ??
          AppDefaults.sessionDefault,
      targetRetention:
          (json['target_retention'] as num?)?.toDouble() ??
          AppDefaults.retentionDefault,
      newWordsPerSession:
          json['new_words_per_session'] as int? ??
          AppDefaults.newWordsDefault,
      newWordSuppressionActive:
          json['new_word_suppression_active'] as bool? ?? false,
      nativeLanguageCode:
          json['native_language_code'] as String? ??
          AppDefaults.nativeLanguageCode,
      meaningDisplayMode:
          json['meaning_display_mode'] as String? ??
          AppDefaults.meaningDisplayMode,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String userId;
  final int dailyTimeTargetMinutes;
  final double targetRetention;
  final int newWordsPerSession; // 3=few, 5=normal, 8=many
  final bool newWordSuppressionActive;
  final String nativeLanguageCode;
  final String meaningDisplayMode; // 'native', 'english', 'both'
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_time_target_minutes': dailyTimeTargetMinutes,
      'target_retention': targetRetention,
      'new_words_per_session': newWordsPerSession,
      'new_word_suppression_active': newWordSuppressionActive,
      'native_language_code': nativeLanguageCode,
      'meaning_display_mode': meaningDisplayMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserPreferencesModel copyWith({
    String? id,
    String? userId,
    int? dailyTimeTargetMinutes,
    double? targetRetention,
    int? newWordsPerSession,
    bool? newWordSuppressionActive,
    String? nativeLanguageCode,
    String? meaningDisplayMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferencesModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyTimeTargetMinutes:
          dailyTimeTargetMinutes ?? this.dailyTimeTargetMinutes,
      targetRetention: targetRetention ?? this.targetRetention,
      newWordsPerSession: newWordsPerSession ?? this.newWordsPerSession,
      newWordSuppressionActive:
          newWordSuppressionActive ?? this.newWordSuppressionActive,
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      meaningDisplayMode: meaningDisplayMode ?? this.meaningDisplayMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
