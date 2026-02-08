import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/supabase_data_service.dart';

/// Service that calls the enrich-vocabulary edge function.
/// Data is stored server-side and fetched via SupabaseDataService.
class EnrichmentService {
  EnrichmentService({
    required this.supabaseClient,
    required this.dataService,
  });

  final SupabaseClient supabaseClient;
  final SupabaseDataService dataService;

  static const int _bufferTarget = 10;
  static const int _replenishThreshold = 5;

  /// Check if the enrichment buffer needs replenishment and trigger if so.
  Future<void> replenishIfNeeded(String userId) async {
    final availableNewWords = await dataService.countEnrichedNewWords(userId);
    if (availableNewWords >= _replenishThreshold) {
      debugPrint(
        '[EnrichmentService] Buffer OK: $availableNewWords enriched new words (>= $_replenishThreshold)',
      );
      return;
    }

    debugPrint(
      '[EnrichmentService] Enrichment buffer low ($availableNewWords enriched new words < $_replenishThreshold), '
      'triggering replenishment',
    );

    final needed = (_bufferTarget - availableNewWords).clamp(1, 10);
    await requestEnrichment(userId: userId, batchSize: needed);
  }

  /// Request enrichment for specific vocabulary IDs or let server pick.
  Future<EnrichmentResult> requestEnrichment({
    required String userId,
    List<String>? vocabularyIds,
    int batchSize = 5,
    String languageCode = 'de',
    bool forceReEnrich = false,
  }) async {
    debugPrint(
      '[EnrichmentService] Requesting enrichment: language=$languageCode, '
      'batchSize=$batchSize, '
      'specificIds=${vocabularyIds?.length ?? 0}',
    );

    try {
      final body = <String, dynamic>{
        'native_language_code': languageCode,
        'batch_size': batchSize,
      };
      if (vocabularyIds != null && vocabularyIds.isNotEmpty) {
        body['vocabulary_ids'] = vocabularyIds;
      }
      if (forceReEnrich) {
        body['force_re_enrich'] = true;
      }

      final response = await supabaseClient.functions.invoke(
        'enrich-vocabulary/request',
        body: body,
      );

      if (response.status != 200) {
        debugPrint(
          '[EnrichmentService] Enrichment request failed: status=${response.status}',
        );
        return const EnrichmentResult(enrichedCount: 0, failedCount: 0);
      }

      final data = response.data as Map<String, dynamic>;
      final enriched = data['enriched'] as List<dynamic>? ?? [];
      final failed = data['failed'] as List<dynamic>? ?? [];
      final skipped = data['skipped'] as List<dynamic>? ?? [];

      final enrichedCount = enriched.length;
      final failedCount = failed.length;

      debugPrint(
        '[EnrichmentService] Enrichment complete: '
        '$enrichedCount enriched, $failedCount failed, ${skipped.length} skipped',
      );

      return EnrichmentResult(
        enrichedCount: enrichedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      debugPrint('[EnrichmentService] Enrichment request error: $e');
      return const EnrichmentResult(enrichedCount: 0, failedCount: 0);
    }
  }

  /// Re-enrich a specific vocabulary word, e.g. after language change.
  /// Server handles soft-deleting existing meanings.
  Future<EnrichmentResult> reEnrich({
    required String userId,
    required String vocabularyId,
    String languageCode = 'de',
  }) async {
    developer.log(
      'Re-enriching vocabulary $vocabularyId for user $userId',
      name: 'EnrichmentService',
    );

    // Request fresh enrichment for this specific word
    return requestEnrichment(
      userId: userId,
      vocabularyIds: [vocabularyId],
      batchSize: 1,
      languageCode: languageCode,
      forceReEnrich: true,
    );
  }

  /// Get the current buffer status.
  Future<BufferStatus> getBufferStatus(String userId) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'enrich-vocabulary/status',
        method: HttpMethod.get,
      );

      if (response.status != 200) {
        return const BufferStatus(
          enrichedCount: 0,
          unEnrichedCount: 0,
          bufferTarget: _bufferTarget,
          needsReplenishment: true,
        );
      }

      final data = response.data as Map<String, dynamic>;
      return BufferStatus(
        enrichedCount: data['enriched_count'] as int? ?? 0,
        unEnrichedCount: data['un_enriched_count'] as int? ?? 0,
        bufferTarget: data['buffer_target'] as int? ?? _bufferTarget,
        needsReplenishment: data['needs_replenishment'] as bool? ?? true,
      );
    } catch (e) {
      developer.log(
        'Buffer status check failed: $e',
        name: 'EnrichmentService',
        level: 900,
      );
      return const BufferStatus(
        enrichedCount: 0,
        unEnrichedCount: 0,
        bufferTarget: _bufferTarget,
        needsReplenishment: true,
      );
    }
  }
}

/// Result of an enrichment request
class EnrichmentResult {
  const EnrichmentResult({
    required this.enrichedCount,
    required this.failedCount,
  });

  final int enrichedCount;
  final int failedCount;
}

/// Current state of the enrichment buffer
class BufferStatus {
  const BufferStatus({
    required this.enrichedCount,
    required this.unEnrichedCount,
    required this.bufferTarget,
    required this.needsReplenishment,
  });

  final int enrichedCount;
  final int unEnrichedCount;
  final int bufferTarget;
  final bool needsReplenishment;
}
