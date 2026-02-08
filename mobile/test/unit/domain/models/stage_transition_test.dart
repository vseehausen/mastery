import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/progress_stage.dart';
import 'package:mastery/domain/models/stage_transition.dart';

void main() {
  group('StageTransition', () {
    final timestamp = DateTime(2026, 2, 8, 10, 30);

    group('isRareAchievement', () {
      test('returns true for transition to Active', () {
        final transition = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          fromStage: ProgressStage.stabilizing,
          toStage: ProgressStage.active,
          timestamp: timestamp,
        );

        expect(transition.isRareAchievement, true);
      });

      test('returns true for transition to Mastered', () {
        final transition = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          fromStage: ProgressStage.active,
          toStage: ProgressStage.mastered,
          timestamp: timestamp,
        );

        expect(transition.isRareAchievement, true);
      });

      test('returns false for transition to Captured', () {
        final transition = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          fromStage: null,
          toStage: ProgressStage.captured,
          timestamp: timestamp,
        );

        expect(transition.isRareAchievement, false);
      });

      test('returns false for transition to Practicing', () {
        final transition = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          fromStage: ProgressStage.captured,
          toStage: ProgressStage.practicing,
          timestamp: timestamp,
        );

        expect(transition.isRareAchievement, false);
      });

      test('returns false for transition to Stabilizing', () {
        final transition = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: timestamp,
        );

        expect(transition.isRareAchievement, false);
      });
    });

    group('JSON serialization', () {
      test('toJson converts to map correctly', () {
        final transition = StageTransition(
          vocabularyId: 'abc-123',
          wordText: 'example',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: timestamp,
        );

        final json = transition.toJson();

        expect(json['vocabularyId'], 'abc-123');
        expect(json['wordText'], 'example');
        expect(json['fromStage'], 'practicing');
        expect(json['toStage'], 'stabilizing');
        expect(json['timestamp'], timestamp.toIso8601String());
      });

      test('toJson handles null fromStage', () {
        final transition = StageTransition(
          vocabularyId: 'abc-123',
          wordText: 'example',
          fromStage: null,
          toStage: ProgressStage.captured,
          timestamp: timestamp,
        );

        final json = transition.toJson();

        expect(json['fromStage'], isNull);
        expect(json['toStage'], 'captured');
      });

      test('fromJson creates instance correctly', () {
        final json = {
          'vocabularyId': 'xyz-456',
          'wordText': 'test',
          'fromStage': 'stabilizing',
          'toStage': 'active',
          'timestamp': timestamp.toIso8601String(),
        };

        final transition = StageTransition.fromJson(json);

        expect(transition.vocabularyId, 'xyz-456');
        expect(transition.wordText, 'test');
        expect(transition.fromStage, ProgressStage.stabilizing);
        expect(transition.toStage, ProgressStage.active);
        expect(transition.timestamp, timestamp);
      });

      test('fromJson handles null fromStage', () {
        final json = {
          'vocabularyId': 'xyz-456',
          'wordText': 'test',
          'fromStage': null,
          'toStage': 'captured',
          'timestamp': timestamp.toIso8601String(),
        };

        final transition = StageTransition.fromJson(json);

        expect(transition.fromStage, isNull);
        expect(transition.toStage, ProgressStage.captured);
      });

      test('round-trip serialization preserves data', () {
        final original = StageTransition(
          vocabularyId: 'test-id',
          wordText: 'roundtrip',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: timestamp,
        );

        final json = original.toJson();
        final deserialized = StageTransition.fromJson(json);

        expect(deserialized.vocabularyId, original.vocabularyId);
        expect(deserialized.wordText, original.wordText);
        expect(deserialized.fromStage, original.fromStage);
        expect(deserialized.toStage, original.toStage);
        expect(deserialized.timestamp, original.timestamp);
      });
    });

    group('equality', () {
      test('two identical transitions are equal', () {
        final transition1 = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: timestamp,
        );

        final transition2 = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: timestamp,
        );

        expect(transition1, equals(transition2));
        expect(transition1.hashCode, equals(transition2.hashCode));
      });

      test('transitions with different IDs are not equal', () {
        final transition1 = StageTransition(
          vocabularyId: '123',
          wordText: 'test',
          toStage: ProgressStage.practicing,
          timestamp: timestamp,
        );

        final transition2 = StageTransition(
          vocabularyId: '456',
          wordText: 'test',
          toStage: ProgressStage.practicing,
          timestamp: timestamp,
        );

        expect(transition1, isNot(equals(transition2)));
      });
    });

    group('toString', () {
      test('includes word and stage transition', () {
        final transition = StageTransition(
          vocabularyId: '123',
          wordText: 'example',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: timestamp,
        );

        final str = transition.toString();

        expect(str, contains('example'));
        expect(str, contains('Practicing'));
        expect(str, contains('Stabilizing'));
      });

      test('handles null fromStage', () {
        final transition = StageTransition(
          vocabularyId: '123',
          wordText: 'example',
          fromStage: null,
          toStage: ProgressStage.captured,
          timestamp: timestamp,
        );

        final str = transition.toString();

        expect(str, contains('example'));
        expect(str, contains('Captured'));
      });
    });
  });
}
