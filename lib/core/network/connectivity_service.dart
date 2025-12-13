import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity status enum
enum NetworkStatus { online, offline }

/// Service to monitor network connectivity status
/// 
/// Works with connectivity_plus v5.x which returns List<ConnectivityResult>
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<NetworkStatus>.broadcast();
  
  NetworkStatus _currentStatus = NetworkStatus.online;
  StreamSubscription? _subscription;

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether device is currently online
  bool get isOnline => _currentStatus == NetworkStatus.online;

  /// Stream of network status changes
  Stream<NetworkStatus> get onStatusChange => _statusController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Get initial status - connectivity_plus 5.x returns List<ConnectivityResult>
    final results = await _connectivity.checkConnectivity();
    _currentStatus = _checkResults(results);
    
    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final newStatus = _checkResults(results);
      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController.add(newStatus);
        debugPrint('📶 Network status changed: $newStatus');
      }
    });
  }

  /// Check current connectivity (one-time check)
  Future<NetworkStatus> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _currentStatus = _checkResults(results);
    return _currentStatus;
  }

  /// Check if results indicate we're online
  /// Handles List<ConnectivityResult> from connectivity_plus 5.x
  NetworkStatus _checkResults(dynamic results) {
    // Handle as List<ConnectivityResult>
    if (results is List) {
      if (results.isEmpty) return NetworkStatus.offline;
      // Check if all results are 'none'
      for (final result in results) {
        if (result != ConnectivityResult.none) {
          return NetworkStatus.online;
        }
      }
      return NetworkStatus.offline;
    }
    
    // Handle single ConnectivityResult (older API versions)
    if (results == ConnectivityResult.none) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
