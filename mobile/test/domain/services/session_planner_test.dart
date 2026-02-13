import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/cue_type.dart';
import 'package:mastery/domain/models/planned_item.dart';
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
      when(mockDataService.hasBrandNewWord(userId)).thenAnswer((_) async => true);
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
            mockDataService.getSessionCards(
              userId,
              reviewLimit: anyNamed('reviewLimit'),
              newLimit: anyNamed('newLimit'),
              excludeIds: anyNamed('excludeIds'),
            ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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

      test('clamps newWordCap to maxItems when cap exceeds capacity', () async {
        // 1 min * 60 / 15 sec = 4 items max
        // newWordsPerSession=8 would normally produce a higher cap,
        // but it must be clamped to maxItems=4
        when(
          mockDataService.getOverdueCount(userId),
        ).thenAnswer((_) async => 0);

        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 1,
          newWordsPerSession: 8, // Would exceed maxItems=4
        );

        expect(params.maxItems, 4);
        expect(params.newWordCap, lessThanOrEqualTo(params.maxItems));
      });

      test('suppresses new words when overdue count is high', () async {
        when(
          mockDataService.getOverdueCount(userId),
        ).thenAnswer((_) async => 100); // High overdue
        when(mockDataService.hasBrandNewWord(userId)).thenAnswer((_) async => false); // No brand-new words

        final params = await planner.computeSessionParams(
          userId: userId,
          timeTargetMinutes: 10,
          newWordsPerSession: 8, // Intense
        );

        expect(params.maxItems, 40);
        expect(params.newWordCap, 0); // Suppressed (no brand-new word guarantee)
        expect(params.estimatedItemCount, 40); // Capped at maxItems
      });
    });

    group('fetchBatch', () {
      test('returns empty list when no cards available', () async {
        when(
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
        ).thenAnswer((_) async => []);

        final items = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 10,
          newLimit: 5,
        );

        expect(items, isEmpty);
      });

      test('excludes already-fetched card IDs', () async {
        final allCards = [
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
        ];

        when(
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
        ).thenAnswer((invocation) async {
          final excludeIds = invocation.namedArguments[#excludeIds] as List? ?? [];
          final excludeSet = excludeIds.toSet();
          return allCards.where((c) => !excludeSet.contains(c['card_id'])).toList();
        });

        final items = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 10,
          newLimit: 5,
          excludeCardIds: {'card-1', 'card-2'},
        );

        expect(items, hasLength(1));
        expect(items[0].word, 'river');
      });

      test('respects new word cap across batches', () async {
        final allCards = [
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
        ];

        when(
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
        ).thenAnswer((invocation) async {
          final newLimit = invocation.namedArguments[#newLimit] as int;
          final reviewLimit = invocation.namedArguments[#reviewLimit] as int;

          // Separate new cards (state=0) and review cards (state!=0)
          final newCards = allCards.where((c) => c['state'] == 0).take(newLimit).toList();
          final reviewCards = allCards.where((c) => c['state'] != 0).take(reviewLimit).toList();
          return [...reviewCards, ...newCards];
        });

        // Cap is 3 but 2 already queued => only 1 new word allowed
        // With new API: reviewLimit=10, newLimit=1 (3 - 2 already queued)
        final items = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 10,
          newLimit: 1,
        );

        final newWordItems = items.where((i) => i.isNewWord).toList();
        expect(newWordItems, hasLength(1));
        // The due card should also be included
        expect(items.any((i) => i.word == 'gamma'), true);
      });

      test('respects RPC limits', () async {
        final cards = List.generate(
          10,
          (i) => createCardJson(
            cardId: 'card-$i',
            vocabularyId: 'vocab-$i',
            word: 'word$i',
          ),
        );

        when(
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
        ).thenAnswer((invocation) async {
          final reviewLimit = invocation.namedArguments[#reviewLimit] as int;
          final newLimit = invocation.namedArguments[#newLimit] as int;
          return cards.take(reviewLimit + newLimit).toList();
        });

        final items = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 2,
          newLimit: 1,
        );

        // RPC returns up to reviewLimit + newLimit = 3 items
        expect(items.length, lessThanOrEqualTo(3));
      });

      test('assigns cue types to items', () async {
        when(
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
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
          reviewLimit: 10,
          newLimit: 5,
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
        ).thenAnswer((invocation) async {
          final excludeIds = invocation.namedArguments[#excludeIds] as List? ?? [];
          final excludeSet = excludeIds.toSet();
          final reviewLimit = invocation.namedArguments[#reviewLimit] as int;
          final newLimit = invocation.namedArguments[#newLimit] as int;

          // Simulate DB sorting: unreviewed first (by original order),
          // then reviewed cards (due pushed to future)
          final unreviewed = allCards.where(
            (c) => !reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
          ).toList();
          final reviewed = allCards.where(
            (c) => reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
          ).toList();

          // Limit results: up to reviewLimit reviews + newLimit new cards
          // For this test, all cards are state=2 (reviews)
          final result = [...unreviewed, ...reviewed];
          return result.take(reviewLimit + newLimit).toList();
        });

        final items = <String>[]; // All items seen across batches
        var currentIndex = 0;

        // --- Batch 1: initial fetch (reviewLimit=3, newLimit=0) ---
        final batch1 = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 3,
          newLimit: 0,
        );
        // Should get 3 cards
        expect(batch1.length, 3);
        items.addAll(batch1.map((i) => i.cardId));

        // "Review" first 2 cards (simulating user progress)
        for (var i = 0; i < 2; i++) {
          reviewedIds.add(items[currentIndex + i]);
        }
        currentIndex = 2; // User is on item index 2 (card-2)

        // --- Batch 2: prefetch with unreviewed tail as exclude ---
        // Unreviewed tail = items from currentIndex onwards = [card-2]
        final excludeIds1 = items.skip(currentIndex).toSet();
        final batch2 = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 3,
          newLimit: 0,
          excludeCardIds: excludeIds1,
        );
        items.addAll(batch2.map((i) => i.cardId));

        // Verify no duplicates - this is the critical invariant
        expect(
          items.toSet().length,
          items.length,
          reason: 'Batch 2 introduced duplicates',
        );
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
            mockDataService.getSessionCards(
              userId,
              reviewLimit: anyNamed('reviewLimit'),
              newLimit: anyNamed('newLimit'),
              excludeIds: anyNamed('excludeIds'),
            ),
          ).thenAnswer((invocation) async {
            final excludeIds = invocation.namedArguments[#excludeIds] as List? ?? [];
            final excludeSet = excludeIds.toSet();
            final reviewLimit = invocation.namedArguments[#reviewLimit] as int;
            final newLimit = invocation.namedArguments[#newLimit] as int;

            final unreviewed = allCards.where(
              (c) => !reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
            ).toList();
            final reviewed = allCards.where(
              (c) => reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
            ).toList();

            // Apply RPC limit
            final result = [...unreviewed, ...reviewed];
            return result.take(reviewLimit + newLimit).toList();
          });

          // Batch 1: fetch up to 3 review cards
          final batch1 = await planner.fetchBatch(
            userId: userId,
            reviewLimit: 3,
            newLimit: 0,
          );
          // All 12 cards are state=2 (reviews), should get 3
          expect(batch1.length, 3);
          final batch1Ids = batch1.map((i) => i.cardId).toList();

          // Review all cards from batch1
          for (final item in batch1) {
            reviewedIds.add(item.cardId);
          }

          // Batch 2: exclude set is empty (reviewed cards from batch1 are not in the queue anymore)
          // Reviewed cards sort last, so should get the next unreviewed cards first
          final batch2 = await planner.fetchBatch(
            userId: userId,
            reviewLimit: 3,
            newLimit: 0,
            excludeCardIds: <String>{}, // No unreviewed items to exclude
          );

          // Verify no duplicates with batch1
          final batch2Ids = batch2.map((i) => i.cardId).toSet();
          final batch1IdSet = batch1Ids.toSet();
          expect(batch2Ids.intersection(batch1IdSet), isEmpty,
              reason: 'Batch 2 should not contain reviewed cards from batch 1');
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
            mockDataService.getSessionCards(
              userId,
              reviewLimit: anyNamed('reviewLimit'),
              newLimit: anyNamed('newLimit'),
              excludeIds: anyNamed('excludeIds'),
            ),
          ).thenAnswer((invocation) async {
            final excludeIds = invocation.namedArguments[#excludeIds] as List? ?? [];
            final excludeSet = excludeIds.toSet();
            final reviewLimit = invocation.namedArguments[#reviewLimit] as int;
            final newLimit = invocation.namedArguments[#newLimit] as int;

            // DB returns: unreviewed first, reviewed last
            final unreviewed = allCards.where(
              (c) => !reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
            ).toList();
            final reviewed = allCards.where(
              (c) => reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
            ).toList();

            // Apply RPC limit
            final result = [...unreviewed, ...reviewed];
            return result.take(reviewLimit + newLimit).toList();
          });

          // Prefetch triggered at currentIndex=2 (just reviewed card-2).
          // Unreviewed tail in local _items = [card-3, card-4]
          final excludeIds = {'card-3', 'card-4'};

          final batch = await planner.fetchBatch(
            userId: userId,
            reviewLimit: 5,
            newLimit: 20,
            excludeCardIds: excludeIds,
          );

          // Core invariant: excluded cards should not appear in result
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
        ).thenAnswer((invocation) async {
          final excludeIds = invocation.namedArguments[#excludeIds] as List? ?? [];
          final excludeSet = excludeIds.toSet();
          final reviewLimit = invocation.namedArguments[#reviewLimit] as int;
          final newLimit = invocation.namedArguments[#newLimit] as int;

          final unreviewed = allCards.where(
            (c) => !reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
          ).toList();
          final reviewed = allCards.where(
            (c) => reviewedIds.contains(c['card_id']) && !excludeSet.contains(c['card_id']),
          ).toList();

          // Apply RPC limit
          final result = [...unreviewed, ...reviewed];
          return result.take(reviewLimit + newLimit).toList();
        });

        // Without exclude: fetch returns unreviewed cards first, then reviewed
        final batchNoExclude = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 5,
          newLimit: 20,
        );
        // All 6 cards are state=2 (reviews by default), should return up to reviewLimit=5
        expect(batchNoExclude.length, lessThanOrEqualTo(6));
        // Unreviewed cards (3,4,5) should come before reviewed cards (0,1,2)
        final idsNoExclude = batchNoExclude.map((i) => i.cardId).toList();
        final idx3 = idsNoExclude.indexOf('card-3');
        final idx0 = idsNoExclude.indexOf('card-0');
        if (idx3 >= 0 && idx0 >= 0) {
          expect(idx3, lessThan(idx0), reason: 'Unreviewed cards should come before reviewed');
        }

        // With exclude set {card-3, card-4} (unreviewed tail in local queue):
        final batchWithExclude = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 5,
          newLimit: 20,
          excludeCardIds: {'card-3', 'card-4'},
        );
        // Core invariant: excluded cards should not appear
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
          mockDataService.getSessionCards(
            userId,
            reviewLimit: anyNamed('reviewLimit'),
            newLimit: anyNamed('newLimit'),
            excludeIds: anyNamed('excludeIds'),
          ),
        ).thenAnswer((invocation) async {
          final excludeIds = invocation.namedArguments[#excludeIds] as List? ?? [];
          final excludeSet = excludeIds.toSet();
          final reviewLimit = invocation.namedArguments[#reviewLimit] as int;
          final newLimit = invocation.namedArguments[#newLimit] as int;

          final availableCards = allCards.where((c) => !excludeSet.contains(c['card_id'])).toList();

          // Separate review and new cards
          final reviews = availableCards.where((c) => c['state'] != 0).take(reviewLimit);
          final newCards = availableCards.where((c) => c['state'] == 0).take(newLimit);

          return [...reviews, ...newCards];
        });

        // Batch 1: reviewLimit=5 (up to 5 due cards), newLimit=3 (up to 3 new cards)
        final batch1 = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 5,
          newLimit: 3,
        );
        final newInBatch1 = batch1.where((i) => i.isNewWord).length;
        // RPC should respect newLimit
        expect(newInBatch1, lessThanOrEqualTo(3));

        // Batch 2: exclude batch1, use remaining newLimit budget
        final remainingNewLimit = 3 - newInBatch1;
        final batch2 = await planner.fetchBatch(
          userId: userId,
          reviewLimit: 5,
          newLimit: remainingNewLimit,
          excludeCardIds: batch1.map((i) => i.cardId).toSet(),
        );
        final newInBatch2 = batch2.where((i) => i.isNewWord).length;
        // RPC should respect the adjusted newLimit
        expect(newInBatch2, lessThanOrEqualTo(remainingNewLimit));

        // Total new words across both batches should equal original cap
        expect(newInBatch1 + newInBatch2, lessThanOrEqualTo(3));
      });
    });

    // =========================================================================
    // Near-Promotion Score
    // =========================================================================
    group('nearPromotionScore', () {
      SessionCard makeCard({
        int state = 2,
        int reps = 5,
        double stability = 10.0,
        int lapses = 0,
        int nonTranslationSuccessCount = 0,
        int? lapsesLast8,
        int? lapsesLast12,
        int? hardMethodSuccessCount,
      }) {
        return SessionCard.fromJson({
          'card_id': 'c1',
          'vocabulary_id': 'v1',
          'state': state,
          'due': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'stability': stability,
          'difficulty': 0.3,
          'reps': reps,
          'lapses': lapses,
          'last_review': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'is_leech': false,
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'word': 'test',
          'stem': 'tes',
          'english_definition': 'test def',
          'part_of_speech': 'noun',
          'synonyms': <String>[],
          'antonyms': <String>[],
          'confusables': <Map<String, dynamic>>[],
          'example_sentences': <Map<String, dynamic>>[],
          'translations': {
            'en': {'primary': 'test', 'alternatives': <String>[]},
          },
          'overrides': <String, dynamic>{},
          'has_confusables': false,
          'non_translation_success_count': nonTranslationSuccessCount,
          if (lapsesLast8 != null) 'lapses_last_8': lapsesLast8,
          if (lapsesLast12 != null) 'lapses_last_12': lapsesLast12,
          if (hardMethodSuccessCount != null) 'hard_method_success_count': hardMethodSuccessCount,
        });
      }

      test('returns 0.0 for new cards (state == 0)', () {
        final card = makeCard(state: 0, reps: 0, stability: 0.0);
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('returns 0.0 for cards far from any promotion threshold', () {
        // reps=1, state=1 (learning) — not near practicing→stabilizing
        final card = makeCard(state: 1, reps: 1, stability: 0.2);
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('scores practicing→stabilizing: state=2, stability>=0.5, lapsesLast8<=2', () {
        final card = makeCard(reps: 2, state: 2, stability: 0.8, lapses: 0);
        final score = planner.nearPromotionScore(card);
        expect(score, greaterThan(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('practicing→stabilizing: higher stability → higher score', () {
        final low = makeCard(reps: 2, state: 2, stability: 0.5, lapses: 0);
        final high = makeCard(reps: 2, state: 2, stability: 0.9, lapses: 0);
        expect(planner.nearPromotionScore(high), greaterThan(planner.nearPromotionScore(low)));
      });

      test('practicing→stabilizing: returns 0 when state != 2', () {
        final card = makeCard(reps: 2, state: 1, stability: 0.8, lapses: 0);
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('practicing→stabilizing: returns 0 when lapsesLast8 > 2', () {
        final card = makeCard(reps: 2, state: 2, stability: 0.8, lapsesLast8: 3);
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('practicing→stabilizing: returns 0 when stability < 0.5', () {
        final card = makeCard(reps: 2, state: 2, stability: 0.3, lapses: 0);
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('practicing→stabilizing uses windowed lapses: lifetime=5 but lapsesLast8=1', () {
        final card = makeCard(
          reps: 2, state: 2, stability: 0.8,
          lapses: 5, // lifetime high
          lapsesLast8: 1, // windowed low
        );
        final score = planner.nearPromotionScore(card);
        expect(score, greaterThan(0.0));
      });

      test('practicing→stabilizing blocked by lapsesLast8>2', () {
        final card = makeCard(
          reps: 2, state: 2, stability: 0.8,
          lapses: 0, // lifetime low
          lapsesLast8: 3, // windowed high
        );
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('stabilizing→known: returns 0.9 when stabilizing criteria met and nonTransSuccess=0', () {
        final card = makeCard(
          reps: 3, state: 2, stability: 1.0, lapses: 0,
          nonTranslationSuccessCount: 0,
        );
        expect(planner.nearPromotionScore(card), 0.9);
      });

      test('stabilizing→known: returns 0 when nonTransSuccess >= 1 (already promoted or not near)', () {
        final card = makeCard(
          reps: 3, state: 2, stability: 1.0, lapses: 0,
          nonTranslationSuccessCount: 1,
        );
        // With nonTransSuccess=1, the stabilizing→known gate is already met,
        // and this card won't match known→mastered thresholds either
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('known→mastered: scores when stability>=70, lapsesLast12<=1, state=2, hardMethodSuccess=0', () {
        final card = makeCard(
          reps: 5, state: 2, stability: 80.0,
          lapses: 0, lapsesLast12: 1,
          nonTranslationSuccessCount: 5,
          hardMethodSuccessCount: 0, // gate: one hard method success would unlock
        );
        final score = planner.nearPromotionScore(card);
        expect(score, greaterThan(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('known→mastered: already has hardMethodSuccess → returns 0', () {
        final card = makeCard(
          reps: 5, state: 2, stability: 80.0,
          lapses: 0, lapsesLast12: 0,
          nonTranslationSuccessCount: 5,
          hardMethodSuccessCount: 1, // already has it
        );
        // Card already meets the hardMethod gate, so it's either already Mastered
        // (if stability>=90) or just near-promo by stability alone — but the
        // near-promo logic requires hardMethodSuccessCount==0
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('known→mastered: higher stability → higher score', () {
        final low = makeCard(
          reps: 5, state: 2, stability: 70.0, lapses: 0,
          nonTranslationSuccessCount: 5, hardMethodSuccessCount: 0,
        );
        final high = makeCard(
          reps: 5, state: 2, stability: 89.0, lapses: 0,
          nonTranslationSuccessCount: 5, hardMethodSuccessCount: 0,
        );
        expect(planner.nearPromotionScore(high), greaterThan(planner.nearPromotionScore(low)));
      });

      test('known→mastered: returns 0 when stability < 70', () {
        final card = makeCard(
          reps: 5, state: 2, stability: 60.0, lapses: 0,
          nonTranslationSuccessCount: 5, hardMethodSuccessCount: 0,
        );
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('known→mastered: returns 0 when lapsesLast12 > 1', () {
        final card = makeCard(
          reps: 5, state: 2, stability: 80.0,
          lapses: 0, lapsesLast12: 2,
          nonTranslationSuccessCount: 5, hardMethodSuccessCount: 0,
        );
        expect(planner.nearPromotionScore(card), 0.0);
      });

      test('known→mastered: at exact stability threshold returns score ~1.0', () {
        final card = makeCard(
          reps: 5, state: 2, stability: 90.0, lapses: 0,
          nonTranslationSuccessCount: 5, hardMethodSuccessCount: 0,
        );
        expect(planner.nearPromotionScore(card), closeTo(1.0, 0.01));
      });
    });

    // =========================================================================
    // Bookend Ordering
    // =========================================================================
    group('applyBookendOrder', () {
      PlannedItem makeItem({
        required String id,
        int state = 2,
        int reps = 5,
        double stability = 10.0,
        double difficulty = 0.3,
        int lapses = 0,
        int nonTranslationSuccessCount = 1,
        int? hardMethodSuccessCount,
      }) {
        final card = SessionCard.fromJson({
          'card_id': id,
          'vocabulary_id': 'v-$id',
          'state': state,
          'due': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'stability': stability,
          'difficulty': difficulty,
          'reps': reps,
          'lapses': lapses,
          'last_review': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'is_leech': false,
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'word': 'word-$id',
          'stem': 'stem-$id',
          'english_definition': 'def $id',
          'part_of_speech': 'noun',
          'synonyms': <String>[],
          'antonyms': <String>[],
          'confusables': <Map<String, dynamic>>[],
          'example_sentences': <Map<String, dynamic>>[],
          'translations': {
            'en': {'primary': 'trans-$id', 'alternatives': <String>[]},
          },
          'overrides': <String, dynamic>{},
          'has_confusables': false,
          'non_translation_success_count': nonTranslationSuccessCount,
          if (hardMethodSuccessCount != null) 'hard_method_success_count': hardMethodSuccessCount,
        });
        return PlannedItem(
          sessionCard: card,
          interactionMode: 1,
          priority: state == 0 ? 0.0 : 1.0,
        );
      }

      test('returns empty list unchanged', () {
        final result = planner.applyBookendOrder([]);
        expect(result.ordered, isEmpty);
        expect(result.closer, isNull);
      });

      test('0 candidates: easiest card held as closer', () {
        // All cards are far from any promotion threshold
        final items = [
          makeItem(id: 'a', stability: 20.0, difficulty: 0.5),
          makeItem(id: 'b', stability: 50.0, difficulty: 0.3), // Easiest (highest stability, lowest diff)
          makeItem(id: 'c', stability: 30.0, difficulty: 0.4),
        ];

        final result = planner.applyBookendOrder(items);

        expect(result.closer, isNotNull);
        expect(result.closer!.cardId, 'b'); // Highest stability
        expect(result.ordered, hasLength(2));
        expect(result.ordered.map((i) => i.cardId), isNot(contains('b')));
      });

      test('0 candidates, stability tie: lower difficulty wins', () {
        final items = [
          makeItem(id: 'a', stability: 50.0, difficulty: 0.7),
          makeItem(id: 'b', stability: 50.0, difficulty: 0.2), // Lower difficulty
        ];

        final result = planner.applyBookendOrder(items);
        expect(result.closer!.cardId, 'b');
      });

      test('1 candidate: used as closer only', () {
        final nearPromo = makeItem(
          id: 'near',
          reps: 2, state: 2, stability: 0.8, lapses: 0,
          nonTranslationSuccessCount: 0,
        );
        final regular = makeItem(id: 'reg', stability: 10.0);

        final result = planner.applyBookendOrder([regular, nearPromo]);

        expect(result.closer!.cardId, 'near');
        expect(result.ordered, hasLength(1));
        expect(result.ordered[0].cardId, 'reg');
      });

      test('2 candidates: 1 opener + 1 closer', () {
        final np1 = makeItem(
          id: 'np1', reps: 2, state: 2, stability: 0.9, lapses: 0,
          nonTranslationSuccessCount: 0,
        );
        final np2 = makeItem(
          id: 'np2', reps: 2, state: 2, stability: 0.6, lapses: 0,
          nonTranslationSuccessCount: 0,
        );
        final reg = makeItem(id: 'reg', stability: 10.0);

        final result = planner.applyBookendOrder([reg, np1, np2]);

        // Best candidate (np1, higher score) → opener
        expect(result.ordered.first.cardId, 'np1');
        // Second candidate → closer
        expect(result.closer!.cardId, 'np2');
        // Regular card stays in ordered
        expect(result.ordered.map((i) => i.cardId), contains('reg'));
        expect(result.ordered, hasLength(2));
      });

      test('3+ candidates: 2 openers + 1 closer, rest in core', () {
        final np1 = makeItem(
          id: 'np1', reps: 5, state: 2, stability: 89.0, lapses: 0,
          nonTranslationSuccessCount: 5, hardMethodSuccessCount: 0,
        ); // known→mastered, high score (needs hardMethodSuccess=0 for near-promo)
        final np2 = makeItem(
          id: 'np2', reps: 3, state: 2, stability: 1.0, lapses: 0,
          nonTranslationSuccessCount: 0,
        ); // stabilizing→known, score=0.9
        final np3 = makeItem(
          id: 'np3', reps: 2, state: 2, stability: 0.8, lapses: 0,
          nonTranslationSuccessCount: 0,
        ); // practicing→stabilizing, lower score
        final np4 = makeItem(
          id: 'np4', reps: 2, state: 2, stability: 0.6, lapses: 0,
          nonTranslationSuccessCount: 0,
        ); // practicing→stabilizing, even lower
        final reg = makeItem(id: 'reg', stability: 10.0);

        final result = planner.applyBookendOrder([reg, np1, np2, np3, np4]);

        // Top 2 → openers (first two items)
        expect(result.ordered[0].cardId, 'np1');
        expect(result.ordered[1].cardId, 'np2');
        // 3rd candidate → closer
        expect(result.closer!.cardId, 'np3');
        // 4th candidate + regular → in ordered core
        final coreIds = result.ordered.skip(2).map((i) => i.cardId).toSet();
        expect(coreIds, contains('np4'));
        expect(coreIds, contains('reg'));
      });

      test('new words placed after openers', () {
        final np = makeItem(
          id: 'np', reps: 2, state: 2, stability: 0.8, lapses: 0,
          nonTranslationSuccessCount: 0,
        );
        final newWord = makeItem(id: 'new', state: 0, reps: 0, stability: 0.0);
        final reg = makeItem(id: 'reg', stability: 10.0);

        final result = planner.applyBookendOrder([reg, newWord, np]);

        // np → closer (only 1 candidate)
        expect(result.closer!.cardId, 'np');
        // New words should be in ordered list
        expect(result.ordered.map((i) => i.cardId).toList(), contains('new'));
      });

      test('preserves all items: ordered + closer = original count', () {
        final items = [
          makeItem(id: 'a', stability: 20.0),
          makeItem(id: 'b', stability: 30.0),
          makeItem(id: 'c', state: 0, reps: 0, stability: 0.0),
          makeItem(
            id: 'd', reps: 2, state: 2, stability: 0.8, lapses: 0,
            nonTranslationSuccessCount: 0,
          ),
          makeItem(
            id: 'e', reps: 3, state: 2, stability: 1.0, lapses: 0,
            nonTranslationSuccessCount: 0,
          ),
        ];

        final result = planner.applyBookendOrder(items);

        final totalCount = result.ordered.length + (result.closer != null ? 1 : 0);
        expect(totalCount, items.length);
      });

      test('no duplicates in output', () {
        final items = [
          makeItem(id: 'a', stability: 5.0),
          makeItem(id: 'b', stability: 30.0),
          makeItem(
            id: 'c', reps: 2, state: 2, stability: 0.8, lapses: 0,
            nonTranslationSuccessCount: 0,
          ),
          makeItem(
            id: 'd', reps: 3, state: 2, stability: 1.0, lapses: 0,
            nonTranslationSuccessCount: 0,
          ),
          makeItem(
            id: 'e', reps: 5, state: 2, stability: 80.0, lapses: 0,
            nonTranslationSuccessCount: 5, hardMethodSuccessCount: 0,
          ),
        ];

        final result = planner.applyBookendOrder(items);

        final allIds = result.ordered.map((i) => i.cardId).toList();
        if (result.closer != null) allIds.add(result.closer!.cardId);
        expect(allIds.toSet().length, allIds.length, reason: 'No duplicate card IDs');
      });

      test('single item: no candidate → item is closer (easiest)', () {
        final item = makeItem(id: 'only', stability: 10.0);
        final result = planner.applyBookendOrder([item]);

        // Single review item, no near-promotion → goes to closer as easiest
        expect(result.closer!.cardId, 'only');
        expect(result.ordered, isEmpty);
      });

      test('single near-promotion item: becomes closer', () {
        final np = makeItem(
          id: 'np', reps: 2, state: 2, stability: 0.8, lapses: 0,
          nonTranslationSuccessCount: 0,
        );
        final result = planner.applyBookendOrder([np]);

        expect(result.closer!.cardId, 'np');
        expect(result.ordered, isEmpty);
      });

      test('only new words: no closer (no review items)', () {
        final items = [
          makeItem(id: 'n1', state: 0, reps: 0, stability: 0.0),
          makeItem(id: 'n2', state: 0, reps: 0, stability: 0.0),
        ];
        final result = planner.applyBookendOrder(items);

        expect(result.closer, isNull);
        expect(result.ordered, hasLength(2));
      });

      test('near-mastered closer with confusables gets disambiguation cue', () {
        // Near-mastered card with hardMethodSuccessCount=0 and confusables
        final nearMastered = PlannedItem(
          sessionCard: SessionCard.fromJson({
            'card_id': 'nm',
            'vocabulary_id': 'v-nm',
            'state': 2,
            'due': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'stability': 80.0,
            'difficulty': 0.3,
            'reps': 5,
            'lapses': 0,
            'last_review': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'is_leech': false,
            'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'word': 'affect',
            'stem': 'affect',
            'english_definition': 'to influence',
            'part_of_speech': 'verb',
            'synonyms': <String>[],
            'antonyms': <String>[],
            'confusables': [
              {
                'word': 'effect',
                'disambiguation_sentence': {
                  'sentence': 'The decision will affect everyone.',
                  'before': 'The decision will ',
                  'blank': 'affect',
                  'after': ' everyone.',
                },
              },
            ],
            'example_sentences': <Map<String, dynamic>>[],
            'translations': {
              'en': {'primary': 'affect', 'alternatives': <String>[]},
            },
            'overrides': <String, dynamic>{},
            'has_confusables': true,
            'non_translation_success_count': 5,
            'lapses_last_12': 0,
            'hard_method_success_count': 0,
          }),
          interactionMode: 1,
          priority: 1.0,
          cueType: CueType.translation, // Originally assigned translation
        );
        final reg = makeItem(id: 'reg', stability: 10.0);

        final result = planner.applyBookendOrder([reg, nearMastered]);

        // nearMastered should be the closer (only 1 candidate)
        expect(result.closer!.cardId, 'nm');
        // And its cue type should be overridden to disambiguation
        expect(result.closer!.cueType, CueType.disambiguation);
      });

      test('near-known closer with translation cue gets non-translation cue', () {
        // Near-known card: meets stabilizing criteria but nonTransSuccess=0
        final nearKnown = PlannedItem(
          sessionCard: SessionCard.fromJson({
            'card_id': 'nk',
            'vocabulary_id': 'v-nk',
            'state': 2,
            'due': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'stability': 1.5,
            'difficulty': 0.3,
            'reps': 3,
            'lapses': 0,
            'last_review': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'is_leech': false,
            'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'word': 'ubiquitous',
            'stem': 'ubiquitous',
            'english_definition': 'present everywhere',
            'part_of_speech': 'adjective',
            'synonyms': ['omnipresent', 'pervasive'],
            'antonyms': <String>[],
            'confusables': <Map<String, dynamic>>[],
            'example_sentences': <Map<String, dynamic>>[],
            'translations': {
              'en': {'primary': 'ubiquitous', 'alternatives': <String>[]},
            },
            'overrides': <String, dynamic>{},
            'has_confusables': false,
            'non_translation_success_count': 0,
          }),
          interactionMode: 1,
          priority: 1.0,
          cueType: CueType.translation, // Originally assigned translation
        );
        final reg = makeItem(id: 'reg3', stability: 10.0);

        final result = planner.applyBookendOrder([reg, nearKnown]);

        expect(result.closer!.cardId, 'nk');
        // Should be overridden to a non-translation cue (synonym available)
        expect(result.closer!.cueType, CueType.synonym);
      });

      test('near-known closer with non-translation cue keeps it', () {
        // Near-known card already has a non-translation cue — no override needed
        final nearKnown = PlannedItem(
          sessionCard: SessionCard.fromJson({
            'card_id': 'nk2',
            'vocabulary_id': 'v-nk2',
            'state': 2,
            'due': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'stability': 1.5,
            'difficulty': 0.3,
            'reps': 3,
            'lapses': 0,
            'last_review': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'is_leech': false,
            'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'word': 'ubiquitous',
            'stem': 'ubiquitous',
            'english_definition': 'present everywhere',
            'part_of_speech': 'adjective',
            'synonyms': ['omnipresent'],
            'antonyms': <String>[],
            'confusables': <Map<String, dynamic>>[],
            'example_sentences': <Map<String, dynamic>>[],
            'translations': {
              'en': {'primary': 'ubiquitous', 'alternatives': <String>[]},
            },
            'overrides': <String, dynamic>{},
            'has_confusables': false,
            'non_translation_success_count': 0,
          }),
          interactionMode: 1,
          priority: 1.0,
          cueType: CueType.definition, // Already non-translation
        );
        final reg = makeItem(id: 'reg4', stability: 10.0);

        final result = planner.applyBookendOrder([reg, nearKnown]);

        expect(result.closer!.cardId, 'nk2');
        // Already has non-translation cue, no override
        expect(result.closer!.cueType, CueType.definition);
      });

      test('near-mastered bookend without confusables keeps original cue', () {
        // Near-mastered card but no confusables — can't do disambiguation
        final nearMastered = PlannedItem(
          sessionCard: SessionCard.fromJson({
            'card_id': 'nm2',
            'vocabulary_id': 'v-nm2',
            'state': 2,
            'due': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'stability': 80.0,
            'difficulty': 0.3,
            'reps': 5,
            'lapses': 0,
            'last_review': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'is_leech': false,
            'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'word': 'house',
            'stem': 'house',
            'english_definition': 'a building',
            'part_of_speech': 'noun',
            'synonyms': <String>[],
            'antonyms': <String>[],
            'confusables': <Map<String, dynamic>>[],
            'example_sentences': <Map<String, dynamic>>[],
            'translations': {
              'en': {'primary': 'house', 'alternatives': <String>[]},
            },
            'overrides': <String, dynamic>{},
            'has_confusables': false,
            'non_translation_success_count': 5,
            'lapses_last_12': 0,
            'hard_method_success_count': 0,
          }),
          interactionMode: 1,
          priority: 1.0,
          cueType: CueType.translation,
        );
        final reg = makeItem(id: 'reg2', stability: 10.0);

        final result = planner.applyBookendOrder([reg, nearMastered]);

        expect(result.closer!.cardId, 'nm2');
        // No confusables → keep original cue
        expect(result.closer!.cueType, CueType.translation);
      });
    });
  });
}
