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
        'english_definition': 'Definition of $word',
        'part_of_speech': 'noun',
        'synonyms': ['synonym1'],
        'antonyms': <String>[],
        'confusables': <Map<String, dynamic>>[],
        'example_sentences': <Map<String, dynamic>>[],
        'translations': {
          'en': {
            'primary': '${word}Translation',
            'alternatives': <String>[],
          },
        },
        'overrides': <String, dynamic>{},
        'has_encounter_context': hasEncounterContext,
        'has_confusables': hasConfusables,
        'non_translation_success_count': 0,
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
      when(
        mockDataService.countEnrichedNewWords(userId),
      ).thenAnswer((_) async => 100); // Default: plenty of new words available
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
          newWordsPerSession: 5,
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
          newWordsPerSession: 5,
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
          newWordsPerSession: 5,
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
          newWordsPerSession: 5,
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
          newWordsPerSession: 3, // Light intensity
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
          newWordsPerSession: 5,
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
          newWordsPerSession: 5,
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
          newWordsPerSession: 5,
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
            newWordsPerSession: 5,
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
              'english_definition': 'Definition of normal',
              'part_of_speech': 'noun',
              'synonyms': <String>[],
              'antonyms': <String>[],
              'confusables': <Map<String, dynamic>>[],
              'example_sentences': <Map<String, dynamic>>[],
              'translations': {
                'en': {
                  'primary': 'normalTranslation',
                  'alternatives': <String>[],
                },
              },
              'overrides': <String, dynamic>{},
              'has_encounter_context': false,
              'has_confusables': false,
              'non_translation_success_count': 0,
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
              'english_definition': 'Definition of leech',
              'part_of_speech': 'noun',
              'synonyms': <String>[],
              'antonyms': <String>[],
              'confusables': <Map<String, dynamic>>[],
              'example_sentences': <Map<String, dynamic>>[],
              'translations': {
                'en': {
                  'primary': 'leechTranslation',
                  'alternatives': <String>[],
                },
              },
              'overrides': <String, dynamic>{},
              'has_encounter_context': false,
              'has_confusables': false,
              'non_translation_success_count': 0,
            },
          ],
        );

        final plan = await planner.buildSessionPlan(
          userId: userId,
          timeTargetMinutes: 10,
          newWordsPerSession: 5,
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
          newWordsPerSession: 5,
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
          newWordsPerSession: 5,
        );

        expect(params.maxItems, 0);
        expect(params.newWordCap, 0);
        expect(params.estimatedSecondsPerItem, 0);
        expect(params.estimatedItemCount, 0);
      });

      test('computes correct capacity and new word cap', () async {
        // 10 min * 60 / 15 sec = 40 items
        // overdue=0, newWordCap=5, availableNewWords=100 → estimated=min(40, 0+5)=5
        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          newWordsPerSession: 5, // Normal: 5 new words per 10 min
        );

        expect(params.maxItems, 40);
        expect(params.newWordCap, 5);
        expect(params.estimatedSecondsPerItem, 15.0);
        expect(params.estimatedItemCount, 5);
      });

      test('estimatedItemCount includes overdue reviews', () async {
        when(
          mockDataService.getOverdueCount(userId),
        ).thenAnswer((_) async => 10);

        // overdue=10, newWordCap=5, availableNewWords=100 → estimated=min(40, 10+5)=15
        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          newWordsPerSession: 5,
        );

        expect(params.estimatedItemCount, 15);
      });

      test('estimatedItemCount capped by maxItems', () async {
        when(
          mockDataService.getOverdueCount(userId),
        ).thenAnswer((_) async => 50);

        // overdue=50, newWordCap=5, availableNewWords=100 → estimated=min(40, 50+5)=40
        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          newWordsPerSession: 5,
        );

        expect(params.estimatedItemCount, 40);
      });

      test('estimatedItemCount limited by available new words', () async {
        when(
          mockDataService.countEnrichedNewWords(userId),
        ).thenAnswer((_) async => 2);

        // overdue=0, newWordCap=5, availableNewWords=2 → estimated=min(40, 0+2)=2
        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          newWordsPerSession: 5,
        );

        expect(params.estimatedItemCount, 2);
      });

      test('suppresses new words when overdue count is high', () async {
        when(
          mockDataService.getOverdueCount(userId),
        ).thenAnswer((_) async => 100); // High overdue

        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          newWordsPerSession: 8, // Intense
        );

        expect(params.maxItems, 40);
        expect(params.newWordCap, 0); // Suppressed
        expect(params.estimatedItemCount, 40); // Capped at maxItems
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

    group('fetchBatch - multi-batch simulation', () {
      /// Simulates the session screen's batch loading: fetches an initial
      /// batch, then subsequent batches using the unreviewed tail as the
      /// exclude set (mirroring _unreviewedCardIds).
      ///
      /// The DB returns all 15 cards sorted by due (same order every call),
      /// and after "reviewing" a card we assume its due is pushed forward
      /// so it sorts to the end. We simulate this by moving reviewed cards
      /// to the end of the return list on each call.

      test('multiple batches yield no duplicate cards', () async {
        // 15 cards total in DB
        final allCards = List.generate(
          15,
          (i) => createCardJson(
            cardId: 'card-$i',
            vocabularyId: 'vocab-$i',
            word: 'word$i',
          ),
        );

        // Track which cards have been "reviewed" (due pushed forward)
        final reviewedIds = <String>{};

        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          // Simulate DB sorting: unreviewed first (by original order),
          // then reviewed cards (due pushed to future)
          final unreviewed = allCards.where(
            (c) => !reviewedIds.contains(c['card_id']),
          );
          final reviewed = allCards.where(
            (c) => reviewedIds.contains(c['card_id']),
          );
          return [...unreviewed, ...reviewed];
        });

        const batchSize = 5;
        final items = <String>[]; // All items seen across batches
        var currentIndex = 0;

        // --- Batch 1: initial fetch ---
        final batch1 = await planner.fetchBatch(
          userId: userId,
          batchSize: batchSize,
          newWordCap: 20,
        );
        expect(batch1, hasLength(batchSize));
        items.addAll(batch1.map((i) => i.cardId));

        // "Review" first 3 cards (simulating user progress)
        for (var i = 0; i < 3; i++) {
          reviewedIds.add(items[currentIndex + i]);
        }
        currentIndex = 3; // User is on item index 3

        // --- Batch 2: prefetch with unreviewed tail as exclude ---
        // Unreviewed tail = items from currentIndex onwards
        final excludeIds1 = items.skip(currentIndex).toSet();
        final batch2 = await planner.fetchBatch(
          userId: userId,
          batchSize: batchSize,
          excludeCardIds: excludeIds1,
          newWordCap: 20,
        );
        expect(batch2, hasLength(batchSize));
        items.addAll(batch2.map((i) => i.cardId));

        // Verify no duplicates so far
        expect(
          items.toSet().length,
          items.length,
          reason: 'Batch 2 introduced duplicates',
        );

        // "Review" remaining items in batch 1 + first 3 of batch 2
        for (var i = currentIndex; i < currentIndex + 5; i++) {
          reviewedIds.add(items[i]);
        }
        currentIndex = 8; // Now at item index 8

        // --- Batch 3: another prefetch ---
        final excludeIds2 = items.skip(currentIndex).toSet();
        final batch3 = await planner.fetchBatch(
          userId: userId,
          batchSize: batchSize,
          excludeCardIds: excludeIds2,
          newWordCap: 20,
        );
        expect(batch3, hasLength(batchSize));
        items.addAll(batch3.map((i) => i.cardId));

        // Verify no duplicates across all 3 batches
        expect(
          items.toSet().length,
          items.length,
          reason: 'Batch 3 introduced duplicates',
        );

        // Verify we fetched all 15 unique cards
        expect(items.toSet().length, 15);
      });

      test(
        'exclude set only needs unreviewed items, not all history',
        () async {
          // 12 cards total
          final allCards = List.generate(
            12,
            (i) => createCardJson(
              cardId: 'card-$i',
              vocabularyId: 'vocab-$i',
              word: 'word$i',
            ),
          );

          final reviewedIds = <String>{};

          when(
            mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
          ).thenAnswer((_) async {
            final unreviewed = allCards.where(
              (c) => !reviewedIds.contains(c['card_id']),
            );
            final reviewed = allCards.where(
              (c) => reviewedIds.contains(c['card_id']),
            );
            return [...unreviewed, ...reviewed];
          });

          // Batch 1: fetch 5
          final batch1 = await planner.fetchBatch(
            userId: userId,
            batchSize: 5,
            newWordCap: 20,
          );
          expect(batch1.map((i) => i.cardId).toList(), [
            'card-0',
            'card-1',
            'card-2',
            'card-3',
            'card-4',
          ]);

          // Review all 5
          for (final item in batch1) {
            reviewedIds.add(item.cardId);
          }

          // Batch 2: exclude set is empty (all reviewed, none unreviewed)
          // Reviewed cards have due pushed to future, so DB sorts them last.
          // Fetch should return the next 5 unreviewed cards.
          final batch2 = await planner.fetchBatch(
            userId: userId,
            batchSize: 5,
            excludeCardIds: <String>{}, // No unreviewed items to exclude
            newWordCap: 20,
          );

          // Should get cards 5-9 (the next unreviewed cards)
          expect(batch2.map((i) => i.cardId).toList(), [
            'card-5',
            'card-6',
            'card-7',
            'card-8',
            'card-9',
          ]);
        },
      );

      test(
        'race condition: prefetch during review excludes current batch',
        () async {
          // Simulates the race condition where a prefetch runs while the user
          // is reviewing cards in the current batch. Cards 3 and 4 are still
          // unreviewed and in the local queue, so the prefetch must exclude them.
          final allCards = List.generate(
            10,
            (i) => createCardJson(
              cardId: 'card-$i',
              vocabularyId: 'vocab-$i',
              word: 'word$i',
            ),
          );

          // Only cards 0,1,2 have been reviewed so far
          final reviewedIds = {'card-0', 'card-1', 'card-2'};

          when(
            mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
          ).thenAnswer((_) async {
            // DB returns: unreviewed first, reviewed last
            final unreviewed = allCards.where(
              (c) => !reviewedIds.contains(c['card_id']),
            );
            final reviewed = allCards.where(
              (c) => reviewedIds.contains(c['card_id']),
            );
            return [...unreviewed, ...reviewed];
          });

          // Prefetch triggered at currentIndex=2 (just reviewed card-2).
          // Unreviewed tail in local _items = [card-3, card-4]
          final excludeIds = {'card-3', 'card-4'};

          final batch = await planner.fetchBatch(
            userId: userId,
            batchSize: 5,
            excludeCardIds: excludeIds,
            newWordCap: 20,
          );

          // Should get cards 5-9 (skipping 3,4 which are excluded)
          final fetchedIds = batch.map((i) => i.cardId).toSet();
          expect(
            fetchedIds,
            isNot(contains('card-3')),
            reason: 'card-3 is in local queue, should be excluded',
          );
          expect(
            fetchedIds,
            isNot(contains('card-4')),
            reason: 'card-4 is in local queue, should be excluded',
          );
          expect(
            fetchedIds,
            isNot(contains('card-0')),
            reason: 'card-0 was reviewed, should sort after unreviewed',
          );
          expect(batch, hasLength(5));
          expect(batch.map((i) => i.cardId).toList(), [
            'card-5',
            'card-6',
            'card-7',
            'card-8',
            'card-9',
          ]);
        },
      );

      test('small deck: reviewed cards reappear without exclude set', () async {
        // With only 6 cards total, after reviewing 3 and fetching with a
        // limit of 5+0=5, the DB returns cards 3,4,5,0,1 (reviewed sort last
        // but still within limit). Without an exclude set, cards 3,4 would
        // be duplicates if they're still in the local queue.
        final allCards = List.generate(
          6,
          (i) => createCardJson(
            cardId: 'card-$i',
            vocabularyId: 'vocab-$i',
            word: 'word$i',
          ),
        );

        final reviewedIds = {'card-0', 'card-1', 'card-2'};

        when(
          mockDataService.getSessionCards(userId, limit: anyNamed('limit')),
        ).thenAnswer((_) async {
          final unreviewed = allCards.where(
            (c) => !reviewedIds.contains(c['card_id']),
          );
          final reviewed = allCards.where(
            (c) => reviewedIds.contains(c['card_id']),
          );
          return [...unreviewed, ...reviewed];
        });

        // Without exclude: fetch returns card-3,4,5,0,1 (5 cards, limit=5)
        final batchNoExclude = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          newWordCap: 20,
        );
        // card-0,1,2 reviewed (sort last), card-3,4,5 unreviewed (sort first)
        // With limit 5: returns card-3,4,5,card-0,card-1
        expect(batchNoExclude, hasLength(5));
        expect(
          batchNoExclude.map((i) => i.cardId),
          containsAll(<String>['card-3', 'card-4', 'card-5']),
        );
        // card-0 and card-1 also returned — would be duplicates!

        // With exclude set {card-3, card-4} (unreviewed tail in local queue):
        final batchWithExclude = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          excludeCardIds: {'card-3', 'card-4'},
          newWordCap: 20,
        );
        // Should get card-5 plus reviewed cards that sort later
        expect(
          batchWithExclude.map((i) => i.cardId).toList(),
          isNot(contains('card-3')),
        );
        expect(
          batchWithExclude.map((i) => i.cardId).toList(),
          isNot(contains('card-4')),
        );
      });

      test('new word cap tracked across multiple batches', () async {
        // 10 cards: 5 new (state=0), 5 due (state=2)
        final allCards = <Map<String, dynamic>>[
          // Due cards come first in DB ordering (state != 0 → priority 0)
          ...List.generate(
            5,
            (i) => createCardJson(
              cardId: 'due-$i',
              vocabularyId: 'vocab-due-$i',
              word: 'due$i',
              state: 2,
            ),
          ),
          // New cards after (state=0 → priority 1)
          ...List.generate(
            5,
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
        ).thenAnswer((_) async => allCards);

        // Batch 1: cap=3, already queued=0
        final batch1 = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          newWordCap: 3,
          newWordsAlreadyQueued: 0,
        );
        final newInBatch1 = batch1.where((i) => i.isNewWord).length;

        // Batch 2: cap=3, already queued = newInBatch1
        final batch2 = await planner.fetchBatch(
          userId: userId,
          batchSize: 5,
          excludeCardIds: batch1.map((i) => i.cardId).toSet(),
          newWordCap: 3,
          newWordsAlreadyQueued: newInBatch1,
        );
        final newInBatch2 = batch2.where((i) => i.isNewWord).length;

        // Total new words across both batches should not exceed cap
        expect(newInBatch1 + newInBatch2, lessThanOrEqualTo(3));
      });
    });
  });
}
