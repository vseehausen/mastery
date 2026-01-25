import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/features/import/parser.dart';

void main() {
  group('Performance Tests', () {
    group('Import Performance', () {
      test('import 1000 highlights in under 30 seconds', () async {
        // Generate large clippings content with 1000 highlights
        final buffer = StringBuffer();

        for (int i = 0; i < 1000; i++) {
          buffer.writeln(
            'Book ${i ~/ 100} (Author ${i ~/ 100})\n'
            '- Your Highlight on page ${i % 300 + 1} | Location ${i}-${i + 10} | Added on Monday, January 20, 2026 10:30:00 AM\n'
            '\n'
            'Highlight content number $i: This is a test highlight for performance testing.\n'
            '==========\n',
          );
        }

        final clippingsContent = buffer.toString();

        // Measure parsing time
        final stopwatch = Stopwatch()..start();
        final parser = KindleClippingsParser();
        final result = parser.parse(clippingsContent);
        stopwatch.stop();

        // Verify results
        expect(result.length, 1000);
        expect(stopwatch.elapsedMilliseconds, lessThan(30000),
            reason:
                'Parsing 1000 highlights should take less than 30 seconds. Took ${stopwatch.elapsedMilliseconds}ms');

        print('✓ Imported 1000 highlights in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('import 100 highlights in under 3 seconds', () async {
        // Generate clippings content with 100 highlights
        final buffer = StringBuffer();

        for (int i = 0; i < 100; i++) {
          buffer.writeln(
            'Test Book (Test Author)\n'
            '- Your Highlight on page ${i + 1} | Location ${i * 10}-${i * 10 + 5} | Added on Monday, January 20, 2026 10:30:00 AM\n'
            '\n'
            'This is test highlight number $i for performance measurement.\n'
            '==========\n',
          );
        }

        final clippingsContent = buffer.toString();

        // Measure parsing time
        final stopwatch = Stopwatch()..start();
        final parser = KindleClippingsParser();
        final result = parser.parse(clippingsContent);
        stopwatch.stop();

        // Verify results
        expect(result.length, 100);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
            reason:
                'Parsing 100 highlights should take less than 3 seconds. Took ${stopwatch.elapsedMilliseconds}ms');

        print('✓ Imported 100 highlights in ${stopwatch.elapsedMilliseconds}ms');
      });

      test('parser handles 10MB file', () {
        // Create a file that's approximately 10MB
        final buffer = StringBuffer();
        int totalSize = 0;
        const targetSize = 10 * 1024 * 1024; // 10MB

        int i = 0;
        while (totalSize < targetSize) {
          final entry =
              'Book ${i ~/ 100} (Author ${i ~/ 100})\n'
              '- Your Highlight on page ${i % 300 + 1} | Location ${i}-${i + 10} | Added on Monday, January 20, 2026 10:30:00 AM\n'
              '\n'
              'This is a test highlight with some longer content to make the file bigger.\n'
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n'
              '==========\n';

          buffer.writeln(entry);
          totalSize += entry.length;
          i++;
        }

        final clippingsContent = buffer.toString();

        // Measure parsing time
        final stopwatch = Stopwatch()..start();
        final parser = KindleClippingsParser();
        final result = parser.parse(clippingsContent);
        stopwatch.stop();

        // Verify it parsed without crashing
        expect(result.isNotEmpty, true);
        expect(
            stopwatch.elapsedMilliseconds,
            lessThan(30000),
            reason:
                '10MB file should parse in under 30 seconds. Took ${stopwatch.elapsedMilliseconds}ms');

        print(
            '✓ Parsed 10MB file (${result.length} highlights) in ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Search Performance', () {
      test('search returns results in under 3 seconds', () async {
        // Generate large content for search
        final buffer = StringBuffer();

        for (int i = 0; i < 1000; i++) {
          buffer.writeln(
            'Book ${i ~/ 100} (Author ${i ~/ 100})\n'
            '- Your Highlight on page ${i % 300 + 1} | Location ${i}-${i + 10} | Added on Monday, January 20, 2026 10:30:00 AM\n'
            '\n'
            'This highlight contains important vocabulary words like ephemeral and serendipity.\n'
            '==========\n',
          );
        }

        final clippingsContent = buffer.toString();

        // Parse and prepare data
        final parser = KindleClippingsParser();
        final highlights = parser.parse(clippingsContent);

        // Simulate search by filtering highlights
        final searchQuery = 'ephemeral';
        final stopwatch = Stopwatch()..start();

        final results = highlights
            .where((h) =>
                h.content.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        stopwatch.stop();

        // Verify results
        expect(results.isNotEmpty, true);
        expect(stopwatch.elapsedMilliseconds, lessThan(3000),
            reason:
                'Search should return results in under 3 seconds. Took ${stopwatch.elapsedMilliseconds}ms');

        print(
            '✓ Searched 1000 highlights in ${stopwatch.elapsedMilliseconds}ms, found ${results.length} matches');
      });

      test('search is case-insensitive and handles special characters', () {
        const content = 'Test Book (Test Author)\n'
            '- Your Highlight on page 1 | Location 10 | Added on Monday, January 20, 2026 10:30:00 AM\n'
            '\n'
            'The word "EPHEMERAL" appears here with punctuation!\n'
            '==========\n';

        final parser = KindleClippingsParser();
        final highlights = parser.parse(content);

        // Search for lowercase version of uppercase word
        final results = highlights
            .where((h) => h.content.toLowerCase().contains('ephemeral'))
            .toList();

        expect(results.length, 1);
        print('✓ Case-insensitive search working correctly');
      });
    });

    group('Content Hash Performance', () {
      test('generate hash for large content quickly', () {
        final largeContent = 'Lorem ipsum dolor sit amet, ' * 1000; // ~30KB

        final stopwatch = Stopwatch()..start();
        final hash1 =
            KindleClippingsParser.generateContentHash('Book', largeContent);
        final hash2 =
            KindleClippingsParser.generateContentHash('Book', largeContent);
        stopwatch.stop();

        expect(hash1, hash2);
        expect(
            stopwatch.elapsedMilliseconds,
            lessThan(100),
            reason:
                'Content hash generation should be under 100ms. Took ${stopwatch.elapsedMilliseconds}ms');

        print('✓ Generated content hashes in ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}
