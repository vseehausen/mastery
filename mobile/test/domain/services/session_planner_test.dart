import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/session_card.dart';
import 'package:mastery/domain/services/cue_selector.dart';
import 'package:mastery/domain/services/session_planner.dart';
import 'package:mastery/domain/services/telemetry_service.dart';
import 'package:mastery/data/services/supabase_data_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([SupabaseDataService, TelemetryService])
import 'session_planner_test.mocks.dart';

void main() {
  group('SessionPlanner', () {
    late SessionPlanner planner;
    late MockSupabaseDataService mockDataService;
    late MockTelemetryService mockTelemetryService;
    late CueSelector cueSelector;

    const userId = 'user-123';

    /// Create a mock session card JSON response
    Map<String, dynamic> createCardJson({
      required String cardId,
      required String vocabularyId,
      required String word,
      int state = 2,
      double stability = 10.0,
      bool isLeech = false,
      bool hasEncounterContext = false,
      bool hasConfusables = false,
    }) {
      return {
        'card_id': cardId,
        'vocabulary_id': vocabularyId,
        'state': state,
        'due': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'stability': stability,
        'difficulty': 0.3,
        'reps': state == 0 ? 0 : 5,
        'lapses': 0,
        'last_review': state == 0
            ? null
            : DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
        'is_leech': isLeech,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
        'word': word,
        'stem': word.substring(0, word.length - 1),
        'meanings': [
          {
            'id': 'meaning-$cardId',
            'primary_translation': '${word}Translation',
            'english_definition': 'Definition of $word',
            'synonyms': ['synonym1'],
            'is_primary': true,
            'sort_order': 0,
          },
        ],
        'cues': [
          {
            'id': 'cue-$cardId',
            'meaning_id': 'meaning-$cardId',
            'cue_type': 'translation',
            'prompt_text': 'What is $word?',
            'answer_text': '${word}Translation',
          },
        ],
        'has_encounter_context': hasEncounterContext,
        'has_confusables': hasConfusables,
      };
    }

    setUp(() {
      mockDataService = MockSupabaseDataService();
      mockTelemetryService = MockTelemetryService();
      cueSelector = CueSelector(random: Random(42));

      planner = SessionPlanner(
        dataService: mockDataService,
        telemetryService: mockTelemetryService,
        cueSelector: cueSelector,
      );

      // Default stubs
      when(
        mockTelemetryService.getEstimatedSecondsPerItem(userId),
      ).thenAnswer((_) async => 15.0);
      when(mockDataService.getOverdueCount(userId)).thenAnswer((_) async => 0);
      when(mockDataService.getOrCreatePreferences(userId)).thenAnswer(
        (_) async => {
          'new_word_suppression_active': false,
          'daily_time_target_minutes': 10,
        },
      );
      when(
        mockDataService.updatePreferences(
          userId: anyNamed('userId'),
          newWordSuppressionActive: anyNamed('newWordSuppressionActive'),
        ),
      ).thenAnswer((_) async {});
    });

    group('buildSessionPlan', () {
      test('returns empty plan when maxItems is 0', () async {
        when(
          mockTelemetryService.getEstimatedSecondsPerItem(userId),
        ).thenAnswer((_) async => 1000.0); // Very slow = 0 items fit

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 1,
          intensity: 1,
          targetRetention: 0.90,
        );

        expect(plan.isEmpty, true);
        expect(plan.items, isEmpty);
      });

      test('fetches session cards and builds plan', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-1',
              vocabularyId: 'vocab-1',
              word: 'house',
              state: 2,
            ),
            createCardJson(
              cardId: 'card-2',
              vocabularyId: 'vocab-2',
              word: 'tree',
              state: 2,
            ),
          ],
        );

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        expect(plan.items, hasLength(2));
        expect(plan.items[0].word, 'house');
        expect(plan.items[1].word, 'tree');
        expect(plan.reviewCount, 2);
        expect(plan.newWordCount, 0);
      });

      test('separates due cards, leeches, and new cards', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-due',
              vocabularyId: 'vocab-due',
              word: 'due',
              state: 2,
            ),
            createCardJson(
              cardId: 'card-leech',
              vocabularyId: 'vocab-leech',
              word: 'leech',
              state: 2,
              isLeech: true,
            ),
            createCardJson(
              cardId: 'card-new',
              vocabularyId: 'vocab-new',
              word: 'new',
              state: 0,
            ),
          ],
        );

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        expect(plan.items, hasLength(3));
        // Due cards come first
        expect(plan.items[0].word, 'due');
        // Leeches next
        expect(plan.items[1].word, 'leech');
        expect(plan.items[1].isLeech, true);
        // New words last
        expect(plan.items[2].word, 'new');
        expect(plan.items[2].isNewWord, true);

        expect(plan.reviewCount, 1);
        expect(plan.leechCount, 1);
        expect(plan.newWordCount, 1);
      });

      test('respects maxItems limit', () async {
        // Create 20 cards
        final cards = List.generate(
          20,
          (i) => createCardJson(
            cardId: 'card-$i',
            vocabularyId: 'vocab-$i',
            word: 'word$i',
            state: 2,
          ),
        );

        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer((_) async => cards);

        // 10 minute session, 15 seconds per item = 40 items max
        // But we only have 20 cards
        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        expect(plan.items.length, lessThanOrEqualTo(40));
      });

      test('respects new word cap based on intensity', () async {
        // Create mix of due and new cards
        final cards = [
          ...List.generate(
            5,
            (i) => createCardJson(
              cardId: 'due-$i',
              vocabularyId: 'vocab-due-$i',
              word: 'due$i',
              state: 2,
            ),
          ),
          ...List.generate(
            10,
            (i) => createCardJson(
              cardId: 'new-$i',
              vocabularyId: 'vocab-new-$i',
              word: 'new$i',
              state: 0,
            ),
          ),
        ];

        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer((_) async => cards);

        // Low intensity = fewer new words
        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 0, // Light intensity
          targetRetention: 0.90,
        );

        // New word cap for light intensity is typically low
        expect(plan.newWordCount, lessThan(10));
      });

      test('assigns cue types to all items', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-1',
              vocabularyId: 'vocab-1',
              word: 'house',
              state: 2,
              stability: 25.0, // Mature
            ),
          ],
        );

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        expect(plan.items, hasLength(1));
        expect(plan.items[0].cueType, isNotNull);
      });

      test('computes estimated duration', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-1',
              vocabularyId: 'vocab-1',
              word: 'house',
              state: 2,
            ),
            createCardJson(
              cardId: 'card-2',
              vocabularyId: 'vocab-2',
              word: 'tree',
              state: 2,
            ),
          ],
        );

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        // 2 items * 15 seconds = 30 seconds
        expect(plan.estimatedDurationSeconds, 30);
      });
    });

    group('shouldSuppressNewWords', () {
      test('returns true when session capacity is 0', () {
        final result = planner.shouldSuppressNewWords(
          overdueCount: 5,
          sessionCapacity: 0,
          previouslySuppressed: false,
        );

        expect(result, true);
      });

      test('returns false when overdue count is low', () {
        final result = planner.shouldSuppressNewWords(
          overdueCount: 5,
          sessionCapacity: 20,
          previouslySuppressed: false,
        );

        expect(result, false);
      });

      test('returns true when overdue exceeds session capacity', () {
        final result = planner.shouldSuppressNewWords(
          overdueCount: 25,
          sessionCapacity: 20,
          previouslySuppressed: false,
        );

        expect(result, true);
      });

      test('uses higher threshold when previously suppressed', () {
        // When previously suppressed, exit threshold is 2x session capacity
        final result = planner.shouldSuppressNewWords(
          overdueCount: 25,
          sessionCapacity: 20,
          previouslySuppressed: true,
        );

        // 25 <= 2 * 20 = 40, so should NOT suppress anymore
        expect(result, false);
      });

      test('maintains suppression when overdue still high', () {
        final result = planner.shouldSuppressNewWords(
          overdueCount: 50,
          sessionCapacity: 20,
          previouslySuppressed: true,
        );

        // 50 > 2 * 20 = 40, so should maintain suppression
        expect(result, true);
      });
    });

    group('selectInteractionMode', () {
      test('returns recall mode for all cards', () {
        final card = createCardJson(
          cardId: 'card-1',
          vocabularyId: 'vocab-1',
          word: 'house',
          state: 2,
        );

        // Parse the JSON to create a SessionCard
        final sessionCard = SessionCard.fromJson(card);
        final mode = planner.selectInteractionMode(sessionCard);

        expect(mode, InteractionMode.recall);
      });
    });

    group('new word suppression updates preferences', () {
      test('updates preferences when suppression state changes', () async {
        when(
          mockDataService.getOverdueCount(userId),
        ).thenAnswer((_) async => 100); // High overdue
        when(mockDataService.getOrCreatePreferences(userId)).thenAnswer(
          (_) async => {
            'new_word_suppression_active': false, // Currently not suppressed
            'daily_time_target_minutes': 10,
          },
        );
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        // Should update to suppress
        verify(
          mockDataService.updatePreferences(
            userId: userId,
            newWordSuppressionActive: true,
          ),
        ).called(1);
      });

      test(
        'does not update preferences when suppression state unchanged',
        () async {
          when(
            mockDataService.getOverdueCount(userId),
          ).thenAnswer((_) async => 5); // Low overdue
          when(mockDataService.getOrCreatePreferences(userId)).thenAnswer(
            (_) async => {
              'new_word_suppression_active': false, // Currently not suppressed
              'daily_time_target_minutes': 10,
            },
          );
          when(
            mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
          ).thenAnswer((_) async => []);

          await planner.buildSessionPlan(
            userId: userId,
            timeTargetMinutes: 10,
            intensity: 1,
            targetRetention: 0.90,
          );

          // Should not call updatePreferences since state didn't change
          verifyNever(
            mockDataService.updatePreferences(
              userId: anyNamed('userId'),
              newWordSuppressionActive: anyNamed('newWordSuppressionActive'),
            ),
          );
        },
      );
    });

    group('priority scoring', () {
      test('leeches have boosted priority', () async {
        // Create cards that are overdue (due date in the past)
        final overdueDate = DateTime.now()
            .subtract(const Duration(days: 7))
            .toIso8601String();
        final lastReviewDate = DateTime.now()
            .subtract(const Duration(days: 14))
            .toIso8601String();

        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            {
              'card_id': 'card-normal',
              'vocabulary_id': 'vocab-normal',
              'state': 2,
              'due': overdueDate,
              'stability': 10.0,
              'difficulty': 0.3,
              'reps': 5,
              'lapses': 0,
              'last_review': lastReviewDate,
              'is_leech': false,
              'created_at': DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
              'word': 'normal',
              'stem': 'norma',
              'meanings': [
                {
                  'id': 'meaning-normal',
                  'primary_translation': 'normalTranslation',
                  'english_definition': 'Definition of normal',
                  'synonyms': [],
                  'is_primary': true,
                  'sort_order': 0,
                },
              ],
              'cues': [],
              'has_encounter_context': false,
              'has_confusables': false,
            },
            {
              'card_id': 'card-leech',
              'vocabulary_id': 'vocab-leech',
              'state': 2,
              'due': overdueDate,
              'stability': 10.0,
              'difficulty': 0.3,
              'reps': 5,
              'lapses': 8, // Many lapses for leech
              'last_review': lastReviewDate,
              'is_leech': true,
              'created_at': DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
              'word': 'leech',
              'stem': 'leec',
              'meanings': [
                {
                  'id': 'meaning-leech',
                  'primary_translation': 'leechTranslation',
                  'english_definition': 'Definition of leech',
                  'synonyms': [],
                  'is_primary': true,
                  'sort_order': 0,
                },
              ],
              'cues': [],
              'has_encounter_context': false,
              'has_confusables': false,
            },
          ],
        );

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        final normalItem = plan.items.firstWhere((i) => i.word == 'normal');
        final leechItem = plan.items.firstWhere((i) => i.word == 'leech');

        // Both should have non-zero priority since they're overdue
        expect(normalItem.priority, greaterThan(0.0));
        expect(leechItem.priority, greaterThan(0.0));

        // Leech should have 1.5x priority boost
        expect(leechItem.priority, greaterThan(normalItem.priority * 1.4));
      });

      test('new words have lowest priority', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-due',
              vocabularyId: 'vocab-due',
              word: 'due',
              state: 2,
            ),
            createCardJson(
              cardId: 'card-new',
              vocabularyId: 'vocab-new',
              word: 'new',
              state: 0,
            ),
          ],
        );

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1,
          targetRetention: 0.90,
        );

        final newItem = plan.items.firstWhere((i) => i.word == 'new');

        expect(newItem.priority, 0.0);
      });
    });

    group('computeSessionParams', () {
      test('returns zero maxItems for very slow users', () async {
        when(
          mockTelemetryService.getEstimatedSecondsPerItem(userId),
        ).thenAnswer((_) async => 1000.0); // Very slow

        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 1,
          intensity: 1,
        );

        expect(params.maxItems, 0);
        expect(params.newWordCap, 0);
        expect(params.estimatedSecondsPerItem, 0);
      });

      test('computes correct capacity and new word cap', () async {
        // 10 min * 60 / 15 sec = 40 items
        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 1, // Normal: 5 new words per 10 min
        );

        expect(params.maxItems, 40);
        expect(params.newWordCap, 5);
        expect(params.estimatedSecondsPerItem, 15.0);
      });

      test('suppresses new words when overdue count is high', () async {
        when(
          mockDataService.getOverdueCount(userId),
        ).thenAnswer((_) async => 100); // High overdue

        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          intensity: 2, // Intense
        );

        expect(params.maxItems, 40);
        expect(params.newWordCap, 0); // Suppressed
      });
    });

    group('fetchBatch', () {
      test('returns empty list when no cards available', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer((_) async => []);

        final items = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          newWordCap: 5,
        );

        expect(items, isEmpty);
      });

      test('excludes already-fetched card IDs', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-1',
              vocabularyId: 'vocab-1',
              word: 'house',
            ),
            createCardJson(
              cardId: 'card-2',
              vocabularyId: 'vocab-2',
              word: 'tree',
            ),
            createCardJson(
              cardId: 'card-3',
              vocabularyId: 'vocab-3',
              word: 'river',
            ),
          ],
        );

        final items = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          excludeCardIds: {'card-1', 'card-2'},
          newWordCap: 5,
        );

        expect(items, hasLength(1));
        expect(items[0].word, 'river');
      });

      test('respects new word cap across batches', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-new-1',
              vocabularyId: 'vocab-new-1',
              word: 'alpha',
              state: 0,
            ),
            createCardJson(
              cardId: 'card-new-2',
              vocabularyId: 'vocab-new-2',
              word: 'beta',
              state: 0,
            ),
            createCardJson(
              cardId: 'card-due',
              vocabularyId: 'vocab-due',
              word: 'gamma',
              state: 2,
            ),
          ],
        );

        // Cap is 3 but 2 already queued => only 1 new word allowed
        final items = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          newWordsAlreadyQueued: 2,
          newWordCap: 3,
        );

        final newWordItems = items.where((i) => i.isNewWord).toList();
        expect(newWordItems, hasLength(1));
        // The due card should also be included
        expect(items.any((i) => i.word == 'gamma'), true);
      });

      test('respects batchSize limit', () async {
        final cards = List.generate(
          10,
          (i) => createCardJson(
            cardId: 'card-$i',
            vocabularyId: 'vocab-$i',
            word: 'word$i',
          ),
        );

        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer((_) async => cards);

        final items = await planner.fetchBatch(
          userId: userId,
          batchSize: 3,
          newWordCap: 10,
        );

        expect(items, hasLength(3));
      });

      test('assigns cue types to items', () async {
        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer(
          (_) async => [
            createCardJson(
              cardId: 'card-1',
              vocabularyId: 'vocab-1',
              word: 'house',
              state: 2,
              stability: 25.0,
            ),
          ],
        );

        final items = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          newWordCap: 5,
        );

        expect(items, hasLength(1));
        expect(items[0].cueType, isNotNull);
      });
    });
  });
}
