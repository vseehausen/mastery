import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/vocabulary/presentation/widgets/dev_info_panel.dart';
import 'package:mastery/providers/dev_mode_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('DevInfoPanel', () {
    testWidgets('returns SizedBox.shrink() when dev mode is false',
        (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
        'created_at': '2026-01-15T10:30:00Z',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
      );

      // Should not render DEV badge or any content
      expect(find.text('DEV'), findsNothing);
      expect(find.text('Confidence'), findsNothing);
      expect(find.text('95%'), findsNothing);
    });

    testWidgets('shows DEV label when dev mode is true', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('DEV'), findsOneWidget);
    });

    testWidgets('shows confidence as percentage', (tester) async {
      final meaning = {
        'confidence': 0.87,
        'source': 'ai',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Confidence'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('defaults confidence to 100% when null', (tester) async {
      final meaning = {
        'source': 'ai',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Confidence'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('shows source text', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'manual',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Source'), findsOneWidget);
      expect(find.text('manual'), findsOneWidget);
    });

    testWidgets('defaults source to "ai" when null', (tester) async {
      final meaning = {
        'confidence': 0.95,
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Source'), findsOneWidget);
      expect(find.text('ai'), findsOneWidget);
    });

    testWidgets('shows formatted created_at timestamp', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
        'created_at': '2026-01-15T10:30:00Z',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Created'), findsOneWidget);
      // DateFormat pattern: 'MMM d, yyyy HH:mm'
      expect(find.textContaining('Jan 15, 2026'), findsOneWidget);
    });

    testWidgets('shows formatted updated_at timestamp', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
        'updated_at': '2026-02-06T14:45:30Z',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Updated'), findsOneWidget);
      expect(find.textContaining('Feb 6, 2026'), findsOneWidget);
    });

    testWidgets('handles missing timestamps gracefully', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      // Should not show timestamp labels if not provided
      expect(find.text('Created'), findsNothing);
      expect(find.text('Updated'), findsNothing);
    });

    testWidgets('handles invalid timestamp strings gracefully',
        (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
        'created_at': 'invalid-date',
        'updated_at': 'also-invalid',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      // Should not show timestamp labels if parsing failed
      expect(find.text('Created'), findsNothing);
      expect(find.text('Updated'), findsNothing);
    });

    testWidgets('shows queue status when provided', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
      };
      final queueStatus = {
        'status': 'pending',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(
          meaning: meaning,
          queueStatus: queueStatus,
        ),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Queue Status'), findsOneWidget);
      expect(find.text('pending'), findsOneWidget);
    });

    testWidgets('shows queue position when provided', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
      };
      final queueStatus = {
        'status': 'queued',
        'position': 3,
      };

      await tester.pumpTestWidget(
        DevInfoPanel(
          meaning: meaning,
          queueStatus: queueStatus,
        ),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Queue Status'), findsOneWidget);
      expect(find.text('queued'), findsOneWidget);
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('defaults queue status to "unknown" when missing',
        (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
      };
      final queueStatus = <String, dynamic>{};

      await tester.pumpTestWidget(
        DevInfoPanel(
          meaning: meaning,
          queueStatus: queueStatus,
        ),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Queue Status'), findsOneWidget);
      expect(find.text('unknown'), findsOneWidget);
    });

    testWidgets('hides queue status when null', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Queue Status'), findsNothing);
      expect(find.text('Position'), findsNothing);
    });

    testWidgets('renders all sections in full example', (tester) async {
      final meaning = {
        'confidence': 0.92,
        'source': 'enrichment',
        'created_at': '2026-01-20T08:15:00Z',
        'updated_at': '2026-02-05T16:22:00Z',
      };
      final queueStatus = {
        'status': 'processing',
        'position': 1,
      };

      await tester.pumpTestWidget(
        DevInfoPanel(
          meaning: meaning,
          queueStatus: queueStatus,
        ),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      // Badge
      expect(find.text('DEV'), findsOneWidget);

      // Metadata
      expect(find.text('Confidence'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('enrichment'), findsOneWidget);

      // Timestamps
      expect(find.text('Created'), findsOneWidget);
      expect(find.textContaining('Jan 20, 2026'), findsOneWidget);
      expect(find.text('Updated'), findsOneWidget);
      expect(find.textContaining('Feb 5, 2026'), findsOneWidget);

      // Queue
      expect(find.text('Queue Status'), findsOneWidget);
      expect(find.text('processing'), findsOneWidget);
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Should have a divider between metadata and queue
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('handles DateTime objects in addition to strings',
        (tester) async {
      final createdDate = DateTime(2026, 1, 10, 12, 30);
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
        'created_at': createdDate,
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
      );

      expect(find.text('Created'), findsOneWidget);
      expect(find.textContaining('Jan 10, 2026'), findsOneWidget);
    });

    testWidgets('renders in dark mode', (tester) async {
      final meaning = {
        'confidence': 0.95,
        'source': 'ai',
      };

      await tester.pumpTestWidget(
        DevInfoPanel(meaning: meaning),
        overrides: [
          devModeProvider.overrideWith((ref) => true),
        ],
        themeMode: ThemeMode.dark,
      );

      expect(find.text('DEV'), findsOneWidget);
      expect(find.text('Confidence'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
    });
  });
}
