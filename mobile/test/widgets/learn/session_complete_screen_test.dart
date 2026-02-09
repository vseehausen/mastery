import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/app_theme.dart';
import 'package:mastery/domain/models/progress_stage.dart';
import 'package:mastery/domain/models/stage_transition.dart';
import 'package:mastery/features/learn/providers/streak_providers.dart';
import 'package:mastery/features/learn/screens/session_complete_screen.dart';
import 'package:mastery/providers/review_write_queue_provider.dart';
import 'package:mastery/providers/supabase_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/session_planner_test.mocks.dart';

/// Helper to build a testable SessionCompleteScreen wrapped in proper
/// navigation context (the screen uses Navigator.of(context).popUntil
/// and pushReplacement, so it must sit inside a Navigator).
Widget _buildTestableScreen({
  required SessionCompleteScreen screen,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: ShadApp(
      themeMode: ThemeMode.light,
      theme: MasteryTheme.light,
      darkTheme: MasteryTheme.dark,
      builder: (context, child) {
        return ScaffoldMessenger(child: child ?? const SizedBox.shrink());
      },
      home: screen,
    ),
  );
}

/// Sets up a phone-sized surface for tests. The SessionCompleteScreen has
/// Spacer widgets and multiple cards that need sufficient vertical and
/// horizontal space to avoid RenderFlex overflow in the test environment.
void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Shared provider overrides used by every test.
Future<List<Override>> _defaultOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  return [
    currentStreakProvider.overrideWith((ref) async => 5),
    supabaseDataServiceProvider.overrideWithValue(MockSupabaseDataService()),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
}

/// Convenience constants for test transitions.
final _stabilizingTransition = StageTransition(
  vocabularyId: '1',
  wordText: 'word1',
  fromStage: ProgressStage.practicing,
  toStage: ProgressStage.stabilizing,
  timestamp: DateTime(2026, 2, 8),
);

final _activeTransition = StageTransition(
  vocabularyId: '2',
  wordText: 'word2',
  fromStage: ProgressStage.stabilizing,
  toStage: ProgressStage.known,
  timestamp: DateTime(2026, 2, 8),
);

final _masteredTransition = StageTransition(
  vocabularyId: '3',
  wordText: 'word3',
  fromStage: ProgressStage.known,
  toStage: ProgressStage.mastered,
  timestamp: DateTime(2026, 2, 8),
);

