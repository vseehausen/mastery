import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/domain/models/progress_stage.dart';
import 'package:mastery/domain/models/session_progress_summary.dart';
import 'package:mastery/domain/models/stage_transition.dart';

void main() {
  group('SessionProgressSummary', () {
    final timestamp = DateTime(2026, 2, 8, 10, 30);

    group('counts', () {
      test('counts stabilizing transitions correctly', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: ProgressStage.practicing,
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            fromStage: ProgressStage.practicing,
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.stabilizingCount, 2);
        expect(summary.knownCount, 0);
        expect(summary.masteredCount, 0);
      });

      test('counts known transitions correctly', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: ProgressStage.stabilizing,
            toStage: ProgressStage.known,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.stabilizingCount, 0);
        expect(summary.knownCount, 1);
        expect(summary.masteredCount, 0);
      });

      test('counts mastered transitions correctly', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: ProgressStage.known,
            toStage: ProgressStage.mastered,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.stabilizingCount, 0);
        expect(summary.knownCount, 0);
        expect(summary.masteredCount, 1);
      });

      test('counts mixed transitions correctly', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: ProgressStage.practicing,
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            fromStage: ProgressStage.stabilizing,
            toStage: ProgressStage.known,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '3',
            wordText: 'word3',
            fromStage: ProgressStage.practicing,
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.stabilizingCount, 2);
        expect(summary.knownCount, 1);
        expect(summary.masteredCount, 0);
      });

      test('ignores other stage transitions', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: null,
            toStage: ProgressStage.captured,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            fromStage: ProgressStage.captured,
            toStage: ProgressStage.practicing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.stabilizingCount, 0);
        expect(summary.knownCount, 0);
        expect(summary.masteredCount, 0);
      });
    });

    group('hasTransitions', () {
      test('returns true when transitions exist', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.hasTransitions, true);
      });

      test('returns false when no transitions', () {
        const summary = SessionProgressSummary.empty();

        expect(summary.hasTransitions, false);
      });
    });

    group('hasRareAchievements', () {
      test('returns true for known transitions', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.known,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.hasRareAchievements, true);
      });

      test('returns true for mastered transitions', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.mastered,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.hasRareAchievements, true);
      });

      test('returns false for only stabilizing transitions', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.hasRareAchievements, false);
      });

      test('returns false when no transitions', () {
        const summary = SessionProgressSummary.empty();

        expect(summary.hasRareAchievements, false);
      });
    });

    group('toDisplayString', () {
      test('formats single stabilizing transition correctly', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.toDisplayString(), '1 word → Stabilizing');
      });

      test('formats multiple stabilizing transitions with plural', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.toDisplayString(), '2 words → Stabilizing');
      });

      test('formats mixed transitions with separator', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '3',
            wordText: 'word3',
            toStage: ProgressStage.known,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(
          summary.toDisplayString(),
          '2 words → Stabilizing • 1 word → Known',
        );
      });

      test('formats all three types correctly', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            toStage: ProgressStage.known,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '3',
            wordText: 'word3',
            toStage: ProgressStage.mastered,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(
          summary.toDisplayString(),
          '1 word → Stabilizing • 1 word → Known • 1 word → Mastered',
        );
      });

      test('returns empty string when no transitions', () {
        const summary = SessionProgressSummary.empty();

        expect(summary.toDisplayString(), '');
      });

      test('ignores non-significant transitions', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            toStage: ProgressStage.captured,
            timestamp: timestamp,
          ),
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            toStage: ProgressStage.practicing,
            timestamp: timestamp,
          ),
        ];

        final summary = SessionProgressSummary(transitions);

        expect(summary.toDisplayString(), '');
      });
    });

    group('empty constructor', () {
      test('creates summary with no transitions', () {
        const summary = SessionProgressSummary.empty();

        expect(summary.transitions, isEmpty);
        expect(summary.hasTransitions, false);
        expect(summary.stabilizingCount, 0);
        expect(summary.knownCount, 0);
        expect(summary.masteredCount, 0);
      });
    });

    group('equality', () {
      test('two summaries with same transitions are equal', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: ProgressStage.practicing,
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary1 = SessionProgressSummary(transitions);
        final summary2 = SessionProgressSummary(transitions);

        expect(summary1 == summary2, true);
      });

      test('two summaries with different transitions are not equal', () {
        final summary1 = SessionProgressSummary([
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: ProgressStage.practicing,
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ]);
        final summary2 = SessionProgressSummary([
          StageTransition(
            vocabularyId: '2',
            wordText: 'word2',
            fromStage: ProgressStage.stabilizing,
            toStage: ProgressStage.known,
            timestamp: timestamp,
          ),
        ]);

        expect(summary1 == summary2, false);
      });

      test('hashCode is consistent for equal objects', () {
        final transitions = [
          StageTransition(
            vocabularyId: '1',
            wordText: 'word1',
            fromStage: ProgressStage.practicing,
            toStage: ProgressStage.stabilizing,
            timestamp: timestamp,
          ),
        ];

        final summary1 = SessionProgressSummary(transitions);
        final summary2 = SessionProgressSummary(transitions);

        expect(summary1.hashCode, summary2.hashCode);
      });

      test('empty summaries are equal', () {
        const summary1 = SessionProgressSummary.empty();
        const summary2 = SessionProgressSummary.empty();

        expect(summary1 == summary2, true);
        expect(summary1.hashCode, summary2.hashCode);
      });
    });
  });
}
