import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

/// Provider for highlights of a specific book
final highlightsForBookProvider =
    FutureProvider.family<List<Highlight>, String>((ref, bookId) async {
  final highlightRepo = ref.watch(highlightRepositoryProvider);
  return highlightRepo.getForBook(bookId);
});

/// Provider for all highlights of the current user
final allHighlightsProvider = FutureProvider<List<Highlight>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final highlightRepo = ref.watch(highlightRepositoryProvider);
  return highlightRepo.getAllForUser(userId);
});

/// Provider for searching highlights
final highlightSearchProvider =
    FutureProvider.family<List<Highlight>, String>((ref, query) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  if (query.isEmpty) return [];

  final highlightRepo = ref.watch(highlightRepositoryProvider);
  return highlightRepo.search(userId: userId, query: query);
});
