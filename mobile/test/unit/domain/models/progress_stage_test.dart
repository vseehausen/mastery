import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/color_tokens.dart';
import 'package:mastery/domain/models/progress_stage.dart';

void main() {
  group('ProgressStage', () {
    group('displayName', () {
      test('returns correct display names for all stages', () {
        expect(ProgressStage.captured.displayName, 'New');
        expect(ProgressStage.practicing.displayName, 'Practicing');
        expect(ProgressStage.stabilizing.displayName, 'Stabilizing');
        expect(ProgressStage.known.displayName, 'Known');
        expect(ProgressStage.mastered.displayName, 'Mastered');
      });
    });

    group('getColor', () {
      late MasteryColorScheme lightColors;

      setUp(() {
        lightColors = MasteryColorScheme.light;
      });

      test('captured uses stageNew', () {
        final color = ProgressStage.captured.getColor(lightColors);
        expect(color, lightColors.stageNew);
      });

      test('practicing uses stagePracticing', () {
        final color = ProgressStage.practicing.getColor(lightColors);
        expect(color, lightColors.stagePracticing);
      });

      test('stabilizing uses stageStabilizing', () {
        final color = ProgressStage.stabilizing.getColor(lightColors);
        expect(color, lightColors.stageStabilizing);
      });

      test('active uses stageKnown', () {
        final color = ProgressStage.known.getColor(lightColors);
        expect(color, lightColors.stageKnown);
      });

      test('mastered uses stageMastered', () {
        final color = ProgressStage.mastered.getColor(lightColors);
        expect(color, lightColors.stageMastered);
      });
    });

    group('fromString', () {
      test('parses all valid stage names (lowercase)', () {
        expect(ProgressStage.fromString('new'), ProgressStage.captured);
        expect(ProgressStage.fromString('captured'), ProgressStage.captured);
        expect(
          ProgressStage.fromString('practicing'),
          ProgressStage.practicing,
        );
        expect(
          ProgressStage.fromString('stabilizing'),
          ProgressStage.stabilizing,
        );
        expect(ProgressStage.fromString('active'), ProgressStage.known);
        expect(ProgressStage.fromString('mastered'), ProgressStage.mastered);
      });

      test('parses mixed case strings', () {
        expect(ProgressStage.fromString('New'), ProgressStage.captured);
        expect(
          ProgressStage.fromString('PRACTICING'),
          ProgressStage.practicing,
        );
        expect(
          ProgressStage.fromString('Stabilizing'),
          ProgressStage.stabilizing,
        );
        expect(ProgressStage.fromString('KNOWN'), ProgressStage.known);
      });

      test('throws ArgumentError for invalid string', () {
        expect(() => ProgressStage.fromString('invalid'), throwsArgumentError);
        expect(() => ProgressStage.fromString(''), throwsArgumentError);
        expect(
          () => ProgressStage.fromString('clarified'), // old stage name
          throwsArgumentError,
        );
      });
    });

    group('toDbString', () {
      test('returns lowercase stage name for all stages', () {
        expect(ProgressStage.captured.toDbString(), 'new');
        expect(ProgressStage.practicing.toDbString(), 'practicing');
        expect(ProgressStage.stabilizing.toDbString(), 'stabilizing');
        expect(ProgressStage.known.toDbString(), 'known');
        expect(ProgressStage.mastered.toDbString(), 'mastered');
      });

      test('round-trip serialization works correctly', () {
        for (final stage in ProgressStage.values) {
          final serialized = stage.toDbString();
          final deserialized = ProgressStage.fromString(serialized);
          expect(deserialized, stage);
        }
      });
    });
  });
}
