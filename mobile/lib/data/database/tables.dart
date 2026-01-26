import 'package:drift/drift.dart';

/// Languages table - supported learning languages
class Languages extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().withLength(max: 5)();
  TextColumn get name => text().withLength(max: 50)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Books table - source books containing highlights
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get languageId => text().nullable()();
  TextColumn get title => text().withLength(max: 500)();
  TextColumn get author => text().withLength(max: 255).nullable()();
  TextColumn get asin => text().withLength(max: 20).nullable()();
  IntColumn get highlightCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Highlights table - individual text passages from books
class Highlights extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get bookId => text()();
  TextColumn get content => text()();
  TextColumn get type => text()(); // 'highlight' or 'note'
  TextColumn get location => text().nullable()();
  IntColumn get page => integer().nullable()();
  DateTimeColumn get kindleDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get context => text().nullable()();
  TextColumn get contentHash => text().withLength(max: 64)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Import sessions table - records of import operations
class ImportSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get source => text()(); // 'file' or 'device'
  TextColumn get filename => text().nullable()();
  TextColumn get deviceName => text().nullable()();
  IntColumn get totalFound => integer()();
  IntColumn get imported => integer()();
  IntColumn get skipped => integer()();
  IntColumn get errors => integer().withDefault(const Constant(0))();
  TextColumn get errorDetails => text().nullable()(); // JSON array
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Vocabulary table - words looked up on Kindle via Vocabulary Builder
class Vocabularys extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get word => text().withLength(max: 100)();
  TextColumn get stem => text().withLength(max: 100).nullable()();
  TextColumn get context => text().nullable()();
  TextColumn get bookTitle => text().nullable()();
  TextColumn get bookAuthor => text().nullable()();
  TextColumn get bookAsin => text().withLength(max: 20).nullable()();
  DateTimeColumn get lookupTimestamp => dateTime().nullable()();
  TextColumn get contentHash => text().withLength(max: 64)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync outbox table - queue for pending sync operations (local only)
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable => text()(); // 'books' or 'highlights'
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
