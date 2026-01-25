import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/models/highlight_type.dart';
import '../../data/models/parsed_highlight.dart';

/// Parser for Kindle "My Clippings.txt" format
class KindleClippingsParser {
  static const String _separator = '==========';

  /// Parse Kindle clippings file content
  List<ParsedHighlight> parse(String content) {
    final highlights = <ParsedHighlight>[];

    // Split by separator
    final entries = content.split(_separator);

    for (final entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;

      final highlight = _parseEntry(trimmed);
      if (highlight != null) {
        highlights.add(highlight);
      }
    }

    return highlights;
  }

  ParsedHighlight? _parseEntry(String entry) {
    final lines = entry.split('\n').map((l) => l.trim()).toList();

    // Need at least: title line, metadata line, empty line, content
    if (lines.length < 3) return null;

    // Line 1: Book title (Author)
    final (title, author) = _parseTitleLine(lines[0]);
    if (title.isEmpty) return null;

    // Line 2: Metadata (type, location, page, date)
    final (type, location, page, kindleDate) = _parseMetadataLine(lines[1]);

    // Content: everything after metadata, skipping empty lines at start
    var contentStart = 2;
    while (contentStart < lines.length && lines[contentStart].isEmpty) {
      contentStart++;
    }

    if (contentStart >= lines.length) return null;

    final content = lines.sublist(contentStart).join('\n').trim();
    if (content.isEmpty) return null;

    return ParsedHighlight(
      bookTitle: title,
      author: author,
      content: content,
      type: type,
      location: location,
      page: page,
      kindleDate: kindleDate,
    );
  }

  (String title, String? author) _parseTitleLine(String line) {
    // Format: "Book Title (Author Name)" or just "Book Title"
    final parenStart = line.lastIndexOf('(');
    final parenEnd = line.lastIndexOf(')');

    if (parenStart > 0 && parenEnd > parenStart) {
      final title = line.substring(0, parenStart).trim();
      final author = line.substring(parenStart + 1, parenEnd).trim();
      return (title, author.isEmpty ? null : author);
    }

    return (line.trim(), null);
  }

  (HighlightType type, String? location, int? page, DateTime? kindleDate)
      _parseMetadataLine(String line) {
    // Determine type
    final type =
        line.contains('Note') ? HighlightType.note : HighlightType.highlight;

    // Extract location: "Location 72-75" or "Location 72"
    final location = _extractPattern(line, 'Location ', [' |', '\n', '\r']);

    // Extract page: "page 5"
    final pageStr = _extractPattern(line, 'page ', [' |', '\n', '\r']);
    final page = pageStr != null ? int.tryParse(pageStr) : null;

    // Extract date: "Added on Monday, January 20, 2026 10:30:00 AM"
    final kindleDate = _parseKindleDate(line);

    return (type, location, page, kindleDate);
  }

  String? _extractPattern(String text, String start, List<String> ends) {
    final startIdx = text.indexOf(start);
    if (startIdx < 0) return null;

    final valueStart = startIdx + start.length;
    final remaining = text.substring(valueStart);

    var endIdx = remaining.length;
    for (final end in ends) {
      final idx = remaining.indexOf(end);
      if (idx >= 0 && idx < endIdx) {
        endIdx = idx;
      }
    }

    final value = remaining.substring(0, endIdx).trim();
    return value.isEmpty ? null : value;
  }

  DateTime? _parseKindleDate(String line) {
    // Pattern: "Added on <weekday>, <month> <day>, <year> <time>"
    final addedOnIdx = line.indexOf('Added on ');
    if (addedOnIdx < 0) return null;

    final dateStr = line.substring(addedOnIdx + 9).trim();

    // Try multiple date formats
    return _tryParseDate(dateStr);
  }

  DateTime? _tryParseDate(String dateStr) {
    // Remove weekday prefix if present (e.g., "Monday, ")
    final commaIdx = dateStr.indexOf(', ');
    final cleanDate =
        commaIdx > 0 ? dateStr.substring(commaIdx + 2).trim() : dateStr.trim();

    // Try common formats
    final patterns = [
      // January 20, 2026 10:30:00 AM (US format)
      RegExp(
          r'(\w+)\s+(\d{1,2}),\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)?',
          caseSensitive: false),
      // 20 January 2026 10:30:00 (UK/European format)
      RegExp(
          r'(\d{1,2})\s+(\w+)\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)?',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleanDate);
      if (match != null) {
        return _buildDateTime(match);
      }
    }

    return null;
  }

  DateTime? _buildDateTime(RegExpMatch match) {
    try {
      final groups = match.groups([1, 2, 3, 4, 5, 6, 7]);

      // Determine if first format (month name first) or second (day first)
      int day;
      int month;
      int year;

      final first = groups[0]!;
      if (int.tryParse(first) != null) {
        // Day first format: day, month name, year
        day = int.parse(first);
        month = _parseMonth(groups[1]!);
        year = int.parse(groups[2]!);
      } else {
        // Month first format: month name, day, year
        month = _parseMonth(first);
        day = int.parse(groups[1]!);
        year = int.parse(groups[2]!);
      }

      var hour = int.parse(groups[3]!);
      final minute = int.parse(groups[4]!);
      final second = int.parse(groups[5]!);

      // Handle AM/PM
      final ampm = groups[6];
      if (ampm != null) {
        if (ampm.toUpperCase() == 'PM' && hour < 12) {
          hour += 12;
        } else if (ampm.toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  int _parseMonth(String month) {
    const months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  /// Generate content hash for duplicate detection
  static String generateContentHash(String bookTitle, String content) {
    final normalized = '${bookTitle.toLowerCase().trim()}|${content.toLowerCase().trim()}';
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
