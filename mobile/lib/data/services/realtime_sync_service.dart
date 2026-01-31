import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_service.dart';

/// Service that subscribes to Supabase Realtime for live data sync.
/// When changes are detected, triggers a pull sync to update local data.
class RealtimeSyncService {
  RealtimeSyncService(this._syncService, this._userId);

  final SyncService _syncService;
  final String _userId;
  RealtimeChannel? _channel;
  Timer? _debounceTimer;

  /// Start listening for realtime changes
  void start() {
    if (_channel != null) return;

    _channel = Supabase.instance.client
        .channel('db-changes-$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vocabulary',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => _onChangeDetected('vocabulary'),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'learning_cards',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => _onChangeDetected('learning_cards'),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sources',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => _onChangeDetected('sources'),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'encounters',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => _onChangeDetected('encounters'),
        )
        .subscribe();

    debugPrint('[RealtimeSync] Started listening for changes');
  }

  /// Stop listening
  void stop() {
    _debounceTimer?.cancel();
    _channel?.unsubscribe();
    _channel = null;
    debugPrint('[RealtimeSync] Stopped');
  }

  void _onChangeDetected(String table) {
    debugPrint('[RealtimeSync] Change detected in $table');
    
    // Debounce to avoid multiple syncs for batch changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      debugPrint('[RealtimeSync] Triggering sync...');
      _syncService.pullChanges(null);
    });
  }
}
