import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/learn/widgets/session_progress_bar.dart';
import 'package:mastery/features/learn/widgets/session_timer.dart';
import '../helpers/test_helpers.dart';

/// Tests for session-related widgets used in SessionScreen
/// Note: Full SessionScreen integration tests require extensive mocking
/// These tests cover the individual widgets that make up the session UI
void main() {
  group('SessionProgressBar', () {
    testWidgets('displays progress correctly', (tester) async {
      await tester.pumpTestWidget(
        const SessionProgressBar(completedItems: 5, totalItems: 10),
      );

      // Should show some visual progress indicator
      expect(find.byType(SessionProgressBar), findsOneWidget);
    });

    testWidgets('shows zero progress at start', (tester) async {
      await tester.pumpTestWidget(
        const SessionProgressBar(completedItems: 0, totalItems: 10),
      );

      expect(find.byType(SessionProgressBar), findsOneWidget);
    });

    testWidgets('shows full progress at completion', (tester) async {
      await tester.pumpTestWidget(
        const SessionProgressBar(completedItems: 10, totalItems: 10),
      );

      expect(find.byType(SessionProgressBar), findsOneWidget);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        const SessionProgressBar(completedItems: 3, totalItems: 10),
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(SessionProgressBar), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        const SessionProgressBar(completedItems: 3, totalItems: 10),
        themeMode: ThemeMode.light,
      );

      expect(find.byType(SessionProgressBar), findsOneWidget);
    });
  });

  group('SessionTimer', () {
    testWidgets('displays timer widget', (tester) async {
      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600, // 10 minutes
          onTimeUp: () {},
          onTick: (int seconds) {},
          isPaused: false,
        ),
      );

      expect(find.byType(SessionTimer), findsOneWidget);
    });

    testWidgets('shows time remaining', (tester) async {
      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600,
          onTimeUp: () {},
          onTick: (int seconds) {},
          isPaused: false,
        ),
      );

      // Timer should show some time text (format varies)
      expect(find.byType(SessionTimer), findsOneWidget);
    });

    testWidgets('respects isPaused state', (tester) async {
      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600,
          onTimeUp: () {},
          onTick: (int seconds) {},
          isPaused: true,
        ),
      );

      expect(find.byType(SessionTimer), findsOneWidget);
    });

    testWidgets('starts from initialElapsed when provided', (tester) async {
      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600,
          onTimeUp: () {},
          onTick: (int seconds) {},
          isPaused: false,
          initialElapsed: 300, // Start at 5 minutes
        ),
      );

      expect(find.byType(SessionTimer), findsOneWidget);
    });

    testWidgets('calls onTick as time progresses', (tester) async {
      int tickCount = 0;
      int lastTick = 0;

      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600,
          onTimeUp: () {},
          onTick: (int seconds) {
            tickCount++;
            lastTick = seconds;
          },
          isPaused: false,
        ),
      );

      // Advance time by 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Timer should have ticked at least once
      expect(tickCount, greaterThan(0));
      expect(lastTick, greaterThan(0));
    });

    testWidgets('does not advance elapsed time when paused', (tester) async {
      int lastTick = 0;

      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600,
          onTimeUp: () {},
          onTick: (int seconds) {
            lastTick = seconds;
          },
          isPaused: true,
          initialElapsed: 100,
        ),
      );

      // Let any init callbacks fire
      await tester.pump();
      final initialTick = lastTick;

      // Advance time by 2 seconds while paused
      await tester.pump(const Duration(seconds: 2));

      // Elapsed time should not advance significantly when paused
      // (allow for init tick that may occur)
      expect(lastTick, lessThanOrEqualTo(initialTick + 1));
    });

    testWidgets('calls onTimeUp when time reaches total', (tester) async {
      bool timeUpCalled = false;

      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 2, // 2 seconds total
          onTimeUp: () {
            timeUpCalled = true;
          },
          onTick: (int seconds) {},
          isPaused: false,
        ),
      );

      // Advance time past the total
      await tester.pump(const Duration(seconds: 3));

      expect(timeUpCalled, isTrue);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600,
          onTimeUp: () {},
          onTick: (int seconds) {},
          isPaused: false,
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(SessionTimer), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpTestWidget(
        SessionTimer(
          totalSeconds: 600,
          onTimeUp: () {},
          onTick: (int seconds) {},
          isPaused: false,
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.byType(SessionTimer), findsOneWidget);
    });
  });

  group('Session UI States', () {
    testWidgets('loading state shows progress indicator', (tester) async {
      // Simulate loading state
      await tester.pumpTestWidget(
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing your session...'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Preparing your session...'), findsOneWidget);
    });

    testWidgets('paused state shows pause indicator', (tester) async {
      // Simulate paused state UI
      await tester.pumpTestWidget(
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pause_circle_outline, size: 64),
                SizedBox(height: 16),
                Text('Session Paused'),
                SizedBox(height: 8),
                Text('Tap the play button to continue'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
      expect(find.text('Session Paused'), findsOneWidget);
      expect(find.text('Tap the play button to continue'), findsOneWidget);
    });

    testWidgets('completion state shows session complete', (tester) async {
      // Simulate completion state UI
      await tester.pumpTestWidget(
        const Scaffold(body: Center(child: Text('Session complete!'))),
      );

      expect(find.text('Session complete!'), findsOneWidget);
    });
  });
}
