import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/core/theme/app_theme.dart';
import 'package:mastery/data/database/database.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Creates an in-memory database for testing
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

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

  static VocabularysCompanion createVocabularyCompanion({
    String? id,
    String? userId,
    String? word,
    String? contentHash,
    String? stem,
  }) {
    final now = DateTime.now();
    return VocabularysCompanion.insert(
      id: id ?? 'vocab-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      word: word ?? 'ephemeral',
      contentHash:
          contentHash ?? 'hash-${DateTime.now().millisecondsSinceEpoch}',
      stem: Value(stem),
      createdAt: now,
      updatedAt: now,
    );
  }

  static SourcesCompanion createSourceCompanion({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? author,
    String? asin,
  }) {
    final now = DateTime.now();
    return SourcesCompanion.insert(
      id: id ?? 'source-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      type: type ?? 'book',
      title: title ?? testSourceTitle,
      author: Value(author ?? testSourceAuthor),
      asin: Value(asin),
      createdAt: now,
      updatedAt: now,
    );
  }

  static EncountersCompanion createEncounterCompanion({
    String? id,
    String? userId,
    required String vocabularyId,
    String? sourceId,
    String? context,
    DateTime? occurredAt,
  }) {
    final now = DateTime.now();
    return EncountersCompanion.insert(
      id: id ?? 'enc-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      vocabularyId: vocabularyId,
      sourceId: Value(sourceId),
      context: Value(context ?? 'The ephemeral nature of things.'),
      occurredAt: Value(occurredAt ?? now),
      createdAt: now,
      updatedAt: now,
    );
  }
}
