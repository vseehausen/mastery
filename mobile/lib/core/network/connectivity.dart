import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity status
enum ConnectivityStatus {
  /// Connected to a network
  connected,

  /// Not connected to any network
  disconnected,

  /// Connectivity status is unknown
  unknown,
}

/// Provider for network connectivity status
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
      (ref) => ConnectivityNotifier(),
    );

/// Notifier for network connectivity changes
class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.unknown) {
    _startMonitoring();
  }

  Timer? _checkTimer;

  void _startMonitoring() {
    // Check connectivity immediately
    _checkConnectivity();

    // Periodically check connectivity (every 10 seconds)
    _checkTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      // Lightweight reachability probe via DNS lookup.
      final result = await InternetAddress.lookup('one.one.one.one');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        state = ConnectivityStatus.connected;
        return;
      }
      state = ConnectivityStatus.disconnected;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Connectivity] check failed: $e');
      }
      state = ConnectivityStatus.disconnected;
    }
  }

  /// Force a connectivity check
  Future<void> checkNow() async {
    await _checkConnectivity();
  }

  /// Update connectivity status manually (useful for testing)
  void setStatus(ConnectivityStatus status) {
    state = status;
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

/// Provider that indicates if the device is online
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityProvider);
  return status == ConnectivityStatus.connected;
});

/// Provider that indicates if sync should be attempted
final shouldSyncProvider = Provider<bool>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  // Add any additional conditions here (e.g., user preferences)
  return isOnline;
});
