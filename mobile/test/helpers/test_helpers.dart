import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/app_theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Wrapper widget for testing with ShadApp theme and Riverpod
Widget createTestableWidget({
  required Widget child,
  List<Override>? overrides,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: ShadApp(
      themeMode: themeMode,
      theme: MasteryTheme.light,
      darkTheme: MasteryTheme.dark,
      home: Scaffold(body: child),
    ),
  );
}

/// Extension to pump a widget with common test setup
extension WidgetTesterExtensions on WidgetTester {
  Future<void> pumpTestWidget(
    Widget widget, {
    List<Override>? overrides,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await pumpWidget(
      createTestableWidget(
        child: widget,
        overrides: overrides,
        themeMode: themeMode,
      ),
    );
  }
}

/// Sample test data generators
class TestData {
  static const String testUserId = 'test-user-123';
  static const String testSourceTitle = 'Test Book';
  static const String testSourceAuthor = 'Test Author';
}
