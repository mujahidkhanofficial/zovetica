import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' show Value, Variable;
import '../models/chat_message.dart';
import '../models/chat_summary.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../core/sync/sync_engine.dart';
import '../data/local/database.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Global Chat Manager - Manages persistent real-time chat connections
/// 
/// This singleton service maintains a persistent Supabase Realtime connection
/// that listens to ALL user's chats simultaneously, not just the currently open one.
/// 
/// Key Features:
/// - Persistent connection throughout app session
/// - Multi-chat subscription (receives messages from all chats)
/// - Global message cache
/// - Badge count management
/// - Background sync support
class GlobalChatManager {
  // Singleton instance
  static final GlobalChatManager instance = GlobalChatManager._();
  GlobalChatManager._();

  // Services
  final SupabaseClient _supabase = SupabaseService.client;
  final NotificationService _notificationService = NotificationService();

  // Connection state
  RealtimeChannel? _mainChannel;
  bool _isInitialized = false;
  bool _isReconnecting = false;
  String? _currentUserId;
  List<int> _subscribedChatIds = [];

  // Message cache (in-memory)
  final Map<int, List<ChatMessage>> _messageCache = {};
  final Map<int, ChatSummary> _chatSummaries = {};
  final Map<int, int> _unreadCounts = {};
  int? _activeChatId;

