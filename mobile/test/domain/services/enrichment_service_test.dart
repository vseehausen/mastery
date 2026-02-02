import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/confusable_set_repository.dart';
import 'package:mastery/data/repositories/cue_repository.dart';
import 'package:mastery/data/repositories/meaning_repository.dart';
import 'package:mastery/data/repositories/user_preferences_repository.dart';
import 'package:mastery/domain/services/enrichment_service.dart';

/// Tests for EnrichmentService local storage logic.
/// These verify that enrichment responses are correctly parsed and stored
/// in the local SQLite database via repositories.
void main() {
  late AppDatabase db;
  late MeaningRepository meaningRepo;
  late CueRepository cueRepo;
  late ConfusableSetRepository confusableSetRepo;
  late UserPreferencesRepository userPrefsRepo;

  const userId = 'test-user-123';
  const vocabularyId = 'vocab-abc';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    meaningRepo = MeaningRepository(db);
    cueRepo = CueRepository(db);
    confusableSetRepo = ConfusableSetRepository(db);
    userPrefsRepo = UserPreferencesRepository(db);

    // Create user preferences
    await userPrefsRepo.getOrCreateWithDefaults(userId);

    // Create a vocabulary entry
    final now = DateTime.now().toUtc();
    await db.into(db.vocabularys).insert(VocabularysCompanion.insert(
      id: vocabularyId,
      userId: userId,
      word: 'efficient',
      contentHash: 'hash-efficient',
      createdAt: now,
      updatedAt: now,
    ));
  });

  tearDown(() => db.close());

  group('EnrichmentService - local storage', () {
    test('stores meanings from enrichment response', () async {
      // Simulate storing enriched data (the same logic EnrichmentService uses)
      final now = DateTime.now().toUtc();
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-1'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('effizient'),
          alternativeTranslations: Value(jsonEncode(['leistungsfähig'])),
          englishDefinition:
              const Value('Achieving results with minimal waste.'),
          partOfSpeech: const Value('adjective'),
          synonyms: Value(jsonEncode(['effective', 'productive'])),
          confidence: const Value(0.95),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final meanings = await meaningRepo.getForVocabulary(vocabularyId);
      expect(meanings.length, 1);
      expect(meanings[0].primaryTranslation, 'effizient');
      expect(meanings[0].englishDefinition,
          'Achieving results with minimal waste.');
      expect(meanings[0].isPrimary, true);
      expect(meanings[0].confidence, 0.95);
      expect(meanings[0].source, 'ai');
    });

    test('stores multiple meanings for ambiguous words', () async {
      final now = DateTime.now().toUtc();
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-bank-1'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('Ufer'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('The side of a river.'),
          confidence: const Value(0.9),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
        MeaningsCompanion(
          id: const Value('meaning-bank-2'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('Bank'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('A financial institution.'),
          confidence: const Value(0.9),
          isPrimary: const Value(false),
          isActive: const Value(true),
          sortOrder: const Value(1),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final meanings = await meaningRepo.getForVocabulary(vocabularyId);
      expect(meanings.length, 2);
      expect(meanings[0].isPrimary, true);
      expect(meanings[1].isPrimary, false);
    });

    test('stores cues linked to meanings', () async {
      final now = DateTime.now().toUtc();

      // Create meaning first
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-cue-test'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('effizient'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('Achieves results with minimal waste.'),
          confidence: const Value(0.95),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      // Create cues
      await cueRepo.bulkInsert([
        CuesCompanion(
          id: const Value('cue-translation'),
          userId: const Value(userId),
          meaningId: const Value('meaning-cue-test'),
          cueType: const Value('translation'),
          promptText: const Value('effizient'),
          answerText: const Value('efficient'),
          metadata: Value(jsonEncode({})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
        CuesCompanion(
          id: const Value('cue-definition'),
          userId: const Value(userId),
          meaningId: const Value('meaning-cue-test'),
          cueType: const Value('definition'),
          promptText: const Value('Achieves results with minimal waste.'),
          answerText: const Value('efficient'),
          metadata: Value(jsonEncode({})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
        CuesCompanion(
          id: const Value('cue-synonym'),
          userId: const Value(userId),
          meaningId: const Value('meaning-cue-test'),
          cueType: const Value('synonym'),
          promptText: const Value('effective, productive'),
          answerText: const Value('efficient'),
          metadata: Value(jsonEncode({})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final cues = await cueRepo.getForVocabulary(vocabularyId);
      expect(cues.length, 3);

      final cueTypes = cues.map((c) => c.cueType).toSet();
      expect(cueTypes, containsAll(['translation', 'definition', 'synonym']));
    });

    test('stores confusable sets linked to vocabulary', () async {
      final now = DateTime.now().toUtc();

      await confusableSetRepo.bulkInsertSets([
        ConfusableSetsCompanion(
          id: const Value('confusable-set-1'),
          userId: const Value(userId),
          languageCode: const Value('de'),
          words: Value(jsonEncode(['efficient', 'effective', 'efficacious'])),
          explanations: Value(jsonEncode({
            'effective': 'Producing the desired result',
            'efficacious': 'Having the power to produce a desired effect',
          })),
          exampleSentences: Value(jsonEncode({
            'effective': 'The treatment was very effective.',
          })),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      await confusableSetRepo.bulkInsertMembers([
        ConfusableSetMembersCompanion(
          id: const Value('member-1'),
          confusableSetId: const Value('confusable-set-1'),
          vocabularyId: const Value(vocabularyId),
          createdAt: Value(now),
        ),
      ]);

      final hasConfusables =
          await confusableSetRepo.hasConfusables(vocabularyId);
      expect(hasConfusables, true);

      final sets = await confusableSetRepo.getForVocabulary(vocabularyId);
      expect(sets.length, 1);
      expect(sets[0].id, 'confusable-set-1');
    });

    test('hasEnrichedMeanings returns correct status', () async {
      // Before enrichment
      var hasMeanings =
          await meaningRepo.hasEnrichedMeanings(vocabularyId);
      expect(hasMeanings, false);

      // After enrichment
      final now = DateTime.now().toUtc();
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-check'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('test'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('A test.'),
          confidence: const Value(0.9),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      hasMeanings = await meaningRepo.hasEnrichedMeanings(vocabularyId);
      expect(hasMeanings, true);
    });

    test('getEnrichedCount returns correct count', () async {
      // Create another vocabulary
      final now = DateTime.now().toUtc();
      await db.into(db.vocabularys).insert(VocabularysCompanion.insert(
        id: 'vocab-xyz',
        userId: userId,
        word: 'test',
        contentHash: 'hash-test',
        createdAt: now,
        updatedAt: now,
      ));

      // Add meanings for first word
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-count-1'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('effizient'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('Efficient.'),
          confidence: const Value(0.9),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final count = await meaningRepo.getEnrichedCount(userId);
      expect(count, 1); // Only one vocabulary has meanings

      // Add meaning for second word
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-count-2'),
          userId: const Value(userId),
          vocabularyId: const Value('vocab-xyz'),
          languageCode: const Value('de'),
          primaryTranslation: const Value('Test'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('A test.'),
          confidence: const Value(0.9),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final count2 = await meaningRepo.getEnrichedCount(userId);
      expect(count2, 2);
    });

    test('cue repository filters by cue type', () async {
      final now = DateTime.now().toUtc();

      // Create meaning
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-filter'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('test'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('A test.'),
          confidence: const Value(0.9),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      // Create multiple cue types
      await cueRepo.bulkInsert([
        CuesCompanion(
          id: const Value('cue-t'),
          userId: const Value(userId),
          meaningId: const Value('meaning-filter'),
          cueType: const Value('translation'),
          promptText: const Value('test'),
          answerText: const Value('test'),
          metadata: Value(jsonEncode({})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
        CuesCompanion(
          id: const Value('cue-d'),
          userId: const Value(userId),
          meaningId: const Value('meaning-filter'),
          cueType: const Value('definition'),
          promptText: const Value('A test.'),
          answerText: const Value('test'),
          metadata: Value(jsonEncode({})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      // Filter by type
      final translationCues =
          await cueRepo.getForMeaning('meaning-filter', cueType: 'translation');
      expect(translationCues.length, 1);
      expect(translationCues[0].cueType, 'translation');

      final definitionCues =
          await cueRepo.getForMeaning('meaning-filter', cueType: 'definition');
      expect(definitionCues.length, 1);
      expect(definitionCues[0].cueType, 'definition');

      // All cues
      final allCues = await cueRepo.getForMeaning('meaning-filter');
      expect(allCues.length, 2);
    });

    test('disambiguation cue stores options in metadata', () async {
      final now = DateTime.now().toUtc();

      // Create meaning
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-disambig'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('effizient'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition: const Value('Achieves results with minimal waste.'),
          confidence: const Value(0.95),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('ai'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      // Create disambiguation cue with options in metadata
      final metadata = jsonEncode({
        'options': ['efficient', 'effective', 'efficacious'],
        'explanations': {
          'effective': 'Producing the desired result',
          'efficacious': 'Having the power to produce a desired effect',
        },
      });

      await cueRepo.bulkInsert([
        CuesCompanion(
          id: const Value('cue-disambig'),
          userId: const Value(userId),
          meaningId: const Value('meaning-disambig'),
          cueType: const Value('disambiguation'),
          promptText: const Value(
              'Choose the word that means: Achieves results with minimal waste.'),
          answerText: const Value('efficient'),
          metadata: Value(metadata),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final cues = await cueRepo.getForMeaning('meaning-disambig',
          cueType: 'disambiguation');
      expect(cues.length, 1);
      expect(cues[0].cueType, 'disambiguation');

      // Verify metadata contains options
      final parsedMetadata =
          jsonDecode(cues[0].metadata) as Map<String, dynamic>;
      expect(parsedMetadata['options'], isA<List<dynamic>>());
      expect((parsedMetadata['options'] as List).length, 3);
    });

    test('context cloze cue stores full sentence in metadata', () async {
      final now = DateTime.now().toUtc();

      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-cloze'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('effizient'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition:
              const Value('Used in context: "An efficient process."'),
          confidence: const Value(0.3),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('context'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      await cueRepo.bulkInsert([
        CuesCompanion(
          id: const Value('cue-cloze'),
          userId: const Value(userId),
          meaningId: const Value('meaning-cloze'),
          cueType: const Value('context_cloze'),
          promptText: const Value('An ___ process.'),
          answerText: const Value('efficient'),
          metadata:
              Value(jsonEncode({'full_sentence': 'An efficient process.'})),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final cues =
          await cueRepo.getForMeaning('meaning-cloze', cueType: 'context_cloze');
      expect(cues.length, 1);
      expect(cues[0].promptText, 'An ___ process.');
      expect(cues[0].answerText, 'efficient');

      final parsedMetadata =
          jsonDecode(cues[0].metadata) as Map<String, dynamic>;
      expect(parsedMetadata['full_sentence'], 'An efficient process.');
    });

    test('low-confidence meanings from DeepL/Google fallbacks', () async {
      final now = DateTime.now().toUtc();

      // DeepL fallback result (confidence 0.6)
      await meaningRepo.bulkInsert([
        MeaningsCompanion(
          id: const Value('meaning-deepl'),
          userId: const Value(userId),
          vocabularyId: const Value(vocabularyId),
          languageCode: const Value('de'),
          primaryTranslation: const Value('effizient'),
          alternativeTranslations: Value(jsonEncode([])),
          englishDefinition:
              const Value('efficient (translated via DeepL)'),
          confidence: const Value(0.6),
          isPrimary: const Value(true),
          isActive: const Value(true),
          sortOrder: const Value(0),
          source: const Value('deepl'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPendingSync: const Value(false),
          version: const Value(1),
        ),
      ]);

      final meanings = await meaningRepo.getForVocabulary(vocabularyId);
      expect(meanings.length, 1);
      expect(meanings[0].confidence, 0.6);
      expect(meanings[0].source, 'deepl');
    });
  });

  group('EnrichmentResult', () {
    test('represents enrichment outcome', () {
      const result =
          EnrichmentResult(enrichedCount: 3, failedCount: 1);
      expect(result.enrichedCount, 3);
      expect(result.failedCount, 1);
    });
  });

  group('BufferStatus', () {
    test('represents buffer state', () {
      const status = BufferStatus(
        enrichedCount: 8,
        unEnrichedCount: 12,
        bufferTarget: 10,
        needsReplenishment: false,
      );
      expect(status.enrichedCount, 8);
      expect(status.unEnrichedCount, 12);
      expect(status.bufferTarget, 10);
      expect(status.needsReplenishment, false);
    });
  });
}
