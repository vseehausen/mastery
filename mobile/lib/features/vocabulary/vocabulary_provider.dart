// Re-export vocabulary providers from the centralized supabase_providers
// These are the main providers that should be used throughout the app
export '../../providers/supabase_provider.dart'
    show
        vocabularyListProvider,
        vocabularyByIdProvider,
        vocabularyCountProvider,
        vocabularySearchProvider,
        enrichedVocabularyIdsProvider;

// Alias for backward compatibility
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/vocabulary.dart';
import '../../providers/supabase_provider.dart' as sp;

/// Provider for all vocabulary of the current user (sorted newest first)
/// Alias for backward compatibility with existing code
final allVocabularyProvider =
    FutureProvider.autoDispose<List<VocabularyModel>>((ref) {
  return ref.watch(sp.vocabularyListProvider.future);
});
