import '../../core/app_defaults.dart';

/// User learning preferences entity
class UserPreferencesModel {
  const UserPreferencesModel({
    required this.id,
    required this.userId,
    this.dailyTimeTargetMinutes = AppDefaults.dailyTimeTargetMinutes,
    this.targetRetention = AppDefaults.targetRetention,
    this.intensity = AppDefaults.intensity,
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
          AppDefaults.dailyTimeTargetMinutes,
      targetRetention:
          (json['target_retention'] as num?)?.toDouble() ??
          AppDefaults.targetRetention,
      intensity: json['intensity'] as int? ?? AppDefaults.intensity,
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
  final int intensity; // 0=light, 1=normal, 2=intense
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
      'intensity': intensity,
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
    int? intensity,
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
      intensity: intensity ?? this.intensity,
      newWordSuppressionActive:
          newWordSuppressionActive ?? this.newWordSuppressionActive,
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      meaningDisplayMode: meaningDisplayMode ?? this.meaningDisplayMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
