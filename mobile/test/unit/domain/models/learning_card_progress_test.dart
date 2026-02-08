import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/learning_card.dart';
import 'package:mastery/domain/models/progress_stage.dart';

void main() {
  group('LearningCardModel with progressStage', () {
    final now = DateTime.now();

    group('JSON serialization', () {
      test('fromJson parses progress_stage correctly', () {
        final json = {
          'id': 'card-123',
          'user_id': 'user-456',
          'vocabulary_id': 'vocab-789',
          'state': 2,
          'due': now.toIso8601String(),
          'stability': 5.0,
          'difficulty': 6.5,
          'reps': 3,
          'lapses': 1,
          'last_review': now.toIso8601String(),
          'is_leech': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'deleted_at': null,
          'version': 1,
          'progress_stage': 'stabilizing',
        };

        final card = LearningCardModel.fromJson(json);

        expect(card.progressStage, ProgressStage.stabilizing);
      });

      test('fromJson handles null progress_stage', () {
        final json = {
          'id': 'card-123',
          'user_id': 'user-456',
          'vocabulary_id': 'vocab-789',
          'state': 2,
          'due': now.toIso8601String(),
          'stability': 5.0,
          'difficulty': 6.5,
          'reps': 3,
          'lapses': 1,
          'is_leech': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'version': 1,
        };

        final card = LearningCardModel.fromJson(json);

        expect(card.progressStage, isNull);
      });

      test('toJson includes progress_stage', () {
        final card = LearningCardModel(
          id: 'card-123',
          userId: 'user-456',
          vocabularyId: 'vocab-789',
          state: 2,
          due: now,
          stability: 5.0,
          difficulty: 6.5,
          reps: 3,
          lapses: 1,
          isLeech: false,
          createdAt: now,
          updatedAt: now,
          progressStage: ProgressStage.active,
        );

        final json = card.toJson();

        expect(json['progress_stage'], 'active');
      });

      test('toJson handles null progress_stage', () {
        final card = LearningCardModel(
          id: 'card-123',
          userId: 'user-456',
          vocabularyId: 'vocab-789',
          state: 2,
          due: now,
          stability: 5.0,
          difficulty: 6.5,
          reps: 3,
          lapses: 1,
          isLeech: false,
          createdAt: now,
          updatedAt: now,
        );

        final json = card.toJson();

        expect(json['progress_stage'], isNull);
      });

      test('round-trip serialization preserves progress_stage', () {
        final original = LearningCardModel(
          id: 'card-123',
          userId: 'user-456',
          vocabularyId: 'vocab-789',
          state: 2,
          due: now,
          stability: 5.0,
          difficulty: 6.5,
          reps: 3,
          lapses: 1,
          isLeech: false,
          createdAt: now,
          updatedAt: now,
          progressStage: ProgressStage.mastered,
        );

        final json = original.toJson();
        final deserialized = LearningCardModel.fromJson(json);

        expect(deserialized.progressStage, ProgressStage.mastered);
      });
    });

    group('copyWith', () {
      test('can update progress_stage', () {
        final original = LearningCardModel(
          id: 'card-123',
          userId: 'user-456',
          vocabularyId: 'vocab-789',
          state: 2,
          due: now,
          stability: 5.0,
          difficulty: 6.5,
          reps: 3,
          lapses: 1,
          isLeech: false,
          createdAt: now,
          updatedAt: now,
          progressStage: ProgressStage.stabilizing,
        );

        final updated = original.copyWith(progressStage: ProgressStage.active);

        expect(updated.progressStage, ProgressStage.active);
        expect(updated.id, original.id); // other fields unchanged
      });

      test('preserves progress_stage when not specified', () {
        final original = LearningCardModel(
          id: 'card-123',
          userId: 'user-456',
          vocabularyId: 'vocab-789',
          state: 2,
          due: now,
          stability: 5.0,
          difficulty: 6.5,
          reps: 3,
          lapses: 1,
          isLeech: false,
          createdAt: now,
          updatedAt: now,
          progressStage: ProgressStage.active,
        );

        final updated = original.copyWith(reps: 4);

        expect(updated.progressStage, ProgressStage.active);
        expect(updated.reps, 4);
      });
    });
  });
}