void main() {
  // Initialize SharedPreferences for all tests
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionCompleteScreen', () {
    group('Progress card visibility', () {
      testWidgets('shows Progress card when transitions are passed', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [_stabilizingTransition],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        // Progress card exists but no header
        expect(find.textContaining('→ Stabilizing'), findsOneWidget);
      });

      testWidgets(
        'does NOT show Progress card when transitions is empty',
        (tester) async {
          _setPhoneSize(tester);
          await tester.pumpWidget(
            _buildTestableScreen(
              screen: const SessionCompleteScreen(
                sessionId: 'session-1',
                itemsCompleted: 10,
                totalItems: 10,
                elapsedSeconds: 300,
                plannedSeconds: 300,
                isFullCompletion: true,
                transitions: [],
              ),
              overrides: await _defaultOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('→'), findsNothing);
        },
      );

      testWidgets(
        'does NOT show Progress card when transitions is default (empty)',
        (tester) async {
          _setPhoneSize(tester);
          await tester.pumpWidget(
            _buildTestableScreen(
              screen: const SessionCompleteScreen(
                sessionId: 'session-1',
                itemsCompleted: 5,
                totalItems: 10,
                elapsedSeconds: 180,
                plannedSeconds: 300,
                isFullCompletion: false,
              ),
              overrides: await _defaultOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('→'), findsNothing);
        },
      );
    });

    group('transition counts', () {
      testWidgets('shows correct count for a single Stabilizing transition', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [_stabilizingTransition],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        // "1 word → Stabilizing" (arrow format in minimal design)
        expect(find.textContaining('1 word'), findsWidgets);
        expect(find.textContaining('→'), findsWidgets);
        expect(find.textContaining('Stabilizing'), findsWidgets);
      });

      testWidgets('shows correct count for multiple Stabilizing transitions', (
        tester,
      ) async {
        _setPhoneSize(tester);
        final secondStabilizing = StageTransition(
          vocabularyId: '4',
          wordText: 'word4',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: DateTime(2026, 2, 8),
        );

        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [_stabilizingTransition, secondStabilizing],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        // "2 words → Stabilizing" (plural, arrow format)
        expect(find.textContaining('2 words'), findsOneWidget);
        expect(find.textContaining('→'), findsWidgets);
      });

      testWidgets('shows correct counts for mixed transition types', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [
                _masteredTransition,
                _activeTransition,
                _stabilizingTransition,
              ],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        // Each type should show "1 word → StageName" (arrow format in minimal design)
        expect(find.textContaining('→'), findsWidgets);
        expect(find.textContaining('Mastered'), findsWidgets);
        expect(find.textContaining('Known'), findsWidgets);
        expect(find.textContaining('Stabilizing'), findsWidgets);
      });

      testWidgets('shows Mastered row with correct text', (tester) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [_masteredTransition],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Mastered'), findsWidgets);
      });

      testWidgets('shows Known row with correct text', (tester) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [_activeTransition],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Known'), findsWidgets);
      });

      testWidgets('shows latest transition when same vocabulary ID progresses multiple times', (
        tester,
      ) async {
        _setPhoneSize(tester);
        // Two transitions for the same word (same vocabulary ID)
        final firstTransition = StageTransition(
          vocabularyId: '1',
          wordText: 'word1',
          fromStage: ProgressStage.practicing,
          toStage: ProgressStage.stabilizing,
          timestamp: DateTime(2026, 2, 8),
        );
        final secondTransition = StageTransition(
          vocabularyId: '1', // Same vocabulary ID
          wordText: 'word1',
          fromStage: ProgressStage.stabilizing,
          toStage: ProgressStage.known,
          timestamp: DateTime(2026, 2, 8),
        );

        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [firstTransition, secondTransition],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        // Should show both stage rows: "1 word → Stabilizing" and "1 word → Known"
        expect(find.textContaining('1 word'), findsWidgets);
        expect(find.textContaining('Known'), findsWidgets);
      });
    });

    group('minimal design - no star icons', () {
      testWidgets('does NOT show star icons in minimal design', (tester) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              transitions: [_masteredTransition, _activeTransition, _stabilizingTransition],
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        // Minimal design removes all star icons
        expect(find.byIcon(Icons.star_rounded), findsNothing);
      });
    });

    group('session stats display - single muted line', () {
      testWidgets('shows stats as single muted line with dots', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 7,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        // Stats are now in a single line: "7 items · 5 min  · 5-day streak"
        expect(find.textContaining('7 items'), findsOneWidget);
        expect(find.textContaining('·'), findsOneWidget);
        expect(find.textContaining('5-day streak'), findsOneWidget);
      });

      testWidgets('shows time in minutes and seconds in stats line', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 185, // 3 min 5 sec
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('3 min 5 sec'), findsOneWidget);
      });

      testWidgets('shows time in seconds only when under a minute', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 2,
              totalItems: 10,
              elapsedSeconds: 45,
              plannedSeconds: 300,
              isFullCompletion: false,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('45 sec'), findsOneWidget);
      });

      testWidgets('omits streak when streak is 0', (tester) async {
        _setPhoneSize(tester);
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: [
              currentStreakProvider.overrideWith((ref) async => 0),
              supabaseDataServiceProvider.overrideWithValue(MockSupabaseDataService()),
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Stats line should not include streak when it's 0
        expect(find.textContaining('streak'), findsNothing);
        expect(find.textContaining('10 items'), findsOneWidget);
      });
    });

    group('title - no subtitle in minimal design', () {
      testWidgets('shows full completion title (no subtitle)', (tester) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("You're done for today!"), findsOneWidget);
        // No subtitle in minimal design
        expect(find.text('Great work! Come back tomorrow.'), findsNothing);
      });

      testWidgets('shows partial completion title (no subtitle)', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 5,
              totalItems: 10,
              elapsedSeconds: 180,
              plannedSeconds: 300,
              isFullCompletion: false,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Session ended'), findsOneWidget);
        // No subtitle in minimal design
        expect(find.text('You made progress today.'), findsNothing);
      });

      testWidgets('shows all items exhausted title (no subtitle)', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
              allItemsExhausted: true,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("You've reviewed everything!"), findsOneWidget);
        // No subtitle in minimal design
        expect(find.text('No more items available right now.'), findsNothing);
      });

      testWidgets('shows quick review title when isQuickReview is true', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 5,
              totalItems: 10,
              elapsedSeconds: 120,
              plannedSeconds: 300,
              isFullCompletion: false,
              isQuickReview: true,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Quick review done!'), findsOneWidget);
      });
    });

    group('bonus time button', () {
      testWidgets(
        'shows bonus time button when full completion and items available',
        (tester) async {
          _setPhoneSize(tester);
          await tester.pumpWidget(
            _buildTestableScreen(
              screen: const SessionCompleteScreen(
                sessionId: 'session-1',
                itemsCompleted: 10,
                totalItems: 10,
                elapsedSeconds: 300,
                plannedSeconds: 300,
                isFullCompletion: true,
                allItemsExhausted: false,
              ),
              overrides: await _defaultOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('+2 min bonus'), findsOneWidget);
        },
      );

      testWidgets(
        'does NOT show bonus time button when all items are exhausted',
        (tester) async {
          _setPhoneSize(tester);
          await tester.pumpWidget(
            _buildTestableScreen(
              screen: const SessionCompleteScreen(
                sessionId: 'session-1',
                itemsCompleted: 10,
                totalItems: 10,
                elapsedSeconds: 300,
                plannedSeconds: 300,
                isFullCompletion: true,
                allItemsExhausted: true,
              ),
              overrides: await _defaultOverrides(),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('+2 min bonus'), findsNothing);
        },
      );

      testWidgets('does NOT show bonus time button for partial completion', (
        tester,
      ) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 5,
              totalItems: 10,
              elapsedSeconds: 180,
              plannedSeconds: 300,
              isFullCompletion: false,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('+2 min bonus'), findsNothing);
      });

      testWidgets('tapping bonus time button calls addBonusTime', (
        tester,
      ) async {
        _setPhoneSize(tester);
        final mockDataService = MockSupabaseDataService();
        when(
          mockDataService.addBonusTime(
            sessionId: anyNamed('sessionId'),
            bonusSeconds: anyNamed('bonusSeconds'),
          ),
        ).thenAnswer((_) async {});

        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: [
              currentStreakProvider.overrideWith((ref) async => 5),
              supabaseDataServiceProvider.overrideWithValue(mockDataService),
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('+2 min bonus'));
        await tester.pump();

        verify(
          mockDataService.addBonusTime(
            sessionId: 'session-1',
            bonusSeconds: 120,
          ),
        ).called(1);
      });

      testWidgets('shows snackbar on error when bonus time fails', (
        tester,
      ) async {
        _setPhoneSize(tester);
        final mockDataService = MockSupabaseDataService();
        when(
          mockDataService.addBonusTime(
            sessionId: anyNamed('sessionId'),
            bonusSeconds: anyNamed('bonusSeconds'),
          ),
        ).thenAnswer((_) async => throw Exception('Network error'));

        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: [
              currentStreakProvider.overrideWith((ref) async => 5),
              supabaseDataServiceProvider.overrideWithValue(mockDataService),
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('+2 min bonus'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error adding bonus time'), findsOneWidget);
      });
    });

    group('Done button', () {
      testWidgets('shows Done button', (tester) async {
        _setPhoneSize(tester);
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: await _defaultOverrides(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Done'), findsOneWidget);
      });

      testWidgets('tapping Done navigates back to first route', (tester) async {
        _setPhoneSize(tester);

        await tester.pumpWidget(
          ProviderScope(
            overrides: await _defaultOverrides(),
            child: ShadApp(
              themeMode: ThemeMode.light,
              theme: MasteryTheme.light,
              darkTheme: MasteryTheme.dark,
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SessionCompleteScreen(
                            sessionId: 'session-1',
                            itemsCompleted: 10,
                            totalItems: 10,
                            elapsedSeconds: 300,
                            plannedSeconds: 300,
                            isFullCompletion: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Go'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to session complete screen
        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        expect(find.text('Done'), findsOneWidget);

        // Tap Done
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Should be back at the first route
        expect(find.text('Go'), findsOneWidget);
        expect(find.text('Done'), findsNothing);
      });
    });

    group('streak error state', () {
      testWidgets('omits streak from stats line when streak provider errors', (
        tester,
      ) async {
        _setPhoneSize(tester);
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          _buildTestableScreen(
            screen: const SessionCompleteScreen(
              sessionId: 'session-1',
              itemsCompleted: 10,
              totalItems: 10,
              elapsedSeconds: 300,
              plannedSeconds: 300,
              isFullCompletion: true,
            ),
            overrides: [
              currentStreakProvider.overrideWith(
                (ref) => throw Exception('Streak fetch failed'),
              ),
              supabaseDataServiceProvider.overrideWithValue(
                MockSupabaseDataService(),
              ),
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // The error state omits streak from stats line (treated as null)
        expect(find.textContaining('10 items'), findsOneWidget);
        expect(find.textContaining('streak'), findsNothing);
      });
    });
  });
}
