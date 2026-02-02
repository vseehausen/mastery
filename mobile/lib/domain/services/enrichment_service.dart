import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/database/database.dart';
import '../../data/repositories/cue_repository.dart';
import '../../data/repositories/confusable_set_repository.dart';
import '../../data/repositories/meaning_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';

/// Service that calls the enrich-vocabulary edge function and stores results locally.
class EnrichmentService {
  EnrichmentService({
    required this.supabaseClient,
    required this.meaningRepository,
    required this.cueRepository,
    required this.confusableSetRepository,
    required this.userPreferencesRepository,
  });

  final SupabaseClient supabaseClient;
  final MeaningRepository meaningRepository;
  final CueRepository cueRepository;
  final ConfusableSetRepository confusableSetRepository;
  final UserPreferencesRepository userPreferencesRepository;

  static const int _bufferTarget = 10;
  static const int _replenishThreshold = 5;

  /// Check if the enrichment buffer needs replenishment and trigger if so.
  Future<void> replenishIfNeeded(String userId) async {
    final enrichedCount = await meaningRepository.getEnrichedCount(userId);
    if (enrichedCount >= _replenishThreshold) return;

    developer.log(
      'Enrichment buffer low ($enrichedCount < $_replenishThreshold), '
      'triggering replenishment',
      name: 'EnrichmentService',
    );

    await requestEnrichment(userId: userId);
  }

  /// Request enrichment for specific vocabulary IDs or let server pick.
  Future<EnrichmentResult> requestEnrichment({
    required String userId,
    List<String>? vocabularyIds,
    int batchSize = 5,
  }) async {
    final prefs = await userPreferencesRepository.getOrCreateWithDefaults(userId);
    final languageCode = prefs.nativeLanguageCode;

    developer.log(
      'Requesting enrichment: language=$languageCode, '
      'batchSize=$batchSize, '
      'specificIds=${vocabularyIds?.length ?? 0}',
      name: 'EnrichmentService',
    );

    try {
      final body = <String, dynamic>{
        'native_language_code': languageCode,
        'batch_size': batchSize,
      };
      if (vocabularyIds != null && vocabularyIds.isNotEmpty) {
        body['vocabulary_ids'] = vocabularyIds;
      }

      final response = await supabaseClient.functions.invoke(
        'enrich-vocabulary/request',
        body: body,
      );

      if (response.status != 200) {
        developer.log(
          'Enrichment request failed: status=${response.status}',
          name: 'EnrichmentService',
          level: 900,
        );
        return const EnrichmentResult(enrichedCount: 0, failedCount: 0);
      }

      final data = response.data as Map<String, dynamic>;
      final enriched = data['enriched'] as List<dynamic>? ?? [];
      final failed = data['failed'] as List<dynamic>? ?? [];

      // Store enriched results locally
      for (final item in enriched) {
        final map = item as Map<String, dynamic>;
        await _storeEnrichedWord(userId, map);
      }

      developer.log(
        'Enrichment complete: ${enriched.length} enriched, '
        '${failed.length} failed',
        name: 'EnrichmentService',
      );

      return EnrichmentResult(
        enrichedCount: enriched.length,
        failedCount: failed.length,
      );
    } catch (e, st) {
      developer.log(
        'Enrichment request error: $e',
        name: 'EnrichmentService',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      return const EnrichmentResult(enrichedCount: 0, failedCount: 0);
    }
  }

  /// Re-enrich a specific vocabulary word, e.g. after language change.
  /// Soft-deletes existing meanings and requests fresh enrichment.
  Future<EnrichmentResult> reEnrich({
    required String userId,
    required String vocabularyId,
  }) async {
    developer.log(
      'Re-enriching vocabulary $vocabularyId for user $userId',
      name: 'EnrichmentService',
    );

    // Soft-delete existing meanings for this vocabulary
    final existingMeanings = await meaningRepository.getForVocabulary(
      vocabularyId,
    );
    for (final meaning in existingMeanings) {
      await meaningRepository.softDelete(meaning.id);
    }

    // Request fresh enrichment for this specific word
    return requestEnrichment(
      userId: userId,
      vocabularyIds: [vocabularyId],
      batchSize: 1,
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

  Future<void> _storeEnrichedWord(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final vocabularyId = data['vocabulary_id'] as String;
    final meaningsData = data['meanings'] as List<dynamic>? ?? [];

    for (final meaningData in meaningsData) {
      final md = meaningData as Map<String, dynamic>;
      final meaningId = md['id'] as String;

      // Insert meaning
      final alternativeTranslations =
          (md['alternative_translations'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
      final synonyms = (md['synonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final now = DateTime.now().toUtc();
      await meaningRepository.bulkInsert([
        MeaningsCompanion(
          id: Value(meaningId),
          userId: Value(userId),
          vocabularyId: Value(vocabularyId),
          languageCode: Value(md['language_code'] as String? ?? 'de'),
          primaryTranslation: Value(md['primary_translation'] as String),
          alternativeTranslations:
              Value(jsonEncode(alternativeTranslations)),
          englishDefinition: Value(md['english_definition'] as String),
          extendedDefinition:
              Value(md['extended_definition'] as String?),
          partOfSpeech: Value(md['part_of_speech'] as String?),
          synonyms: Value(jsonEncode(synonyms)),
          confidence:
              Value((md['confidence'] as num?)?.toDouble() ?? 1.0),
          isPrimary: Value(md['is_primary'] as bool? ?? false),
          isActive: const Value(true),
          sortOrder: Value(md['sort_order'] as int? ?? 0),
          source: Value(md['source'] as String? ?? 'ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      // Insert cues
      final cuesData = md['cues'] as List<dynamic>? ?? [];
      final cueCompanions = <CuesCompanion>[];
      for (final cueData in cuesData) {
        final cd = cueData as Map<String, dynamic>;
        cueCompanions.add(CuesCompanion(
          id: Value(cd['id'] as String),
          userId: Value(userId),
          meaningId: Value(meaningId),
          cueType: Value(cd['cue_type'] as String),
          promptText: Value(cd['prompt_text'] as String),
          answerText: Value(cd['answer_text'] as String),
          hintText: Value(cd['hint_text'] as String?),
          metadata: Value(
              jsonEncode(cd['metadata'] as Map<String, dynamic>? ?? {})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ));
      }
      if (cueCompanions.isNotEmpty) {
        await cueRepository.bulkInsert(cueCompanions);
      }
    }

    // Insert confusable set if present
    final confusableData = data['confusable_set'] as Map<String, dynamic>?;
    if (confusableData != null) {
      final now = DateTime.now().toUtc();
      final setId = confusableData['id'] as String;

      await confusableSetRepository.bulkInsertSets([
        ConfusableSetsCompanion(
          id: Value(setId),
          userId: Value(userId),
          languageCode: Value(
              confusableData['language_code'] as String? ?? 'de'),
          words: Value(jsonEncode(confusableData['words'])),
          explanations: Value(jsonEncode(confusableData['explanations'])),
          exampleSentences: Value(
              jsonEncode(confusableData['example_sentences'] ?? {})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      // Link vocabulary to confusable set
      await confusableSetRepository.bulkInsertMembers([
        ConfusableSetMembersCompanion(
          id: Value('${setId}_$vocabularyId'),
          confusableSetId: Value(setId),
          vocabularyId: Value(vocabularyId),
          createdAt: Value(now),
        ),
      ]);
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
