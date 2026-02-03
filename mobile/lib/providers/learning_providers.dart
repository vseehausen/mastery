import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/services/distractor_service.dart';
import '../domain/services/enrichment_service.dart';
import '../domain/services/session_planner.dart';
import '../domain/services/srs_scheduler.dart';
import '../domain/services/telemetry_service.dart';
import 'supabase_provider.dart';

part 'learning_providers.g.dart';

// =============================================================================
// Service Providers
// =============================================================================

@riverpod
SrsScheduler srsScheduler(Ref ref, {double targetRetention = 0.90}) {
  return SrsScheduler(targetRetention: targetRetention);
}

@Riverpod(keepAlive: true)
TelemetryService telemetryService(Ref ref) {
  final dataService = ref.watch(supabaseDataServiceProvider);
  return TelemetryService(dataService);
}

@Riverpod(keepAlive: true)
SessionPlanner sessionPlanner(Ref ref) {
  final dataService = ref.watch(supabaseDataServiceProvider);
  final telemetryService = ref.watch(telemetryServiceProvider);
  final srsScheduler = ref.watch(srsSchedulerProvider());

  return SessionPlanner(
    dataService: dataService,
    telemetryService: telemetryService,
    srsScheduler: srsScheduler,
  );
}

@Riverpod(keepAlive: true)
DistractorService distractorService(Ref ref) {
  final dataService = ref.watch(supabaseDataServiceProvider);
  return DistractorService(dataService);
}

@Riverpod(keepAlive: true)
EnrichmentService enrichmentService(Ref ref) {
  final dataService = ref.watch(supabaseDataServiceProvider);
  return EnrichmentService(
    supabaseClient: Supabase.instance.client,
    dataService: dataService,
  );
}
