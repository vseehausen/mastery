import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/field_feedback.dart';
import 'package:mastery/providers/supabase_provider.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../domain/services/session_planner_test.mocks.dart';

void main() {
  group('FieldFeedback', () {
    late MockSupabaseDataService mockDataService;

    setUp(() {
      mockDataService = MockSupabaseDataService();
      // Default stub for createEnrichmentFeedback
      when(
        mockDataService.createEnrichmentFeedback(
          userId: anyNamed('userId'),
          meaningId: anyNamed('meaningId'),
          fieldName: anyNamed('fieldName'),
          rating: anyNamed('rating'),
          flagCategory: anyNamed('flagCategory'),
        ),
      ).thenAnswer((_) async => Future<void>.value());
    });

    testWidgets('displays thumbs up, thumbs down, and flag icons', (
      tester,
    ) async {
      await tester.pumpTestWidget(
        const FieldFeedback(
          meaningId: 'meaning-1',
          fieldName: 'translation',
          userId: 'user-1',
        ),
      );

      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('shows filled thumb up when rated up', (tester) async {
      await tester.pumpTestWidget(
        const FieldFeedback(
          meaningId: 'meaning-1',
          fieldName: 'translation',
          userId: 'user-1',
          existingFeedback: {'rating': 'up'},
        ),
      );

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
    });

    testWidgets('shows filled thumb down when rated down', (tester) async {
      await tester.pumpTestWidget(
        const FieldFeedback(
          meaningId: 'meaning-1',
          fieldName: 'translation',
          userId: 'user-1',
          existingFeedback: {'rating': 'down'},
        ),
      );

      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsNothing);
    });

    testWidgets('flag icon tap opens bottom sheet with all 6 categories', (
      tester,
    ) async {
      // Set surface size to avoid overflow in bottom sheet
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpTestWidget(
        const FieldFeedback(
          meaningId: 'meaning-1',
          fieldName: 'translation',
          userId: 'user-1',
        ),
      );

      // Tap the flag icon
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      // Verify bottom sheet title
      expect(find.text('Report Issue'), findsOneWidget);
      expect(find.text('What\'s wrong with this translation?'), findsOneWidget);

      // Verify all 6 categories are present
      expect(find.text('Wrong Translation'), findsOneWidget);
      expect(find.text('Inaccurate Definition'), findsOneWidget);
      expect(find.text('Bad Synonyms'), findsOneWidget);
      expect(find.text('Wrong Part of Speech'), findsOneWidget);
      expect(find.text('Missing Context'), findsOneWidget);
      expect(find.text('Confusables Wrong'), findsOneWidget);

      // Verify cancel button
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('selecting a category from flag sheet closes it', (
      tester,
    ) async {
      // Set surface size to avoid overflow in bottom sheet
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpTestWidget(
        const FieldFeedback(
          meaningId: 'meaning-1',
          fieldName: 'translation',
          userId: 'user-1',
        ),
        overrides: [
          supabaseDataServiceProvider.overrideWithValue(mockDataService),
        ],
      );

      // Tap the flag icon to open bottom sheet
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      // Verify bottom sheet is open
      expect(find.text('Report Issue'), findsOneWidget);

      // Tap a category
      await tester.tap(find.text('Wrong Translation'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is closed
      expect(find.text('Report Issue'), findsNothing);
    });

    testWidgets('cancel button in flag sheet closes it', (tester) async {
      // Set surface size to avoid overflow in bottom sheet
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpTestWidget(
        const FieldFeedback(
          meaningId: 'meaning-1',
          fieldName: 'translation',
          userId: 'user-1',
        ),
        overrides: [
          supabaseDataServiceProvider.overrideWithValue(mockDataService),
        ],
      );

      // Tap the flag icon to open bottom sheet
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      // Verify bottom sheet is open
      expect(find.text('Report Issue'), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is closed
      expect(find.text('Report Issue'), findsNothing);
    });
  });
}
