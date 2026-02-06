import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for development mode toggle.
///
/// This is an in-memory state that resets to `false` on app restart.
/// Used to enable dev-only features like manual session enrichment triggers.
final devModeProvider = StateProvider<bool>((ref) => false);
