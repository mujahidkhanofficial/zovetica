import 'dart:async';
import 'package:flutter/foundation.dart';
import '../network/connectivity_service.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/pet_repository.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/doctor_repository.dart';
import '../../data/repositories/notification_repository.dart';

/// Central sync engine that orchestrates data synchronization
/// 
/// Responsibilities:
/// - Listen to connectivity changes and trigger sync
/// - Periodic foreground sync
/// - Coordinate repository sync operations
class SyncEngine {
  static SyncEngine? _instance;
  static SyncEngine get instance => _instance ??= SyncEngine._();
  
  SyncEngine._();

  final ConnectivityService _connectivity = ConnectivityService.instance;
  final ChatRepositoryImpl _chatRepo = ChatRepositoryImpl();
  final UserRepository _userRepo = UserRepository.instance;
  final PetRepository _petRepo = PetRepository.instance;
  final AppointmentRepository _appointmentRepo = AppointmentRepository.instance;
  final PostRepository _postRepo = PostRepository.instance;
  final DoctorRepository _doctorRepo = DoctorRepository.instance;
  final NotificationRepository _notificationRepo = NotificationRepository.instance;
  
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  
  // Sync status stream for reactive UI updates
  final _syncStatusController = StreamController<bool>.broadcast();
  
  bool _isInitialized = false;
  bool _isSyncing = false;
  
  /// Stream of sync status changes
  Stream<bool> get syncStatusStream => _syncStatusController.stream;
  
  /// Set syncing state and notify listeners
  void _setSyncing(bool value) {
    if (_isSyncing != value) {
      _isSyncing = value;
      _syncStatusController.add(value);
    }
  }

  /// Initialize the sync engine
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onStatusChange.listen((status) {
      if (status == NetworkStatus.online) {
        debugPrint('🌐 Back online - triggering sync');
        _onConnectivityRestored();
      }
    });

    // Start periodic sync (every 5 minutes in foreground)
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performPeriodicSync(),
    );

    _isInitialized = true;
    debugPrint('🔄 SyncEngine initialized');

    // Initial sync if online
    if (_connectivity.isOnline) {
      await performInitialSync();
    }
  }

  /// Perform initial sync on app start
  Future<void> performInitialSync() async {
    if (_isSyncing) return;
    
    try {
      _setSyncing(true);
      debugPrint('🚀 Starting initial sync...');
      
      // Sync all data in parallel
      await Future.wait([
        _chatRepo.performFullSync(),
        _userRepo.getCurrentUser(forceRefresh: true),
        _petRepo.syncPets(),
        _appointmentRepo.syncAppointments(),
        _postRepo.syncPosts(),
        _doctorRepo.syncDoctors(),
        _notificationRepo.syncNotifications(),
      ]);
      
      debugPrint('✅ Initial sync complete');
    } catch (e) {
      debugPrint('❌ Initial sync failed: $e');
    } finally {
      _setSyncing(false);
    }
  }

  /// Handle connectivity restoration
  Future<void> _onConnectivityRestored() async {
    if (_isSyncing) return;
    
    try {
      _setSyncing(true);
      
      // First, push any pending local changes
      await Future.wait([
        _chatRepo.pushPendingChanges(),
        _petRepo.syncPendingPets(),
        _appointmentRepo.syncPendingAppointments(),
      ]);
      
      // Then pull latest from server
      await Future.wait([
        _chatRepo.performFullSync(),
        _userRepo.getCurrentUser(forceRefresh: true),
        _petRepo.syncPets(),
        _appointmentRepo.syncAppointments(),
        _postRepo.syncPosts(),
        _doctorRepo.syncDoctors(),
        _notificationRepo.syncNotifications(),
      ]);
    } catch (e) {
      debugPrint('❌ Connectivity restore sync failed: $e');
    } finally {
      _setSyncing(false);
    }
  }

  /// Periodic background sync
  Future<void> _performPeriodicSync() async {
    if (!_connectivity.isOnline || _isSyncing) return;
    
    try {
      _setSyncing(true);
      debugPrint('⏰ Periodic sync...');
      
      await Future.wait([
        _chatRepo.syncChats(),
        _chatRepo.pushPendingChanges(),
        _petRepo.syncPets(),
        _appointmentRepo.syncAppointments(),
        _postRepo.syncPosts(),
        _doctorRepo.syncDoctors(),
        _notificationRepo.syncNotifications(),
      ]);
      
      debugPrint('✅ Periodic sync complete');
    } catch (e) {
      debugPrint('❌ Periodic sync failed: $e');
    } finally {
      _setSyncing(false);
    }
  }

  /// Manually trigger sync for a specific chat
  /// If force=true, fetches all messages ignoring lastSync timestamp
  Future<void> syncChat(int chatId, {bool force = false}) async {
    if (!_connectivity.isOnline) return;
    await _chatRepo.syncMessages(chatId, force: force);
  }

  /// Force a full sync (call from pull-to-refresh, etc.)
  Future<void> forceFullSync() async {
    if (_isSyncing) return;
    
    try {
      _setSyncing(true);
      await _chatRepo.performFullSync();
    } finally {
      _setSyncing(false);
    }
  }

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _syncStatusController.close();
    _isInitialized = false;
    _instance = null;
  }
}
