import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Languages, Books, Highlights, ImportSessions, SyncOutbox, Vocabularys])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed English language
        await into(languages).insert(LanguagesCompanion.insert(
          id: 'en-default',
          code: 'en',
          name: 'English',
          createdAt: DateTime.now(),
        ));
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from version 1 to 2: Add vocabulary table
        if (from < 2) {
          await m.createTable(vocabularys);
        }
        // Migration from version 2 to 3: Recreate vocabulary table with new schema
        if (from < 3) {
          await m.deleteTable('vocabularys');
          await m.createTable(vocabularys);
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
