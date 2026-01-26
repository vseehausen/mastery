import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../database/database.dart';
import '../repositories/sync_outbox_repository.dart';

/// Service for syncing local changes to Supabase
class SyncService {
  final SyncOutboxRepository _outboxRepo;
  final AppDatabase _db;

  bool _isSyncing = false;

  SyncService({
    required SyncOutboxRepository outboxRepo,
    required AppDatabase db,
  })  : _outboxRepo = outboxRepo,
        _db = db;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Push pending local changes to the server
  Future<SyncPushResult> pushChanges() async {
    if (_isSyncing) {
      return SyncPushResult(applied: 0, failed: 0, error: 'Sync already in progress');
    }

    if (!SupabaseConfig.isAuthenticated) {
      return SyncPushResult(applied: 0, failed: 0, error: 'Not authenticated');
    }

    _isSyncing = true;

    try {
      final pendingItems = await _outboxRepo.getPendingItemsForSync();

      if (pendingItems.isEmpty) {
        return SyncPushResult(applied: 0, failed: 0);
      }

      final changes = pendingItems.map((item) {
        return {
          'table': item.entityTable,
          'operation': item.operation,
          'id': item.recordId,
          'data': jsonDecode(item.payload),
        };
      }).toList();

      final response = await SupabaseConfig.client.functions.invoke(
        'sync/push',
        body: {'changes': changes},
        method: HttpMethod.post,
      );

      if (response.status != 200) {
        return SyncPushResult(
          applied: 0,
          failed: pendingItems.length,
          error: 'Server returned ${response.status}',
        );
      }

      final result = response.data as Map<String, dynamic>;
      final applied = result['applied'] as int? ?? 0;

      // Mark successfully synced items
      for (final item in pendingItems) {
        await _outboxRepo.markSynced(item.id);
      }

      // Update lastSyncedAt for synced records
      final syncedAt = DateTime.now();
      await _updateLastSyncedAt(pendingItems, syncedAt);

      return SyncPushResult(applied: applied, failed: 0);
    } catch (e) {
      return SyncPushResult(applied: 0, failed: 0, error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull remote changes from the server
  Future<SyncPullResult> pullChanges(DateTime? lastSyncedAt) async {
    if (_isSyncing) {
      return SyncPullResult(books: 0, highlights: 0, vocabulary: 0, error: 'Sync already in progress');
    }

    if (!SupabaseConfig.isAuthenticated) {
      return SyncPullResult(books: 0, highlights: 0, vocabulary: 0, error: 'Not authenticated');
    }

    _isSyncing = true;

    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'sync/pull',
        body: {
          'lastSyncedAt': (lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).toIso8601String(),
        },
        method: HttpMethod.post,
      );

      if (response.status != 200) {
        return SyncPullResult(
          books: 0,
          highlights: 0,
          vocabulary: 0,
          error: 'Server returned ${response.status}',
        );
      }

      final result = response.data as Map<String, dynamic>;
      final books = result['books'] as List<dynamic>? ?? [];
      final highlights = result['highlights'] as List<dynamic>? ?? [];
      final vocabulary = result['vocabulary'] as List<dynamic>? ?? [];

      // Save vocabulary to local database
      for (final v in vocabulary) {
        final entry = VocabularysCompanion(
          id: Value(v['id'] as String),
          userId: Value(v['user_id'] as String),
          word: Value(v['word'] as String),
          stem: Value(v['stem'] as String?),
          context: Value(v['context'] as String?),
          bookTitle: Value(v['book_title'] as String?),
          bookAuthor: Value(v['book_author'] as String?),
          bookAsin: Value(v['book_asin'] as String?),
          contentHash: Value(v['content_hash'] as String),
          lookupTimestamp: Value(v['lookup_timestamp'] != null 
              ? DateTime.parse(v['lookup_timestamp'] as String) 
              : null),
          createdAt: Value(DateTime.parse(v['created_at'] as String)),
          updatedAt: Value(DateTime.parse(v['updated_at'] as String)),
          lastSyncedAt: Value(DateTime.now()),
          isPendingSync: const Value(false),
        );
        await _db.into(_db.vocabularys).insertOnConflictUpdate(entry);
      }

      return SyncPullResult(
        books: books.length,
        highlights: highlights.length,
        vocabulary: vocabulary.length,
      );
    } catch (e) {
      return SyncPullResult(books: 0, highlights: 0, vocabulary: 0, error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Full sync (push then pull)
  Future<SyncResult> sync() async {
    final pushResult = await pushChanges();
    if (pushResult.error != null) {
      return SyncResult(push: pushResult, pull: null);
    }

    // TODO: Get last sync timestamp from preferences
    final pullResult = await pullChanges(null);

    return SyncResult(push: pushResult, pull: pullResult);
  }

  Future<void> _updateLastSyncedAt(List<SyncOutboxData> items, DateTime syncedAt) async {
    for (final item in items) {
      if (item.entityTable == 'books') {
        await (_db.update(_db.books)..where((b) => b.id.equals(item.recordId)))
            .write(BooksCompanion(
          lastSyncedAt: Value(syncedAt),
          isPendingSync: const Value(false),
        ));
      } else if (item.entityTable == 'highlights') {
        await (_db.update(_db.highlights)..where((h) => h.id.equals(item.recordId)))
            .write(HighlightsCompanion(
          lastSyncedAt: Value(syncedAt),
          isPendingSync: const Value(false),
        ));
      } else if (item.entityTable == 'vocabulary') {
        await (_db.update(_db.vocabularys)..where((v) => v.id.equals(item.recordId)))
            .write(VocabularysCompanion(
          lastSyncedAt: Value(syncedAt),
          isPendingSync: const Value(false),
        ));
      }
    }
  }
}

/// Result of a sync push operation
class SyncPushResult {
  final int applied;
  final int failed;
  final String? error;

  SyncPushResult({required this.applied, required this.failed, this.error});

  bool get hasError => error != null;
}

/// Result of a sync pull operation
class SyncPullResult {
  final int books;
  final int highlights;
  final int vocabulary;
  final String? error;

  SyncPullResult({required this.books, required this.highlights, required this.vocabulary, this.error});

  bool get hasError => error != null;
}

/// Combined result of a full sync
class SyncResult {
  final SyncPushResult push;
  final SyncPullResult? pull;

  SyncResult({required this.push, this.pull});

  bool get hasError => push.hasError || (pull?.hasError ?? false);
}
