import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart';

/// Repository for managing sync outbox operations
class SyncOutboxRepository {
  final AppDatabase _db;

  SyncOutboxRepository(this._db);

  /// Add an item to the sync outbox
  Future<void> queueForSync({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final companion = SyncOutboxCompanion.insert(
      entityTable: tableName,
      recordId: recordId,
      operation: operation,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
    );

    await _db.into(_db.syncOutbox).insert(companion);
  }

  /// Get all pending sync items
  Future<List<SyncOutboxData>> getPendingItems() async {
    return (_db.select(_db.syncOutbox)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Get pending items with retry count under limit
  Future<List<SyncOutboxData>> getPendingItemsForSync({int maxRetries = 3}) async {
    return (_db.select(_db.syncOutbox)
          ..where((t) => t.retryCount.isSmallerThan(Variable(maxRetries)))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Mark item as successfully synced (delete from outbox)
  Future<void> markSynced(int id) async {
    await (_db.delete(_db.syncOutbox)..where((t) => t.id.equals(id))).go();
  }

  /// Get a single item by ID
  Future<SyncOutboxData?> getById(int id) async {
    return (_db.select(_db.syncOutbox)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Increment retry count and record error
  Future<void> recordFailure(int id, String error) async {
    final item = await getById(id);
    if (item == null) return;

    await (_db.update(_db.syncOutbox)..where((t) => t.id.equals(id))).write(
      SyncOutboxCompanion(
        retryCount: Value(item.retryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Delete all synced items
  Future<void> clearSynced(List<int> ids) async {
    await (_db.delete(_db.syncOutbox)..where((t) => t.id.isIn(ids))).go();
  }

  /// Get count of pending items
  Future<int> getPendingCount() async {
    final result = await (_db.selectOnly(_db.syncOutbox)
          ..addColumns([_db.syncOutbox.id.count()]))
        .getSingle();
    return result.read(_db.syncOutbox.id.count()) ?? 0;
  }
}
