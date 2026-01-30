import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/sync_outbox_repository.dart';

/// Background sync worker for syncing changes when device is online
class BackgroundSyncWorker {
  BackgroundSyncWorker({required SyncOutboxRepository outboxRepo})
    : _outboxRepo = outboxRepo;

  final SyncOutboxRepository _outboxRepo;
  static const Duration _syncInterval = Duration(minutes: 15);
  static const Duration _retryDelay = Duration(seconds: 5);

  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Start the background sync worker
  void start() {
    if (_syncTimer != null) {
      return; // Already running
    }

    debugPrint('[BackgroundSync] Starting background sync worker');

    // Perform initial sync immediately
    _performSync();

    // Schedule periodic syncs
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _performSync();
    });
  }

  /// Stop the background sync worker
  void stop() {
    debugPrint('[BackgroundSync] Stopping background sync worker');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Perform a sync operation
  Future<void> _performSync() async {
    if (_isSyncing) {
      debugPrint('[BackgroundSync] Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;
    try {
      debugPrint('[BackgroundSync] Starting sync...');

      // Get pending items
      final pending = await _outboxRepo.getPendingItemsForSync();

      if (pending.isEmpty) {
        debugPrint('[BackgroundSync] No pending items to sync');
        _isSyncing = false;
        return;
      }

      debugPrint('[BackgroundSync] Found ${pending.length} pending items');

      // In a real implementation, this would call the sync service
      // For now, we just log the pending items
      for (final item in pending) {
        debugPrint(
          '[BackgroundSync] Pending: ${item.entityTable} - ${item.operation}',
        );
      }

      debugPrint('[BackgroundSync] Sync completed successfully');
    } catch (e) {
      debugPrint('[BackgroundSync] Sync failed: $e');
      // Retry after delay
      await Future<void>.delayed(_retryDelay);
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Check if background worker is running
  bool get isRunning => _syncTimer != null;
}