  // Stream controllers
  final StreamController<List<ChatSummary>> _chatListController =
      StreamController<List<ChatSummary>>.broadcast();
  final Map<int, StreamController<List<ChatMessage>>> _messageControllers = {};
  final StreamController<int> _badgeController =
      StreamController<int>.broadcast();
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  Stream<List<ChatSummary>> get chatListStream => _chatListController.stream;
  Stream<int> get totalUnreadCountStream => _badgeController.stream;
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  /// Initialize the global chat manager for a user
  /// Call this after successful login
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('🔵 GlobalChatManager already initialized for user $userId');
      return;
    }

    debugPrint('🚀 Initializing GlobalChatManager for user $userId');
    _currentUserId = userId;
    _connectionStatus = ConnectionStatus.connecting;
    _connectionStatusController.add(_connectionStatus);

    try {
      // 1. Fetch all chat IDs for this user
      final chatIds = await _fetchUserChatIds(userId);
      _subscribedChatIds = chatIds;

      debugPrint('📋 User has ${chatIds.length} chats: $chatIds');

      // 2. Initialize message cache for each chat
      for (final chatId in chatIds) {
        _messageCache[chatId] = [];
        _unreadCounts[chatId] = 0;
        
        // Create stream controller for this chat
        if (!_messageControllers.containsKey(chatId)) {
          _messageControllers[chatId] =
              StreamController<List<ChatMessage>>.broadcast();
        }
      }

      // 3. Set up multi-chat Realtime subscription
      await _setupRealtimeSubscription(userId, chatIds);

      // 4. Load initial chat summaries
      await _loadChatSummaries(chatIds);

      _isInitialized = true;
      _connectionStatus = ConnectionStatus.connected;
      _connectionStatusController.add(_connectionStatus);

      debugPrint('✅ GlobalChatManager initialized successfully');
    } catch (e, stack) {
      debugPrint('❌ Error initializing GlobalChatManager: $e');
      debugPrint('Stack: $stack');
      _connectionStatus = ConnectionStatus.disconnected;
      _connectionStatusController.add(_connectionStatus);
      rethrow;
    }
  }

  /// Fetch all chat IDs for a user
  Future<List<int>> _fetchUserChatIds(String userId) async {
    try {
      final response = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', userId);

      return (response as List)
          .map((p) => p['chat_id'] as int)
          .toList();
    } catch (e) {
      debugPrint('Error fetching user chat IDs: $e');
      return [];
    }
  }

  /// Set up Supabase Realtime subscription for multiple chats
  Future<void> _setupRealtimeSubscription(
      String userId, List<int> chatIds) async {
    if (chatIds.isEmpty) {
      debugPrint('⚠️ No chats to subscribe to');
      return;
    }

    // Remove old channel if exists
    if (_mainChannel != null) {
      await _mainChannel!.unsubscribe();
      _mainChannel = null;
    }

    // Create new channel for all chats
    final channelName = 'user:$userId:chats';
    debugPrint('📡 Setting up channel: $channelName for ${chatIds.length} chats');

    _mainChannel = _supabase.channel(channelName);

    // Subscribe to INSERT events for messages in ANY of user's chats
    _mainChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        debugPrint('📨 New message received via Realtime');
        _handleNewMessage(payload);
      },
    );

    // Subscribe to UPDATE events (for edited messages)
    _mainChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        debugPrint('✏️ Message updated via Realtime');
        _handleMessageUpdate(payload);
      },
    );

    // Subscribe to DELETE events
    _mainChannel!.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        debugPrint('🗑️ Message deleted via Realtime');
        _handleMessageDelete(payload);
      },
    );

    // Subscribe to channel
    await _mainChannel!.subscribe();

    debugPrint('✅ Subscribed to Realtime channel');
  }

  /// Load chat summaries for all chats
  Future<void> _loadChatSummaries(List<int> chatIds) async {
    // This will be implemented using existing ChatService logic
    // For now, initialize with empty summaries
    for (final chatId in chatIds) {
      _chatSummaries[chatId] = ChatSummary(
        id: chatId,
        type: 'private',
        updatedAt: DateTime.now(),
        participants: [],
      );
    }
    
    _chatListController.add(_chatSummaries.values.toList());
  }

  /// Handle new message from Realtime
  Future<void> _handleNewMessage(PostgresChangePayload payload) async {
    try {
      final messageData = payload.newRecord;
      final message = ChatMessage.fromMap(messageData);

      // Skip messages sent by current user (already in local DB)
      if (message.senderId == _currentUserId) {
        debugPrint('⏭️ Skipping own message ${message.id} (already in local DB)');
        return;
      }

      // Auto-subscribe to chat if not already subscribed
      if (!_subscribedChatIds.contains(message.chatId)) {
        debugPrint('⚠️ Received message for unsubscribed chat ${message.chatId}');
        debugPrint('🔄 Auto-subscribing to chat ${message.chatId}...');
        await subscribeToChat(message.chatId);
        debugPrint('✅ Auto-subscribed to chat ${message.chatId}');
      }

      debugPrint('📬 Processing new message for chat ${message.chatId}');
      debugPrint('📊 [STATE] Active chat: $_activeChatId, Subscribed chats: ${_subscribedChatIds.length}');

      // 1. Add to message cache
      _messageCache[message.chatId]?.add(message);

      // 2. Update chat summary
      _updateChatSummary(message);

      // 3. Update badge count (if not active chat)
      if (message.chatId != _activeChatId && message.senderId != _currentUserId) {
        _unreadCounts[message.chatId] = (_unreadCounts[message.chatId] ?? 0) + 1;
        _badgeController.add(_getTotalUnreadCount());
        debugPrint('🔔 Badge updated: ${_getTotalUnreadCount()} total unread');
      }

      // 4. Trigger UI updates
      _messageControllers[message.chatId]?.add(
        _messageCache[message.chatId] ?? [],
      );
      _chatListController.add(_chatSummaries.values.toList());

      // 5. Write directly to local DB (bypass unreliable delta sync)
      debugPrint('💾 [DB] Writing message ${message.id} to local DB...');
      await _writeMessageToLocalDB(message);
      debugPrint('✅ [DB] Message ${message.id} written successfully');

      // 6. Update chat metadata to trigger chat list refresh
      await _updateChatMetadataInDB(message);

      // 7. Show notification (if not active chat and not from self)
      if (message.chatId != _activeChatId && message.senderId != _currentUserId) {
        _showLocalNotification(message);
      }

      debugPrint('✅ [SUCCESS] Message ${message.id} processed successfully');
    } catch (e, stack) {
      debugPrint('❌ [ERROR] Failed to process message: $e');
      debugPrint('📍 [CONTEXT] Chat: ${payload.newRecord['chat_id']}, Sender: ${payload.newRecord['sender_id']}');
      debugPrint('📚 [STACK] $stack');
      
      // Attempt recovery
      try {
        final message = ChatMessage.fromMap(payload.newRecord);
        debugPrint('🔄 [RECOVERY] Attempting to recover...');
        await subscribeToChat(message.chatId);
        await _writeMessageToLocalDB(message);
        debugPrint('✅ [RECOVERY] Message recovered');
      } catch (recoveryError) {
        debugPrint('❌ [RECOVERY_FAILED] $recoveryError');
      }
    }
  }

  /// Handle message update from Realtime
  void _handleMessageUpdate(PostgresChangePayload payload) {
    try {
      final messageData = payload.newRecord;
      final updatedMessage = ChatMessage.fromMap(messageData);

      // Find and update the message in cache
      final messages = _messageCache[updatedMessage.chatId];
      if (messages != null) {
        final index = messages.indexWhere((m) => m.id == updatedMessage.id);
        if (index != -1) {
          messages[index] = updatedMessage;
          _messageControllers[updatedMessage.chatId]?.add(messages);
        }
      }
    } catch (e) {
      debugPrint('Error handling message update: $e');
    }
  }

  /// Handle message delete from Realtime
  void _handleMessageDelete(PostgresChangePayload payload) {
    try {
      final oldRecord = payload.oldRecord;
      final messageId = oldRecord['id'] as int;
      final chatId = oldRecord['chat_id'] as int;

      // Remove from cache
      final messages = _messageCache[chatId];
      if (messages != null) {
        messages.removeWhere((m) => m.id == messageId);
        _messageControllers[chatId]?.add(messages);
      }
    } catch (e) {
      debugPrint('Error handling message delete: $e');
    }
  }

  /// Update chat summary with new message
  void _updateChatSummary(ChatMessage message) {
    final summary = _chatSummaries[message.chatId];
    if (summary != null) {
      _chatSummaries[message.chatId] = summary.copyWith(
        lastMessage: message,
        updatedAt: message.createdAt,
        unreadCount: _unreadCounts[message.chatId] ?? 0,
      );
    }
  }

  /// Write message directly to local database (bypass delta sync)
  Future<void> _writeMessageToLocalDB(ChatMessage message) async {
    try {
      final db = AppDatabase.instance;
      
      await db.into(db.localMessages).insertOnConflictUpdate(
        LocalMessagesCompanion(
          remoteId: Value(message.id),
          chatId: Value(message.chatId),
          senderId: Value(message.senderId),
          content: Value(message.content),
          createdAt: Value(message.createdAt),
          editedAt: Value(message.editedAt),
          syncStatus: const Value('synced'),
          syncedAt: Value(DateTime.now()),
          isDeleted: const Value(false),
        ),
      );
      
      debugPrint('✅ Message ${message.id} written to local DB');
    } catch (e, stack) {
      debugPrint('❌ Failed to write message to local DB: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Update chat metadata in local DB to trigger chat list refresh
  Future<void> _updateChatMetadataInDB(ChatMessage message) async {
    try {
      final db = AppDatabase.instance;
      
      // Update the chat's updated_at timestamp to trigger watchChats() stream
      await db.customUpdate(
        'UPDATE local_chats SET updated_at = ? WHERE id = ?',
        updates: {db.localChats},
        variables: [
          Variable(message.createdAt),
          Variable(message.chatId),
        ],
      );
      
      debugPrint('✅ Chat ${message.chatId} metadata updated');
    } catch (e) {
      debugPrint('⚠️ Failed to update chat metadata: $e');
      // Non-critical error, continue
    }
  }

  /// Show local notification for new message
  void _showLocalNotification(ChatMessage message) {
    // Will integrate with NotificationService
    debugPrint('🔔 Would show notification for message from ${message.senderId}');
  }

  /// Get stream of messages for a specific chat
  Stream<List<ChatMessage>> getMessagesForChat(int chatId) {
    // Ensure stream controller exists
    if (!_messageControllers.containsKey(chatId)) {
      _messageControllers[chatId] =
          StreamController<List<ChatMessage>>.broadcast();
    }

    // Load messages if not in cache
    if (!_messageCache.containsKey(chatId)) {
      _messageCache[chatId] = [];
      _loadMessagesForChat(chatId);
    }

    return _messageControllers[chatId]!.stream;
  }

  /// Load messages for a chat from database
  Future<void> _loadMessagesForChat(int chatId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .limit(100); // Last 100 messages

      final messages = (response as List)
          .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
          .toList();

      _messageCache[chatId] = messages;
      _messageControllers[chatId]?.add(messages);

      debugPrint('📥 Loaded ${messages.length} messages for chat $chatId');
    } catch (e) {
      debugPrint('Error loading messages for chat $chatId: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage(int chatId, String content) async {
    if (_currentUserId == null) return;

    try {
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': _currentUserId,
        'content': content,
      });

      debugPrint('📤 Message sent to chat $chatId');
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Set the currently active chat
  void setActiveChat(int? chatId) {
    _activeChatId = chatId;
    debugPrint('👁️ Active chat set to: $chatId');
  }

  /// Mark chat as read
  void markChatAsRead(int chatId) {
    _unreadCounts[chatId] = 0;
    _badgeController.add(_getTotalUnreadCount());
    
    // Update chat summary
    final summary = _chatSummaries[chatId];
    if (summary != null) {
      _chatSummaries[chatId] = summary.copyWith(unreadCount: 0);
      _chatListController.add(_chatSummaries.values.toList());
    }
    
    debugPrint('✅ Chat $chatId marked as read');
  }

  /// Get total unread count
  int _getTotalUnreadCount() {
    return _unreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Get unread count for specific chat
  int getUnreadCount(int chatId) {
    return _unreadCounts[chatId] ?? 0;
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    debugPrint('🔴 Disposing GlobalChatManager');

    await _mainChannel?.unsubscribe();
    _mainChannel = null;

    _messageCache.clear();
    _chatSummaries.clear();
    _unreadCounts.clear();
    _subscribedChatIds.clear();

    for (final controller in _messageControllers.values) {
      await controller.close();
    }
    _messageControllers.clear();

    await _chatListController.close();
    await _badgeController.close();
    await _connectionStatusController.close();

    _isInitialized = false;
    _currentUserId = null;
    _activeChatId = null;

    debugPrint('✅ GlobalChatManager disposed');
  }

  /// Reconnect after connection loss
  Future<void> reconnect() async {
    if (_isReconnecting || _currentUserId == null) return;

    debugPrint('🔄 Attempting reconnection...');
    _isReconnecting = true;
    _connectionStatus = ConnectionStatus.reconnecting;
    _connectionStatusController.add(_connectionStatus);

    try {
      await dispose();
      await initialize(_currentUserId!);
      _isReconnecting = false;
    } catch (e) {
      debugPrint('❌ Reconnection failed: $e');
      _isReconnecting = false;
      _connectionStatus = ConnectionStatus.disconnected;
      _connectionStatusController.add(_connectionStatus);
    }
  }

  /// Subscribe to a new chat
  Future<void> subscribeToChat(int chatId) async {
    if (_subscribedChatIds.contains(chatId)) {
      debugPrint('ℹ️ Already subscribed to chat $chatId');
      return;
    }

    debugPrint('📌 Subscribing to new chat $chatId');
    
    _subscribedChatIds.add(chatId);
    
    // Initialize cache and state for this chat
    _messageCache[chatId] = [];
    _unreadCounts[chatId] = 0;

    // Create stream controller if doesn't exist
    if (!_messageControllers.containsKey(chatId)) {
      _messageControllers[chatId] =
          StreamController<List<ChatMessage>>.broadcast();
    }
    
    // Initialize chat summary if doesn't exist
    if (!_chatSummaries.containsKey(chatId)) {
      _chatSummaries[chatId] = ChatSummary(
        id: chatId,
        type: 'private',
        updatedAt: DateTime.now(),
        participants: [],
      );
    }

    // Realtime subscription is chat-agnostic - it listens to ALL messages
    // for this user, so no need to recreate the channel
    
    debugPrint('✅ Successfully subscribed to chat $chatId');
    debugPrint('📊 Total subscriptions: ${_subscribedChatIds.length}');
  }
}
