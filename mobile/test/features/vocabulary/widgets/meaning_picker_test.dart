import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/meaning_picker.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MeaningPickerScreen', () {
    testWidgets('shows title and subtitle', (tester) async {
      await tester.pumpTestWidget(
        MeaningPickerScreen(
          meanings: const [
            MeaningOption(
              meaningId: 'm1',
              primaryTranslation: 'Ufer (Flussufer)',
              englishDefinition: 'The side of a river.',
              isRecommended: true,
            ),
            MeaningOption(
              meaningId: 'm2',
              primaryTranslation: 'Bank (Geldinstitut)',
              englishDefinition: 'A financial institution.',
              isRecommended: false,
            ),
          ],
          onSelect: (_) {},
        ),
      );

      expect(
        find.text('Which meaning do you want to learn first?'),
        findsOneWidget,
      );
      expect(
        find.text('You can learn the others later.'),
        findsOneWidget,
      );
    });

    testWidgets('shows all meaning options', (tester) async {
      await tester.pumpTestWidget(
        MeaningPickerScreen(
          meanings: const [
            MeaningOption(
              meaningId: 'm1',
              primaryTranslation: 'Ufer (Flussufer)',
              englishDefinition: 'The side of a river.',
              isRecommended: true,
            ),
            MeaningOption(
              meaningId: 'm2',
              primaryTranslation: 'Bank (Geldinstitut)',
              englishDefinition: 'A financial institution.',
              isRecommended: false,
            ),
          ],
          onSelect: (_) {},
        ),
      );

      expect(find.text('Ufer (Flussufer)'), findsOneWidget);
      expect(find.text('The side of a river.'), findsOneWidget);
      expect(find.text('Bank (Geldinstitut)'), findsOneWidget);
      expect(find.text('A financial institution.'), findsOneWidget);
    });

    testWidgets('shows recommended badge on first meaning', (tester) async {
      await tester.pumpTestWidget(
        MeaningPickerScreen(
          meanings: const [
            MeaningOption(
              meaningId: 'm1',
              primaryTranslation: 'Ufer',
              englishDefinition: 'River bank.',
              isRecommended: true,
            ),
            MeaningOption(
              meaningId: 'm2',
              primaryTranslation: 'Bank',
              englishDefinition: 'Financial institution.',
              isRecommended: false,
            ),
          ],
          onSelect: (_) {},
        ),
      );

      expect(find.text('Recommended'), findsOneWidget);
    });

    testWidgets('calls onSelect with meaning ID on tap', (tester) async {
      String? selectedId;

      await tester.pumpTestWidget(
        MeaningPickerScreen(
          meanings: const [
            MeaningOption(
              meaningId: 'm1',
              primaryTranslation: 'Ufer',
              englishDefinition: 'River bank.',
              isRecommended: true,
            ),
            MeaningOption(
              meaningId: 'm2',
              primaryTranslation: 'Bank',
              englishDefinition: 'Financial institution.',
              isRecommended: false,
            ),
          ],
          onSelect: (id) => selectedId = id,
        ),
      );

      // Tap "Start with this" button for second option
      final startButtons = find.text('Start with this');
      expect(startButtons, findsNWidgets(2));

      await tester.tap(startButtons.at(1));
      await tester.pumpAndSettle();

      expect(selectedId, 'm2');
    });

    testWidgets('selects first meaning on tap', (tester) async {
      String? selectedId;

      await tester.pumpTestWidget(
        MeaningPickerScreen(
          meanings: const [
            MeaningOption(
              meaningId: 'm1',
              primaryTranslation: 'Ufer',
              englishDefinition: 'River bank.',
              isRecommended: true,
            ),
            MeaningOption(
              meaningId: 'm2',
              primaryTranslation: 'Bank',
              englishDefinition: 'Financial institution.',
              isRecommended: false,
            ),
          ],
          onSelect: (id) => selectedId = id,
        ),
      );

      final startButtons = find.text('Start with this');
      await tester.tap(startButtons.first);
      await tester.pumpAndSettle();

      expect(selectedId, 'm1');
    });
  });
}
