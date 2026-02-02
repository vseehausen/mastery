import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Languages,
    Sources,
    Encounters,
    ImportSessions,
    SyncOutbox,
    Vocabularys,
    // Learning feature tables (004-calm-srs-learning)
    LearningCards,
    ReviewLogs,
    LearningSessions,
    UserLearningPreferences,
    Streaks,
    // Meaning graph tables (005-meaning-graph)
    Meanings,
    Cues,
    ConfusableSets,
    ConfusableSetMembers,
    MeaningEdits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed English language
        await into(languages).insert(
          LanguagesCompanion.insert(
            id: 'en-default',
            code: 'en',
            name: 'English',
            createdAt: DateTime.now(),
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Destructive migration: drop old tables, create new ones
        if (from < 5) {
          // Drop old tables that no longer exist
          await m.deleteTable('books');
          await m.deleteTable('highlights');

          // Recreate vocabulary without book fields
          await m.deleteTable('vocabularys');
          await m.createTable(vocabularys);

          // Create new tables
          await m.createTable(sources);
          await m.createTable(encounters);

          // Ensure learning tables exist
          if (from < 4) {
            await m.createTable(learningCards);
            await m.createTable(reviewLogs);
            await m.createTable(learningSessions);
            await m.createTable(userLearningPreferences);
            await m.createTable(streaks);
          }
        }
        // 005-meaning-graph: Add meaning graph tables and new columns
        if (from < 6) {
          await m.createTable(meanings);
          await m.createTable(cues);
          await m.createTable(confusableSets);
          await m.createTable(confusableSetMembers);
          await m.createTable(meaningEdits);
          // Add new columns to existing tables
          await m.addColumn(
              userLearningPreferences, userLearningPreferences.nativeLanguageCode);
          await m.addColumn(
              userLearningPreferences, userLearningPreferences.meaningDisplayMode);
          await m.addColumn(reviewLogs, reviewLogs.cueType);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mastery.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
