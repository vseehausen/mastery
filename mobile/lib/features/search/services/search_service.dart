import '../../../data/database/database.dart';
import '../../../data/repositories/vocabulary_repository.dart';

/// Service for searching vocabulary across the library
class SearchService {
  final VocabularyRepository _vocabularyRepository;

  SearchService(this._vocabularyRepository);

  /// Search vocabulary by word or context
  Future<List<Vocabulary>> searchVocabulary({
    required String userId,
    required String query,
    int limit = 50,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final results = await _vocabularyRepository.search(
      userId: userId,
      query: query.trim(),
    );

    if (offset >= results.length) {
      return [];
    }

    final endIndex = (offset + limit) > results.length ? results.length : offset + limit;
    return results.sublist(offset, endIndex);
  }
}
