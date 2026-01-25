import '../../../data/database/database.dart';
import '../../../data/repositories/highlight_repository.dart';

/// Service for searching highlights across the library
///
/// Currently uses simple LIKE search via the HighlightRepository.
/// Can be enhanced to use FTS5 for better performance and relevance ranking.
class SearchService {
  final HighlightRepository _highlightRepository;

  SearchService(this._highlightRepository);

  /// Search highlights by content
  ///
  /// Returns highlights where the content contains the query (case-insensitive).
  /// Results are ordered by relevance (currently by creation date).
  Future<List<Highlight>> searchHighlights({
    required String userId,
    required String query,
    String? bookId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Use repository's search method
    // This currently uses LIKE search but can be upgraded to FTS5
    final results = await _highlightRepository.search(
      userId: userId,
      query: query.trim(),
      bookId: bookId,
    );

    // Apply pagination manually since repository doesn't support it yet
    if (offset >= results.length) {
      return [];
    }

    final endIndex = (offset + limit) > results.length ? results.length : offset + limit;
    return results.sublist(offset, endIndex);
  }

  /// Search highlights with FTS5 (full-text search)
  ///
  /// This method will use FTS5 virtual table for better search performance
  /// and relevance ranking when implemented.
  Future<List<HighlightSearchResult>> searchWithRanking({
    required String userId,
    required String query,
    String? bookId,
    int limit = 50,
  }) async {
    // TODO: Implement FTS5 search with ranking
    // For now, fall back to simple search
    final highlights = await searchHighlights(
      userId: userId,
      query: query,
      bookId: bookId,
      limit: limit,
    );

    return highlights.map((h) => HighlightSearchResult(
      highlight: h,
      rank: 1.0, // Default rank until FTS5 is implemented
      snippet: _generateSnippet(h.content, query),
    )).toList();
  }

  /// Generate a snippet of content around the matched query
  String _generateSnippet(String content, String query, {int contextLength = 100}) {
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();

    final index = contentLower.indexOf(queryLower);
    if (index == -1) {
      // If query not found, return start of content
      return content.length > contextLength * 2
          ? '${content.substring(0, contextLength * 2)}...'
          : content;
    }

    // Calculate snippet boundaries
    final start = (index - contextLength).clamp(0, content.length);
    final end = (index + query.length + contextLength).clamp(0, content.length);

    final snippet = content.substring(start, end);
    final prefix = start > 0 ? '...' : '';
    final suffix = end < content.length ? '...' : '';

    return '$prefix$snippet$suffix';
  }
}

/// A search result with ranking information
class HighlightSearchResult {
  final Highlight highlight;
  final double rank;
  final String snippet;

  HighlightSearchResult({
    required this.highlight,
    required this.rank,
    required this.snippet,
  });
}
