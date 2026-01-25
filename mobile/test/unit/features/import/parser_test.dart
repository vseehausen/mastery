import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/models/highlight_type.dart';
import 'package:mastery/features/import/parser.dart';

void main() {
  late KindleClippingsParser parser;

  setUp(() {
    parser = KindleClippingsParser();
  });

  group('KindleClippingsParser', () {
    group('parse', () {
      test('parses empty content', () {
        final result = parser.parse('');
        expect(result, isEmpty);
      });

      test('parses single highlight', () {
        const content = '''
The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 5 | Location 72-75 | Added on Monday, January 20, 2026 10:30:00 AM

In my younger and more vulnerable years my father gave me some advice.
==========
''';
        final result = parser.parse(content);

        expect(result.length, 1);
        expect(result[0].bookTitle, 'The Great Gatsby');
        expect(result[0].author, 'F. Scott Fitzgerald');
        expect(result[0].type, HighlightType.highlight);
        expect(result[0].page, 5);
        expect(result[0].location, '72-75');
        expect(result[0].content,
            'In my younger and more vulnerable years my father gave me some advice.');
      });

      test('parses note type', () {
        const content = '''
1984 (George Orwell)
- Your Note on page 50 | Location 750 | Added on Tuesday, January 21, 2026 9:30:00 AM

This reminds me of modern surveillance concerns.
==========
''';
        final result = parser.parse(content);

        expect(result.length, 1);
        expect(result[0].type, HighlightType.note);
        expect(result[0].bookTitle, '1984');
        expect(result[0].author, 'George Orwell');
      });

      test('parses book without author', () {
        const content = '''
Book Without Author
- Your Highlight on Location 100-105 | Added on Wednesday, January 22, 2026 2:00:00 PM

Some highlighted text from a book without a known author.
==========
''';
        final result = parser.parse(content);

        expect(result.length, 1);
        expect(result[0].bookTitle, 'Book Without Author');
        expect(result[0].author, isNull);
      });

      test('parses multiple highlights', () {
        const content = '''
The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 5 | Location 72-75 | Added on Monday, January 20, 2026 10:30:00 AM

First highlight.
==========
1984 (George Orwell)
- Your Highlight on page 1 | Location 10-12 | Added on Tuesday, January 21, 2026 9:00:00 AM

Second highlight.
==========
''';
        final result = parser.parse(content);

        expect(result.length, 2);
        expect(result[0].bookTitle, 'The Great Gatsby');
        expect(result[1].bookTitle, '1984');
      });

      test('skips entries without content', () {
        const content = '''
The Great Gatsby (F. Scott Fitzgerald)
- Your Highlight on page 5 | Location 72-75 | Added on Monday, January 20, 2026 10:30:00 AM


==========
1984 (George Orwell)
- Your Highlight on page 1 | Location 10-12 | Added on Tuesday, January 21, 2026 9:00:00 AM

Valid content.
==========
''';
        final result = parser.parse(content);

        expect(result.length, 1);
        expect(result[0].bookTitle, '1984');
      });

      test('handles highlight without page number', () {
        const content = '''
Book Title (Author)
- Your Highlight on Location 100-105 | Added on Monday, January 20, 2026 10:00:00 AM

Some content.
==========
''';
        final result = parser.parse(content);

        expect(result.length, 1);
        expect(result[0].page, isNull);
        expect(result[0].location, '100-105');
      });

      test('parses fixture file', () {
        final file = File('test/fixtures/sample_clippings.txt');
        if (!file.existsSync()) {
          fail('Fixture file not found');
        }

        final content = file.readAsStringSync();
        final result = parser.parse(content);

        expect(result.length, 5);

        // First highlight
        expect(result[0].bookTitle, 'The Great Gatsby');
        expect(result[0].author, 'F. Scott Fitzgerald');
        expect(result[0].type, HighlightType.highlight);

        // Note
        final note = result.firstWhere((h) => h.type == HighlightType.note);
        expect(note.bookTitle, '1984');
        expect(note.content, 'This reminds me of modern surveillance concerns.');

        // Book without author
        final noAuthor =
            result.firstWhere((h) => h.bookTitle == 'Book Without Author');
        expect(noAuthor.author, isNull);
      });
    });

    group('generateContentHash', () {
      test('generates consistent hash for same content', () {
        final hash1 =
            KindleClippingsParser.generateContentHash('Book', 'Content');
        final hash2 =
            KindleClippingsParser.generateContentHash('Book', 'Content');

        expect(hash1, hash2);
      });

      test('generates different hash for different content', () {
        final hash1 =
            KindleClippingsParser.generateContentHash('Book', 'Content 1');
        final hash2 =
            KindleClippingsParser.generateContentHash('Book', 'Content 2');

        expect(hash1, isNot(hash2));
      });

      test('hash is case-insensitive', () {
        final hash1 =
            KindleClippingsParser.generateContentHash('BOOK', 'CONTENT');
        final hash2 =
            KindleClippingsParser.generateContentHash('book', 'content');

        expect(hash1, hash2);
      });

      test('hash ignores leading/trailing whitespace', () {
        final hash1 =
            KindleClippingsParser.generateContentHash('  Book  ', '  Content  ');
        final hash2 =
            KindleClippingsParser.generateContentHash('Book', 'Content');

        expect(hash1, hash2);
      });

      test('returns 64-character hex string', () {
        final hash =
            KindleClippingsParser.generateContentHash('Book', 'Content');

        expect(hash.length, 64);
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
      });
    });

    group('date parsing', () {
      test('parses AM time correctly', () {
        const content = '''
Book (Author)
- Your Highlight on page 1 | Location 1 | Added on Monday, January 20, 2026 10:30:00 AM

Content.
==========
''';
        final result = parser.parse(content);
        final date = result[0].kindleDate;

        expect(date, isNotNull);
        expect(date!.hour, 10);
        expect(date.minute, 30);
      });

      test('parses PM time correctly', () {
        const content = '''
Book (Author)
- Your Highlight on page 1 | Location 1 | Added on Monday, January 20, 2026 2:30:00 PM

Content.
==========
''';
        final result = parser.parse(content);
        final date = result[0].kindleDate;

        expect(date, isNotNull);
        expect(date!.hour, 14);
        expect(date.minute, 30);
      });

      test('parses 12:00 PM as noon', () {
        const content = '''
Book (Author)
- Your Highlight on page 1 | Location 1 | Added on Monday, January 20, 2026 12:00:00 PM

Content.
==========
''';
        final result = parser.parse(content);
        final date = result[0].kindleDate;

        expect(date, isNotNull);
        expect(date!.hour, 12);
      });

      test('parses 12:00 AM as midnight', () {
        const content = '''
Book (Author)
- Your Highlight on page 1 | Location 1 | Added on Monday, January 20, 2026 12:00:00 AM

Content.
==========
''';
        final result = parser.parse(content);
        final date = result[0].kindleDate;

        expect(date, isNotNull);
        expect(date!.hour, 0);
      });
    });
  });
}
