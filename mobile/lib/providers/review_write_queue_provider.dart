import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/review_write_queue.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with an actual SharedPreferences instance',
  );
});

/// Provider for the ReviewWriteQueue service
final reviewWriteQueueProvider = Provider<ReviewWriteQueue>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReviewWriteQueue(prefs);
});
