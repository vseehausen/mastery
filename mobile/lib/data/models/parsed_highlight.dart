import 'highlight_type.dart';

/// Represents a parsed highlight from Kindle clippings file
class ParsedHighlight {
  final String bookTitle;
  final String? author;
  final String content;
  final HighlightType type;
  final String? location;
  final int? page;
  final DateTime? kindleDate;

  const ParsedHighlight({
    required this.bookTitle,
    this.author,
    required this.content,
    required this.type,
    this.location,
    this.page,
    this.kindleDate,
  });

  @override
  String toString() {
    return 'ParsedHighlight(bookTitle: $bookTitle, author: $author, type: $type, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}
