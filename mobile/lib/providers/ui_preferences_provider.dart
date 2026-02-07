import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI preferences that are local to the app session.
///
/// This controls whether optional enrichment progress appears on Home.
/// It defaults to false to keep Home focused on learning actions.
final showEnrichmentProgressOnHomeProvider = StateProvider<bool>(
  (ref) => false,
);
