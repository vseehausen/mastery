import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';

/// Provider for all books of the current user
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final bookRepo = ref.watch(bookRepositoryProvider);
  return bookRepo.getAllForUser(userId);
});

/// Provider for a single book by ID
final bookByIdProvider =
    FutureProvider.family<Book?, String>((ref, bookId) async {
  final bookRepo = ref.watch(bookRepositoryProvider);
  return bookRepo.getById(bookId);
});
