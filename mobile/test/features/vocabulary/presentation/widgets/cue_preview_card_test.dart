import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/cue_preview_card.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('CuePreviewCard', () {
    testWidgets('renders translation cue', (tester) async {
      final cue = {
        'cue_type': 'translation',
        'prompt_text': 'Translate: Gehen Sie zum Bahnhof.',
        'answer_text': 'Go to the train station.',
      };

      await tester.pumpTestWidget(CuePreviewCard(cue: cue));

      expect(find.text('Translation'), findsOneWidget);
      expect(find.text('Translate: Gehen Sie zum Bahnhof.'), findsOneWidget);
      expect(find.text('Go to the train station.'), findsOneWidget);
    });

    testWidgets('renders definition cue', (tester) async {
      final cue = {
        'cue_type': 'definition',
        'prompt_text': 'What does "bahnhof" mean?',
        'answer_text': 'train station',
      };

      await tester.pumpTestWidget(CuePreviewCard(cue: cue));

      expect(find.text('Definition'), findsOneWidget);
      expect(find.text('What does "bahnhof" mean?'), findsOneWidget);
      expect(find.text('train station'), findsOneWidget);
    });

    testWidgets('renders synonym cue', (tester) async {
      final cue = {
        'cue_type': 'synonym',
        'prompt_text': 'Give a synonym for "schnell"',
        'answer_text': 'rasch',
      };

      await tester.pumpTestWidget(CuePreviewCard(cue: cue));

      expect(find.text('Synonym'), findsOneWidget);
      expect(find.text('Give a synonym for "schnell"'), findsOneWidget);
      expect(find.text('rasch'), findsOneWidget);
    });

    testWidgets('renders cloze cue', (tester) async {
      final cue = {
        'cue_type': 'cloze',
        'prompt_text': 'Complete: Der ___ ist groß.',
        'answer_text': 'Bahnhof',
      };

      await tester.pumpTestWidget(CuePreviewCard(cue: cue));

      expect(find.text('Fill in the Blank'), findsOneWidget);
      expect(find.text('Complete: Der ___ ist groß.'), findsOneWidget);
      expect(find.text('Bahnhof'), findsOneWidget);
    });

    testWidgets('renders multiple_choice cue', (tester) async {
      final cue = {
        'cue_type': 'multiple_choice',
        'prompt_text': 'Which word fits: ___ nach Berlin',
        'answer_text': 'Fahren',
      };

      await tester.pumpTestWidget(CuePreviewCard(cue: cue));

      expect(find.text('Choose the Word'), findsOneWidget);
      expect(find.text('Which word fits: ___ nach Berlin'), findsOneWidget);
      expect(find.text('Fahren'), findsOneWidget);
    });
  });
}
