import '../local/database.dart';

/// Abstract interface for chat data operations
/// Screens depend on this interface, not the implementation
abstract class ChatRepository {
  // ============================================
  // READ OPERATIONS (Local-First, Streams)
  // ============================================
  
  /// Watch all chats for current user (reactive stream from local DB)
  Stream<List<ChatData>> watchChats();
  
  /// Watch messages for a specific chat (reactive stream from local DB)
  Stream<List<MessageData>> watchMessages(int chatId);
  
  /// Get a single chat by ID
  Future<ChatData?> getChatById(int chatId);

  // ============================================
  // WRITE OPERATIONS (Optimistic, Local-First)
  // ============================================
  
  /// Send a message (writes to local DB first, syncs in background)
  /// Returns the local message ID for tracking
  Future<int> sendMessage({
    required int chatId,
    required String content,
    required String recipientId,
  });
  
  /// Create or get existing chat with a user
  Future<int> createOrGetChat(String targetUserId);
  
  /// Delete a message locally (marks for sync)
  Future<void> deleteMessage(int messageId);
  
  /// Delete a chat and its messages
  Future<void> deleteChat(int chatId);

  // ============================================
  // SYNC OPERATIONS
  // ============================================
  
  /// Sync all chats from remote (delta sync)
  Future<void> syncChats();
  
  /// Sync messages for a specific chat (delta sync)
  Future<void> syncMessages(int chatId);
  
  /// Push pending local changes to remote
  Future<void> pushPendingChanges();
  
  /// Full sync (chats + recent messages)
  Future<void> performFullSync();
}

/// Chat data model for UI (simplified from LocalChat)
class ChatData {
  final int id;
  final String? name;
  final String? otherUserName;
  final String? otherUserImage;
  final String? otherUserId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final bool isSynced;

  ChatData({
    required this.id,
    this.name,
    this.otherUserName,
    this.otherUserImage,
    this.otherUserId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.isSynced = true,
  });

  /// Create from Drift LocalChat
  factory ChatData.fromLocal(LocalChat local) {
    return ChatData(
      id: local.id,
      name: local.name,
      otherUserName: local.otherUserName,
      otherUserImage: local.otherUserImage,
      otherUserId: local.otherUserId,
      lastMessage: local.lastMessage,
      lastMessageAt: local.lastMessageAt,
      createdAt: local.createdAt,
      isSynced: local.isSynced,
    );
  }
}

/// Message data model for UI
class MessageData {
  final int id;
  final int? remoteId;
  final int chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String syncStatus;  // 'pending', 'syncing', 'synced', 'failed'
  final bool isDeleted;

  MessageData({
    required this.id,
    this.remoteId,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.editedAt,
    this.syncStatus = 'synced',
    this.isDeleted = false,
  });

  /// Whether this message is still syncing
  bool get isPending => syncStatus == 'pending' || syncStatus == 'syncing';

  /// Create from Drift LocalMessage
  factory MessageData.fromLocal(LocalMessage local) {
    return MessageData(
      id: local.id,
      remoteId: local.remoteId,
      chatId: local.chatId,
      senderId: local.senderId,
      content: local.content,
      createdAt: local.createdAt,
      editedAt: local.editedAt,
      syncStatus: local.syncStatus,
      isDeleted: local.isDeleted,
    );
  }
}
