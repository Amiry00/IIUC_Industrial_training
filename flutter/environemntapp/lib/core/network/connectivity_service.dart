import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor internet connectivity status.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  ConnectivityService() {
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Stream of connectivity status.
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Check current connectivity status.
  Future<bool> get isConnected async {
    try {
      // Add a timeout to prevent infinite hanging on Linux if dbus/NetworkManager is unresponsive
      final result = await _connectivity.checkConnectivity().timeout(const Duration(seconds: 2));
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      // Fallback to true so the actual network request can be attempted (and timeout naturally if offline)
      return true;
    }
  }

  /// Update connection status based on connectivity result.
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final connected = !result.contains(ConnectivityResult.none);
    debugPrint('[ConnectivityService] Connection status: $connected');
    _connectionStatusController.add(connected);
  }

  /// Dispose the stream controller.
  void dispose() {
    _connectionStatusController.close();
  }
}
