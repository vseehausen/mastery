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

/// Sources table - origin container (book, website, document, manual)
class Sources extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // 'book', 'website', 'document', 'manual'
  TextColumn get title => text().withLength(max: 500)();
  TextColumn get author => text().withLength(max: 255).nullable()();
  TextColumn get asin => text().withLength(max: 50).nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get domain => text().withLength(max: 255).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Encounters table - a vocabulary word seen in a source, with context
class Encounters extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get vocabularyId => text()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get context => text().nullable()();
  TextColumn get locatorJson => text().nullable()();
  DateTimeColumn get occurredAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();
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

/// Vocabulary table - word identity only
class Vocabularys extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get word => text().withLength(max: 100)();
  TextColumn get stem => text().withLength(max: 100).nullable()();
  TextColumn get contentHash => text().withLength(max: 64)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync outbox table - queue for pending sync operations (local only)
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable =>
      text()(); // 'sources', 'encounters', 'vocabulary'
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

// =============================================================================
// Learning Feature Tables (004-calm-srs-learning)
// =============================================================================

/// Learning cards table - FSRS state for each vocabulary item
/// One row per vocabulary item that enters the learning system.
class LearningCards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get vocabularyId => text()(); // References Vocabularys.id
  // FSRS state: 0=new, 1=learning, 2=review, 3=relearning
  IntColumn get state => integer().withDefault(const Constant(0))();
  DateTimeColumn get due => dateTime()(); // Next review date (UTC)
  RealColumn get stability =>
      real().withDefault(const Constant(0.0))(); // FSRS stability (days)
  RealColumn get difficulty =>
      real().withDefault(const Constant(0.0))(); // FSRS difficulty [1-10]
  IntColumn get reps =>
      integer().withDefault(const Constant(0))(); // Total successful reviews
  IntColumn get lapses =>
      integer().withDefault(const Constant(0))(); // Failed reviews
  DateTimeColumn get lastReview => dateTime().nullable()(); // Last review (UTC)
  BoolColumn get isLeech =>
      boolean().withDefault(const Constant(false))(); // True when lapses >= 8
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Review logs table - append-only log of every review interaction
/// Used for telemetry, FSRS parameter optimization, and analytics.
class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get learningCardId => text()(); // References LearningCards.id
  // Rating: 1=again, 2=hard, 3=good, 4=easy
  IntColumn get rating => integer()();
  // Interaction mode: 0=recognition (MCQ), 1=recall (self-grade)
  IntColumn get interactionMode => integer()();
  IntColumn get stateBefore => integer()(); // Card state before review
  IntColumn get stateAfter => integer()(); // Card state after review
  RealColumn get stabilityBefore => real()();
  RealColumn get stabilityAfter => real()();
  RealColumn get difficultyBefore => real()();
  RealColumn get difficultyAfter => real()();
  IntColumn get responseTimeMs => integer()(); // Actual time user took
  RealColumn get retrievabilityAtReview =>
      real()(); // FSRS retrievability (0-1) at review time
  DateTimeColumn get reviewedAt => dateTime()(); // UTC
  TextColumn get sessionId =>
      text().nullable()(); // References LearningSessions.id
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Learning sessions table - tracks each time-boxed practice session
/// Supports resume via expiresAt.
class LearningSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()(); // UTC
  DateTimeColumn get expiresAt => dateTime()(); // Default: end of local day
  IntColumn get plannedMinutes => integer()(); // User's daily target
  IntColumn get elapsedSeconds =>
      integer().withDefault(const Constant(0))(); // Updated after each item
  IntColumn get bonusSeconds =>
      integer().withDefault(const Constant(0))(); // Accumulated bonus time
  IntColumn get itemsPresented => integer().withDefault(const Constant(0))();
  IntColumn get itemsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get newWordsPresented => integer().withDefault(const Constant(0))();
  IntColumn get reviewsPresented => integer().withDefault(const Constant(0))();
  RealColumn get accuracyRate => real().nullable()(); // Computed at session end
  IntColumn get avgResponseTimeMs =>
      integer().nullable()(); // Computed at session end
  // Outcome: 0=in_progress, 1=complete, 2=partial, 3=expired
  IntColumn get outcome => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// User learning preferences table - one row per user
/// Created with defaults on first session start.
class UserLearningPreferences extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().unique()();
  IntColumn get dailyTimeTargetMinutes =>
      integer().withDefault(const Constant(10))(); // 1-60
  RealColumn get targetRetention =>
      real().withDefault(const Constant(0.90))(); // 0.85-0.95
  // Intensity: 0=light, 1=normal, 2=intense
  IntColumn get intensity => integer().withDefault(const Constant(1))();
  // Hysteresis tracking for new-word suppression
  BoolColumn get newWordSuppressionActive =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Streaks table - tracks current and longest streak per user
class Streaks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().unique()();
  IntColumn get currentCount => integer().withDefault(const Constant(0))();
  IntColumn get longestCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastCompletedDate =>
      dateTime().nullable()(); // Calendar date of last completed session
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
