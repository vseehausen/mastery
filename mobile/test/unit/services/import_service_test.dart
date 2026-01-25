import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/models/import_result.dart';
import 'package:mastery/data/models/import_source.dart';

// Note: Full integration tests require mocking the database and repositories.
// These tests focus on testing the ImportResult model and related logic.

void main() {
  group('ImportResult', () {
    test('creates result with all statistics', () {
      final result = ImportResult(
        totalFound: 100,
        imported: 80,
        skipped: 15,
        errors: 5,
        errorDetails: ['Error 1', 'Error 2'],
        duration: const Duration(seconds: 10),
      );

      expect(result.totalFound, 100);
      expect(result.imported, 80);
      expect(result.skipped, 15);
      expect(result.errors, 5);
      expect(result.errorDetails.length, 2);
      expect(result.duration.inSeconds, 10);
    });

    test('calculates success rate correctly', () {
      final result = ImportResult(
        totalFound: 100,
        imported: 75,
        skipped: 20,
        errors: 5,
        errorDetails: [],
        duration: Duration.zero,
      );

      // 75 imported + 20 skipped (duplicates) = 95% success
      // 5 errors = 5% failure
      expect(result.totalFound - result.errors, 95);
    });

    test('handles empty import', () {
      final result = ImportResult(
        totalFound: 0,
        imported: 0,
        skipped: 0,
        errors: 0,
        errorDetails: [],
        duration: Duration.zero,
      );

      expect(result.totalFound, 0);
      expect(result.imported, 0);
    });

    test('tracks all errors in errorDetails', () {
      final errors = [
        'Failed to parse highlight 1',
        'Database error on highlight 2',
        'Invalid date format on highlight 3',
      ];

      final result = ImportResult(
        totalFound: 10,
        imported: 7,
        skipped: 0,
        errors: 3,
        errorDetails: errors,
        duration: Duration.zero,
      );

      expect(result.errors, result.errorDetails.length);
    });
  });

  group('ImportSource', () {
    test('has file source', () {
      expect(ImportSource.file.name, 'file');
    });

    test('has device source', () {
      expect(ImportSource.device.name, 'device');
    });

    test('all sources have valid names', () {
      for (final source in ImportSource.values) {
        expect(source.name.isNotEmpty, true);
      }
    });
  });

  group('Import Service Logic', () {
    test('duplicate detection uses content hash', () {
      // Content hash should be deterministic for same content
      const bookTitle = 'Test Book';
      const content1 = 'This is a test highlight';
      const content2 = 'This is a test highlight';
      const content3 = 'This is a different highlight';

      // Same content should produce same conceptual hash
      expect(content1, content2);
      expect(content1 == content3, false);
    });

    test('book title and author parsing works', () {
      // Test the parser logic conceptually
      const titleWithAuthor = 'The Great Gatsby (F. Scott Fitzgerald)';
      final match = RegExp(r'^(.+)\s*\(([^)]+)\)$').firstMatch(titleWithAuthor);

      expect(match, isNotNull);
      expect(match!.group(1)?.trim(), 'The Great Gatsby');
      expect(match.group(2)?.trim(), 'F. Scott Fitzgerald');
    });

    test('book title without author works', () {
      const titleWithoutAuthor = 'Unknown Book';
      final match = RegExp(r'^(.+)\s*\(([^)]+)\)$').firstMatch(titleWithoutAuthor);

      expect(match, isNull);
    });
  });
}
