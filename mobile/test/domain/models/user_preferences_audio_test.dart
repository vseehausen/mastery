import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/app_defaults.dart';
import 'package:mastery/domain/models/user_preferences.dart';

void main() {
  group('UserPreferencesModel audio fields', () {
    test('defaults to audioEnabled=true and audioAccent=us', () {
      final prefs = UserPreferencesModel(
        id: 'test',
        userId: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(prefs.audioEnabled, true);
      expect(prefs.audioAccent, 'us');
    });

    test('fromJson parses audio fields', () {
      final json = {
        'id': 'test',
        'user_id': 'user',
        'daily_time_target_minutes': 5,
        'target_retention': 0.90,
        'new_words_per_session': 5,
        'new_word_suppression_active': false,
        'native_language_code': 'de',
        'audio_enabled': false,
        'audio_accent': 'gb',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };
      final prefs = UserPreferencesModel.fromJson(json);
      expect(prefs.audioEnabled, false);
      expect(prefs.audioAccent, 'gb');
    });

    test('fromJson uses defaults when audio fields missing', () {
      final json = {
        'id': 'test',
        'user_id': 'user',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };
      final prefs = UserPreferencesModel.fromJson(json);
      expect(prefs.audioEnabled, AppDefaults.audioEnabled);
      expect(prefs.audioAccent, AppDefaults.audioAccent);
    });

    test('toJson includes audio fields', () {
      final prefs = UserPreferencesModel(
        id: 'test',
        userId: 'user',
        audioEnabled: false,
        audioAccent: 'gb',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final json = prefs.toJson();
      expect(json['audio_enabled'], false);
      expect(json['audio_accent'], 'gb');
    });

    test('copyWith updates audio fields', () {
      final prefs = UserPreferencesModel(
        id: 'test',
        userId: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final updated = prefs.copyWith(audioEnabled: false, audioAccent: 'gb');
      expect(updated.audioEnabled, false);
      expect(updated.audioAccent, 'gb');
      // Original unchanged
      expect(prefs.audioEnabled, true);
      expect(prefs.audioAccent, 'us');
    });
  });
}
