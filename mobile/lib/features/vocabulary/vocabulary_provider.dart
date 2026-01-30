import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

/// Provider for all vocabulary of the current user (sorted newest first)
final allVocabularyProvider = StreamProvider<List<Vocabulary>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final vocabRepo = ref.watch(vocabularyRepositoryProvider);
  return vocabRepo.watchAllForUser(userId);
});

/// Provider for a single vocabulary entry by ID
final vocabularyByIdProvider = FutureProvider.family<Vocabulary?, String>((
  ref,
  id,
) async {
  final vocabRepo = ref.watch(vocabularyRepositoryProvider);
  return vocabRepo.getById(id);
});

/// Provider for vocabulary count
final vocabularyCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final vocabRepo = ref.watch(vocabularyRepositoryProvider);
  return vocabRepo.countForUser(userId);
});

/// Provider for searching vocabulary
final vocabularySearchProvider =
    FutureProvider.family<List<Vocabulary>, String>((ref, query) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return [];
      if (query.isEmpty) return [];

      final vocabRepo = ref.watch(vocabularyRepositoryProvider);
      return vocabRepo.search(userId: userId, query: query);
    });
