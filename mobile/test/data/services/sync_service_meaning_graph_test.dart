import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastery/data/database/database.dart';
import 'package:mastery/data/repositories/confusable_set_repository.dart';
import 'package:mastery/data/repositories/cue_repository.dart';
import 'package:mastery/data/repositories/meaning_repository.dart';

void main() {
  late AppDatabase db;
  late MeaningRepository meaningRepo;
  late CueRepository cueRepo;
  late ConfusableSetRepository confusableSetRepo;

  const userId = 'test-user-sync';
  const vocabId = 'vocab-sync-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    meaningRepo = MeaningRepository(db);
    cueRepo = CueRepository(db);
    confusableSetRepo = ConfusableSetRepository(db);

    // Insert prerequisite vocabulary
    await db.into(db.vocabularys).insert(VocabularysCompanion.insert(
      id: vocabId,
      userId: userId,
      word: 'ephemeral',
      contentHash: 'hash-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() => db.close());

  group('Meaning graph sync - push data collection', () {
    test('newly created meanings are pending sync', () async {
      final meaning = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'lasting a very short time',
        isPrimary: true,
      );

      final pending = await meaningRepo.getPendingSync();
      expect(pending.length, 1);
      expect(pending.first.id, meaning.id);
      expect(pending.first.isPendingSync, true);
    });

    test('updated meanings are pending sync with incremented version', () async {
      final meaning = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'lasting a short time',
        isPrimary: true,
      );

      await meaningRepo.markSynced(meaning.id);
      var pending = await meaningRepo.getPendingSync();
      expect(pending, isEmpty);

      await meaningRepo.update(
        id: meaning.id,
        primaryTranslation: 'kurzlebig',
      );

      pending = await meaningRepo.getPendingSync();
      expect(pending.length, 1);
      expect(pending.first.version, 2);
    });

    test('pinAsPrimary marks affected meanings as pending sync', () async {
      final m1 = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'lasting a short time',
        isPrimary: true,
      );
      final m2 = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'kurzlebig',
        englishDefinition: 'short-lived',
      );

      await meaningRepo.markSynced(m1.id);
      await meaningRepo.markSynced(m2.id);

      await meaningRepo.pinAsPrimary(m2.id);

      final pending = await meaningRepo.getPendingSync();
      expect(pending.length, 2);
    });

    test('soft-deleted meanings are pending sync', () async {
      final meaning = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'short-lived',
        isPrimary: true,
      );

      await meaningRepo.markSynced(meaning.id);
      await meaningRepo.softDelete(meaning.id);

      final pending = await meaningRepo.getPendingSync();
      expect(pending.length, 1);
      expect(pending.first.deletedAt, isNotNull);
    });

    test('markSynced clears pending flag and sets lastSyncedAt', () async {
      final meaning = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'short-lived',
        isPrimary: true,
      );

      await meaningRepo.markSynced(meaning.id);
      final synced = await meaningRepo.getById(meaning.id);

      expect(synced!.isPendingSync, false);
      expect(synced.lastSyncedAt, isNotNull);
    });

    test('newly created cues are pending sync', () async {
      final meaning = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'short-lived',
        isPrimary: true,
      );

      final cue = await cueRepo.create(
        userId: userId,
        meaningId: meaning.id,
        cueType: 'translation',
        promptText: 'vergaenglich',
        answerText: 'ephemeral',
      );

      final pending = await cueRepo.getPendingSync();
      expect(pending.length, 1);
      expect(pending.first.id, cue.id);
    });

    test('confusable sets are pending sync after creation', () async {
      final set = await confusableSetRepo.create(
        userId: userId,
        languageCode: 'de',
        words: '["ephemeral","temporal"]',
        explanations: '{"temporal":"relating to time"}',
        vocabularyIds: [vocabId],
      );

      final pending = await confusableSetRepo.getPendingSync();
      expect(pending.length, 1);
      expect(pending.first.id, set.id);
    });
  });

  group('Meaning graph sync - pull data storage', () {
    test('meanings can be inserted via companion for pull', () async {
      final now = DateTime.now().toUtc();
      final entry = MeaningsCompanion(
        id: const Value('meaning-pull-1'),
        userId: const Value(userId),
        vocabularyId: const Value(vocabId),
        languageCode: const Value('de'),
        primaryTranslation: const Value('vergaenglich'),
        alternativeTranslations: const Value('["kurzlebig"]'),
        englishDefinition: const Value('lasting a very short time'),
        extendedDefinition: const Value.absent(),
        partOfSpeech: const Value('adjective'),
        synonyms: const Value('["fleeting"]'),
        confidence: const Value(0.95),
        isPrimary: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(0),
        source: const Value('ai'),
        createdAt: Value(now),
        updatedAt: Value(now),
        lastSyncedAt: Value(now),
        isPendingSync: const Value(false),
        version: const Value(1),
      );

      await db.into(db.meanings).insertOnConflictUpdate(entry);

      final meanings = await meaningRepo.getForVocabulary(vocabId);
      expect(meanings.length, 1);
      expect(meanings.first.primaryTranslation, 'vergaenglich');
      expect(meanings.first.isPendingSync, false);
    });

    test('cues can be inserted via companion for pull', () async {
      final now = DateTime.now().toUtc();

      // Insert meaning first
      await db.into(db.meanings).insert(MeaningsCompanion.insert(
        id: 'meaning-pull-2',
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'short-lived',
        createdAt: now,
        updatedAt: now,
      ));

      final entry = CuesCompanion(
        id: const Value('cue-pull-1'),
        userId: const Value(userId),
        meaningId: const Value('meaning-pull-2'),
        cueType: const Value('translation'),
        promptText: const Value('vergaenglich'),
        answerText: const Value('ephemeral'),
        hintText: const Value.absent(),
        metadata: const Value('{}'),
        createdAt: Value(now),
        updatedAt: Value(now),
        lastSyncedAt: Value(now),
        isPendingSync: const Value(false),
        version: const Value(1),
      );

      await db.into(db.cues).insertOnConflictUpdate(entry);

      final cues = await cueRepo.getForMeaning('meaning-pull-2');
      expect(cues.length, 1);
      expect(cues.first.cueType, 'translation');
      expect(cues.first.isPendingSync, false);
    });

    test('confusable sets can be inserted via companion for pull', () async {
      final now = DateTime.now().toUtc();
      final entry = ConfusableSetsCompanion(
        id: const Value('cs-pull-1'),
        userId: const Value(userId),
        languageCode: const Value('de'),
        words: const Value('["ephemeral","temporal"]'),
        explanations: const Value('{"temporal":"relating to time"}'),
        exampleSentences: const Value('{}'),
        createdAt: Value(now),
        updatedAt: Value(now),
        lastSyncedAt: Value(now),
        isPendingSync: const Value(false),
        version: const Value(1),
      );

      await db.into(db.confusableSets).insertOnConflictUpdate(entry);

      // Link member
      await db.into(db.confusableSetMembers).insert(
        ConfusableSetMembersCompanion.insert(
          id: 'csm-pull-1',
          confusableSetId: 'cs-pull-1',
          vocabularyId: vocabId,
          createdAt: now,
        ),
      );

      final sets = await confusableSetRepo.getForVocabulary(vocabId);
      expect(sets.length, 1);
      expect(sets.first.words, '["ephemeral","temporal"]');
    });

    test('pull overwrites local data via insertOnConflictUpdate', () async {
      final now = DateTime.now().toUtc();

      // Create local meaning
      final meaning = await meaningRepo.create(
        userId: userId,
        vocabularyId: vocabId,
        languageCode: 'de',
        primaryTranslation: 'vergaenglich',
        englishDefinition: 'short-lived',
        isPrimary: true,
      );

      // Simulate pull with updated data
      final entry = MeaningsCompanion(
        id: Value(meaning.id),
        userId: const Value(userId),
        vocabularyId: const Value(vocabId),
        languageCode: const Value('de'),
        primaryTranslation: const Value('kurzlebig'),
        alternativeTranslations: const Value('[]'),
        englishDefinition: const Value('short-lived (updated)'),
        partOfSpeech: const Value('adjective'),
        synonyms: const Value('[]'),
        confidence: const Value(0.9),
        isPrimary: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(0),
        source: const Value('ai'),
        createdAt: Value(now),
        updatedAt: Value(now),
        lastSyncedAt: Value(now),
        isPendingSync: const Value(false),
        version: const Value(2),
      );

      await db.into(db.meanings).insertOnConflictUpdate(entry);

      final updated = await meaningRepo.getById(meaning.id);
      expect(updated!.primaryTranslation, 'kurzlebig');
      expect(updated.englishDefinition, 'short-lived (updated)');
      expect(updated.version, 2);
      expect(updated.isPendingSync, false);
    });
  });
}
