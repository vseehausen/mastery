import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/database.dart';
import '../../data/models/highlight_type.dart';
import '../../data/models/import_result.dart';
import '../../data/models/import_source.dart';
import '../../data/models/parsed_highlight.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/highlight_repository.dart';
import 'parser.dart';

/// Service for importing Kindle clippings
class ImportService {
  final AppDatabase _db;
  final BookRepository _bookRepo;
  final HighlightRepository _highlightRepo;
  final KindleClippingsParser _parser;
  final _uuid = const Uuid();

  ImportService({
    required AppDatabase db,
    required BookRepository bookRepo,
    required HighlightRepository highlightRepo,
    KindleClippingsParser? parser,
  })  : _db = db,
        _bookRepo = bookRepo,
        _highlightRepo = highlightRepo,
        _parser = parser ?? KindleClippingsParser();

  /// Import highlights from a file content
  Future<ImportResult> importFromContent({
    required String userId,
    required String content,
    required ImportSource source,
    String? filename,
    String? deviceName,
  }) async {
    final startTime = DateTime.now();
    final errorDetails = <String>[];

    // Parse the clippings
    final parsed = _parser.parse(content);
    final totalFound = parsed.length;

    var imported = 0;
    var skipped = 0;
    var errors = 0;

    // Process each highlight
    for (final highlight in parsed) {
      try {
        final wasImported = await _importHighlight(userId, highlight);
        if (wasImported) {
          imported++;
        } else {
          skipped++;
        }
      } catch (e) {
        errors++;
        errorDetails.add('Failed to import: ${highlight.bookTitle} - ${e.toString()}');
      }
    }

    final duration = DateTime.now().difference(startTime);

    // Record import session
    await _recordImportSession(
      userId: userId,
      source: source,
      filename: filename,
      deviceName: deviceName,
      totalFound: totalFound,
      imported: imported,
      skipped: skipped,
      errors: errors,
      errorDetails: errorDetails.isEmpty ? null : errorDetails,
      startedAt: startTime,
    );

    return ImportResult(
      totalFound: totalFound,
      imported: imported,
      skipped: skipped,
      errors: errors,
      errorDetails: errorDetails,
      duration: duration,
    );
  }

  /// Import a single parsed highlight
  /// Returns true if imported, false if skipped (duplicate)
  Future<bool> _importHighlight(String userId, ParsedHighlight parsed) async {
    // Generate content hash for duplicate detection
    final contentHash = KindleClippingsParser.generateContentHash(
      parsed.bookTitle,
      parsed.content,
    );

    // Check if already exists
    final exists = await _highlightRepo.existsByContentHash(
      userId: userId,
      contentHash: contentHash,
    );

    if (exists) {
      return false; // Duplicate, skip
    }

    // Find or create the book
    final book = await _bookRepo.findOrCreate(
      userId: userId,
      title: parsed.bookTitle,
      author: parsed.author,
    );

    // Create the highlight
    await _highlightRepo.create(
      userId: userId,
      bookId: book.id,
      content: parsed.content,
      type: parsed.type.name,
      contentHash: contentHash,
      location: parsed.location,
      page: parsed.page,
      kindleDate: parsed.kindleDate,
      note: parsed.type == HighlightType.note ? parsed.content : null,
    );

    // Update book highlight count
    await _bookRepo.incrementHighlightCount(book.id);

    return true;
  }

  /// Record an import session for analytics
  Future<void> _recordImportSession({
    required String userId,
    required ImportSource source,
    String? filename,
    String? deviceName,
    required int totalFound,
    required int imported,
    required int skipped,
    required int errors,
    List<String>? errorDetails,
    required DateTime startedAt,
  }) async {
    final companion = ImportSessionsCompanion.insert(
      id: _uuid.v4(),
      userId: userId,
      source: source.name,
      filename: Value(filename),
      deviceName: Value(deviceName),
      totalFound: totalFound,
      imported: imported,
      skipped: skipped,
      errors: Value(errors),
      errorDetails: Value(errorDetails != null ? jsonEncode(errorDetails) : null),
      startedAt: startedAt,
      completedAt: Value(DateTime.now()),
    );

    await _db.into(_db.importSessions).insert(companion);
  }

  /// Get recent import sessions for a user
  Future<List<ImportSession>> getRecentImportSessions(String userId, {int limit = 10}) async {
    return (_db.select(_db.importSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
          ..limit(limit))
        .get();
  }
}
