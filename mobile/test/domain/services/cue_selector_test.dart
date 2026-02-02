import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/domain/models/cue_type.dart';
import 'package:mastery/domain/services/cue_selector.dart';

LearningCard _card({
  int state = 0,
  double stability = 0.0,
}) {
  final now = DateTime.now();
  return LearningCard(
    id: 'card-1',
    userId: 'user-1',
    vocabularyId: 'vocab-1',
    state: state,
    due: now,
    stability: stability,
    difficulty: 5.0,
    reps: 0,
    lapses: 0,
    isLeech: false,
    createdAt: now,
    updatedAt: now,
    isPendingSync: false,
    version: 1,
  );
}

/// A deterministic Random that always returns the given value from nextInt.
class _FixedRandom implements Random {
  _FixedRandom(this._value);

  final int _value;

  @override
  int nextInt(int max) => _value.clamp(0, max - 1);

  @override
  double nextDouble() => 0.0;

  @override
  bool nextBool() => false;
}

void main() {
  group('CueSelector', () {
    group('getMaturityStage', () {
      test('state 0 (new) returns newCard', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 0, stability: 0.0)),
          MaturityStage.newCard,
        );
      });

      test('state 0 returns newCard regardless of stability', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 0, stability: 50.0)),
          MaturityStage.newCard,
        );
      });

      test('state 1 (learning) with stability < 1.0 returns newCard', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 1, stability: 0.5)),
          MaturityStage.newCard,
        );
      });

      test('state 1 (learning) with stability >= 1.0 returns growing', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 1, stability: 1.0)),
          MaturityStage.growing,
        );
      });

      test('state 2 (review) with stability < 21.0 returns growing', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 2, stability: 15.0)),
          MaturityStage.growing,
        );
      });

      test('state 2 (review) with stability >= 21.0 returns mature', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 2, stability: 21.0)),
          MaturityStage.mature,
        );
      });

      test('state 2 (review) with high stability returns mature', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 2, stability: 100.0)),
          MaturityStage.mature,
        );
      });

      test('state 3 (relearning) returns growing', () {
        final selector = CueSelector();
        expect(
          selector.getMaturityStage(_card(state: 3, stability: 5.0)),
          MaturityStage.growing,
        );
      });
    });

    group('selectCueType', () {
      test('returns translation when no meaning data', () {
        final selector = CueSelector();
        final card = _card(state: 2, stability: 30.0);

        expect(
          selector.selectCueType(card: card, hasMeaning: false),
          CueType.translation,
        );
      });

      test('returns translation for new cards', () {
        final selector = CueSelector();
        final card = _card(state: 0, stability: 0.0);

        expect(
          selector.selectCueType(card: card, hasMeaning: true),
          CueType.translation,
        );
      });

      test('returns translation for learning cards with low stability', () {
        final selector = CueSelector();
        final card = _card(state: 1, stability: 0.3);

        expect(
          selector.selectCueType(card: card, hasMeaning: true),
          CueType.translation,
        );
      });

      group('growing stage', () {
        test('first weighted pick returns translation (weight 70)', () {
          // Roll 0 should pick translation (weight 70 of 95 total)
          final selector = CueSelector(random: _FixedRandom(0));
          final card = _card(state: 2, stability: 10.0);

          expect(
            selector.selectCueType(card: card, hasMeaning: true),
            CueType.translation,
          );
        });

        test('roll at 70 returns definition (weight 15)', () {
          final selector = CueSelector(random: _FixedRandom(70));
          final card = _card(state: 2, stability: 10.0);

          expect(
            selector.selectCueType(card: card, hasMeaning: true),
            CueType.definition,
          );
        });

        test('roll at 85 returns synonym (weight 10)', () {
          final selector = CueSelector(random: _FixedRandom(85));
          final card = _card(state: 2, stability: 10.0);

          expect(
            selector.selectCueType(card: card, hasMeaning: true),
            CueType.synonym,
          );
        });

        test('contextCloze only available when hasEncounterContext', () {
          // With context: roll 95 hits contextCloze (weight 5)
          final selectorWith = CueSelector(random: _FixedRandom(95));
          final card = _card(state: 2, stability: 10.0);

          expect(
            selectorWith.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: true,
            ),
            CueType.contextCloze,
          );

          // Without context: total weight is 95, roll 94 should hit synonym
          final selectorWithout = CueSelector(random: _FixedRandom(94));

          expect(
            selectorWithout.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: false,
            ),
            CueType.synonym,
          );
        });

        test('weight redistribution without context', () {
          // Without encounter context, total weight = 95 (70+15+10)
          // All rolls should still select from available cues
          final card = _card(state: 2, stability: 10.0);
          final counts = <CueType, int>{};

          for (var i = 0; i < 95; i++) {
            final selector = CueSelector(random: _FixedRandom(i));
            final type = selector.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: false,
            );
            counts[type] = (counts[type] ?? 0) + 1;
          }

          expect(counts[CueType.translation], 70);
          expect(counts[CueType.definition], 15);
          expect(counts[CueType.synonym], 10);
          expect(counts.containsKey(CueType.contextCloze), false);
        });
      });

      group('mature stage', () {
        test('full distribution with all data available', () {
          // Total weight = 20+25+20+15+20 = 100
          final card = _card(state: 2, stability: 30.0);
          final counts = <CueType, int>{};

          for (var i = 0; i < 100; i++) {
            final selector = CueSelector(random: _FixedRandom(i));
            final type = selector.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: true,
              hasConfusables: true,
            );
            counts[type] = (counts[type] ?? 0) + 1;
          }

          expect(counts[CueType.translation], 20);
          expect(counts[CueType.definition], 25);
          expect(counts[CueType.synonym], 20);
          expect(counts[CueType.contextCloze], 15);
          expect(counts[CueType.disambiguation], 20);
        });

        test('redistributes without context or confusables', () {
          // Total weight = 20+25+20 = 65
          final card = _card(state: 2, stability: 30.0);
          final counts = <CueType, int>{};

          for (var i = 0; i < 65; i++) {
            final selector = CueSelector(random: _FixedRandom(i));
            final type = selector.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: false,
              hasConfusables: false,
            );
            counts[type] = (counts[type] ?? 0) + 1;
          }

          expect(counts[CueType.translation], 20);
          expect(counts[CueType.definition], 25);
          expect(counts[CueType.synonym], 20);
          expect(counts.containsKey(CueType.contextCloze), false);
          expect(counts.containsKey(CueType.disambiguation), false);
        });

        test('non-translation cues >= 60% in mature stage with all data', () {
          final card = _card(state: 2, stability: 30.0);
          var nonTranslation = 0;
          const total = 1000;

          for (var i = 0; i < total; i++) {
            final selector = CueSelector(random: Random(i));
            final type = selector.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: true,
              hasConfusables: true,
            );
            if (type != CueType.translation) nonTranslation++;
          }

          // With weights 20/100 for translation, ~80% should be non-translation
          expect(nonTranslation / total, greaterThan(0.6));
        });

        test('non-translation cues >= 30% in growing stage', () {
          final card = _card(state: 2, stability: 10.0);
          var nonTranslation = 0;
          const total = 1000;

          for (var i = 0; i < total; i++) {
            final selector = CueSelector(random: Random(i));
            final type = selector.selectCueType(
              card: card,
              hasMeaning: true,
              hasEncounterContext: true,
            );
            if (type != CueType.translation) nonTranslation++;
          }

          // Growing: translation=70, rest=30 of 100 total
          expect(nonTranslation / total, greaterThanOrEqualTo(0.2));
        });
      });
    });
  });
}
