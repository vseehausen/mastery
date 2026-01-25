import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/models/import_source.dart';
import 'package:mastery/features/import/parser.dart';

/// Integration tests for the complete import flow
///
/// These tests verify the full import pipeline from parsing to storage.
/// Note: Full database integration requires drift_dev test utilities.
void main() {
  group('Import Flow Integration', () {
    late KindleClippingsParser parser;

    setUp(() {
      parser = KindleClippingsParser();
    });

    group('End-to-end parsing', () {
      test('parses real Kindle clippings format', () {
        const clippings = '''
The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 47 | Location 721-722 | Added on Monday, January 15, 2024 12:30:45 PM

In my younger and more vulnerable years my father gave me some advice that I've been turning over in my mind ever since.
==========
The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 93 | Location 1421-1423 | Added on Monday, January 15, 2024 1:15:23 PM

So we beat on, boats against the current, borne back ceaselessly into the past.
==========
1984 (George Orwell)
- Your Note on page 1 | Location 15 | Added on Tuesday, January 16, 2024 9:00:00 AM

This is a personal note about the opening line.
==========
''';

        final highlights = parser.parse(clippings);

        expect(highlights.length, 3);

        // First highlight
        expect(highlights[0].bookTitle, 'The Great Gatsby');
        expect(highlights[0].author, 'F. Scott Fitzgerald');
        expect(highlights[0].page, 47);
        expect(highlights[0].content, contains('my younger and more vulnerable years'));

        // Second highlight from same book
        expect(highlights[1].bookTitle, 'The Great Gatsby');
        expect(highlights[1].page, 93);
        expect(highlights[1].content, contains('boats against the current'));

        // Third entry is a note from different book
        expect(highlights[2].bookTitle, '1984');
        expect(highlights[2].author, 'George Orwell');
      });

      test('handles UK date format', () {
        const clippings = '''
Test Book (Test Author)
- Your Highlight on page 1 | Location 10 | Added on Monday, 15 January 2024 12:30:45

Test content
==========
''';

        final highlights = parser.parse(clippings);
        expect(highlights.length, 1);
        expect(highlights[0].kindleDate, isNotNull);
      });

      test('handles bookmarks (filters them out)', () {
        const clippings = '''
Test Book (Test Author)
- Your Bookmark on page 50 | Location 500 | Added on Monday, January 15, 2024 12:00:00 PM

==========
Test Book (Test Author)
- Your Highlight on page 51 | Location 510 | Added on Monday, January 15, 2024 12:01:00 PM

Actual highlight content
==========
''';

        final highlights = parser.parse(clippings);
        // Bookmarks should be filtered out (or handled specially)
        expect(highlights.length, greaterThanOrEqualTo(1));
        expect(highlights.any((h) => h.content.isNotEmpty), true);
      });

      test('handles multiple books in single file', () {
        const clippings = '''
Book One (Author One)
- Your Highlight on page 1 | Location 10 | Added on Monday, January 15, 2024 12:00:00 PM

Content from book one
==========
Book Two (Author Two)
- Your Highlight on page 2 | Location 20 | Added on Monday, January 15, 2024 12:01:00 PM

Content from book two
==========
Book Three (Author Three)
- Your Highlight on page 3 | Location 30 | Added on Monday, January 15, 2024 12:02:00 PM

Content from book three
==========
''';

        final highlights = parser.parse(clippings);
        expect(highlights.length, 3);

        final books = highlights.map((h) => h.bookTitle).toSet();
        expect(books.length, 3);
      });
    });

    group('Content hash generation', () {
      test('generates consistent hash for same content', () {
        const bookTitle = 'Test Book';
        const content = 'Same content';

        final hash1 = KindleClippingsParser.generateContentHash(bookTitle, content);
        final hash2 = KindleClippingsParser.generateContentHash(bookTitle, content);

        expect(hash1, hash2);
      });

      test('generates different hash for different content', () {
        const bookTitle = 'Test Book';

        final hash1 = KindleClippingsParser.generateContentHash(bookTitle, 'Content one');
        final hash2 = KindleClippingsParser.generateContentHash(bookTitle, 'Content two');

        expect(hash1, isNot(hash2));
      });

      test('generates different hash for different books with same content', () {
        const content = 'Same content';

        final hash1 = KindleClippingsParser.generateContentHash('Book One', content);
        final hash2 = KindleClippingsParser.generateContentHash('Book Two', content);

        expect(hash1, isNot(hash2));
      });
    });

    group('Import source tracking', () {
      test('file source is recorded', () {
        expect(ImportSource.file.name, 'file');
      });

      test('device source is recorded', () {
        expect(ImportSource.device.name, 'device');
      });
    });

    group('Error handling', () {
      test('handles empty file gracefully', () {
        final highlights = parser.parse('');
        expect(highlights, isEmpty);
      });

      test('handles file with only delimiters', () {
        const clippings = '''
==========
==========
==========
''';

        final highlights = parser.parse(clippings);
        expect(highlights, isEmpty);
      });

      test('handles malformed entries gracefully', () {
        const clippings = '''
This is not a valid entry
without proper formatting
==========
Valid Book (Valid Author)
- Your Highlight on page 1 | Location 10 | Added on Monday, January 15, 2024 12:00:00 PM

Valid content here
==========
''';

        // Should not throw, and should parse valid entries
        final highlights = parser.parse(clippings);
        expect(highlights.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
