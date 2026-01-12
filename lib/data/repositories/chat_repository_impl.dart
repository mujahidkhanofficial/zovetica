import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../local/database.dart';
import '../../core/network/connectivity_service.dart';
import '../../services/supabase_service.dart';
import 'chat_repository.dart';

const _uuid = Uuid();

/// Implementation of ChatRepository with offline-first architecture
/// 
/// Golden Rules:
/// 1. READS: Always from local DB first (returns streams for reactive UI)
/// 2. WRITES: Write to local DB first (optimistic), then sync to Supabase in background
/// 3. SYNC: Delta sync using timestamps to minimize bandwidth
class ChatRepositoryImpl implements ChatRepository {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final ConnectivityService _connectivity;

  ChatRepositoryImpl({
    AppDatabase? db,
    SupabaseClient? supabase,
    ConnectivityService? connectivity,
  })  : _db = db ?? AppDatabase.instance,
        _supabase = supabase ?? SupabaseService.client,
        _connectivity = connectivity ?? ConnectivityService.instance;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // READ OPERATIONS (Local-First, Streams)
  // ============================================

  @override
  Stream<List<ChatData>> watchChats() {
    return _db.watchChats().map(
      (localChats) => localChats.map((c) => ChatData.fromLocal(c)).toList(),
    );
  }

  @override
  Stream<List<MessageData>> watchMessages(int chatId) {
    return _db.watchMessages(chatId).map(
      (localMessages) => localMessages.map((m) => MessageData.fromLocal(m)).toList(),
    );
  }

  @override
  Future<ChatData?> getChatById(int chatId) async {
    final result = await (_db.select(_db.localChats)
          ..where((c) => c.id.equals(chatId)))
        .getSingleOrNull();
    return result != null ? ChatData.fromLocal(result) : null;
  }

  // ============================================
  // WRITE OPERATIONS (Optimistic, Local-First)
  // ============================================

  @override
  Future<int> sendMessage({
    required int chatId,
    required String content,
    required String recipientId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Generate idempotency key for this message (prevents duplicates on retry)
    final clientMessageId = _uuid.v4();

    // 1. Insert to local DB immediately (optimistic UI)
    final localId = await _db.insertPendingMessage(
      chatId: chatId,
      senderId: userId,
      content: content,
      clientMessageId: clientMessageId,
    );
    
    debugPrint('💬 Message saved locally (id: $localId, clientId: $clientMessageId), syncing...');

    // 2. Update chat's last message locally
    await (_db.update(_db.localChats)..where((c) => c.id.equals(chatId))).write(
      LocalChatsCompanion(
        lastMessage: Value(content),
        lastMessageAt: Value(DateTime.now()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );

    // 3. Sync to Supabase in background (non-blocking)
    _syncMessageToRemote(localId, chatId, content, recipientId, clientMessageId);

    return localId;
  }

  /// Background sync of a single message to Supabase
  /// Uses idempotency key to prevent duplicate sends on retry
  Future<void> _syncMessageToRemote(
    int localId,
    int chatId,
    String content,
    String recipientId,
    String clientMessageId,
  ) async {
    if (!_connectivity.isOnline) {
      debugPrint('📵 Offline - message will sync when online');
      return;
    }

    try {
      // Mark as syncing
      await (_db.update(_db.localMessages)..where((m) => m.id.equals(localId)))
          .write(const LocalMessagesCompanion(syncStatus: Value('syncing')));

      // Insert to Supabase with idempotency key
      // The server has a unique constraint on (chat_id, client_message_id)
      // so retries will fail gracefully and we can fetch the existing record
      final response = await _supabase.from('messages').upsert(
        {
          'chat_id': chatId,
          'sender_id': _currentUserId,
          'content': content,
          'client_message_id': clientMessageId,
        },
        onConflict: 'chat_id,client_message_id',
      ).select().single();

      final remoteId = response['id'] as int;

      // Mark as synced with remote ID
      await _db.markMessageSynced(localId, remoteId);
      
      // Update chat's updated_at in Supabase
      await _supabase.from('chats').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      debugPrint('✅ Message synced (remote id: $remoteId)');
    } catch (e) {
      debugPrint('❌ Message sync failed: $e');
      // Mark as failed
      await (_db.update(_db.localMessages)..where((m) => m.id.equals(localId)))
          .write(const LocalMessagesCompanion(syncStatus: Value('failed')));
    }
  }

  @override
  Future<int> createOrGetChat(String targetUserId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Check if chat exists locally first
    final existing = await (_db.select(_db.localChats)
          ..where((c) => c.otherUserId.equals(targetUserId)))
        .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    // If online, create on server
    if (_connectivity.isOnline) {
      try {
        // Check if chat exists on server
        final participations = await _supabase
            .from('chat_participants')
            .select('chat_id')
            .eq('user_id', userId);

        for (final p in participations) {
          final chatId = p['chat_id'] as int;
          final otherParticipant = await _supabase
              .from('chat_participants')
              .select('user_id')
              .eq('chat_id', chatId)
              .neq('user_id', userId)
              .maybeSingle();

          if (otherParticipant != null && otherParticipant['user_id'] == targetUserId) {
            // Found existing chat - cache locally
            await _cacheChat(chatId, targetUserId);
            return chatId;
          }
        }

        // Create new chat
        final chatResponse = await _supabase.from('chats').insert({
          'type': 'direct',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select().single();

        final newChatId = chatResponse['id'] as int;

        // Add participants
        await _supabase.from('chat_participants').insert([
          {'chat_id': newChatId, 'user_id': userId},
          {'chat_id': newChatId, 'user_id': targetUserId},
        ]);

        // Cache locally
        await _cacheChat(newChatId, targetUserId);

        return newChatId;
      } catch (e) {
        debugPrint('Failed to create chat on server: $e');
        rethrow;
      }
    }

    throw Exception('Cannot create chat while offline');
  }

  Future<void> _cacheChat(int chatId, String otherUserId) async {
    // Get other user's info
    final otherUser = await _supabase
        .from('users')
        .select('name, profile_image')
        .eq('id', otherUserId)
        .maybeSingle();

    await _db.into(_db.localChats).insertOnConflictUpdate(
      LocalChatsCompanion(
        id: Value(chatId),
        otherUserId: Value(otherUserId),
        otherUserName: Value(otherUser?['name'] as String?),
        otherUserImage: Value(otherUser?['profile_image'] as String?),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(true),
      ),
    );
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    // Mark as deleted locally
    await (_db.update(_db.localMessages)..where((m) => m.id.equals(messageId)))
        .write(const LocalMessagesCompanion(
          isDeleted: Value(true),
          syncStatus: Value('pending'),
        ));

    // Sync deletion to server
    if (_connectivity.isOnline) {
      final message = await (_db.select(_db.localMessages)
            ..where((m) => m.id.equals(messageId)))
          .getSingleOrNull();

      if (message?.remoteId != null) {
        try {
          await _supabase.from('messages').delete().eq('id', message!.remoteId!);
          await (_db.delete(_db.localMessages)..where((m) => m.id.equals(messageId))).go();
        } catch (e) {
          debugPrint('Failed to delete message on server: $e');
        }
      }
    }
  }

  @override
  Future<void> deleteChat(int chatId) async {
    // Delete locally first
    await (_db.delete(_db.localMessages)..where((m) => m.chatId.equals(chatId))).go();
    await (_db.delete(_db.localChats)..where((c) => c.id.equals(chatId))).go();

    // Then delete on server
    if (_connectivity.isOnline) {
      try {
        await _supabase.from('messages').delete().eq('chat_id', chatId);
        await _supabase.from('chat_participants').delete().eq('chat_id', chatId);
        await _supabase.from('chats').delete().eq('id', chatId);
      } catch (e) {
        debugPrint('Failed to delete chat on server: $e');
      }
    }
  }

  // ============================================
  // SYNC OPERATIONS
  // ============================================

  @override
  Future<void> syncChats() async {
    if (!_connectivity.isOnline) return;

    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Get last sync time
      final lastSync = await _db.getLastSyncTime('chats');

      // Fetch my chat participations
      final participations = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', userId);

      final chatIds = participations.map((p) => p['chat_id'] as int).toList();
      
      if (chatIds.isEmpty) return;

      // Fetch chat details with delta filter
      List<dynamic> chats;
      if (lastSync != null) {
        chats = await _supabase
            .from('chats')
            .select('*')
            .inFilter('id', chatIds)
            .gt('updated_at', lastSync.toIso8601String())
            .order('updated_at', ascending: false);
      } else {
        chats = await _supabase
            .from('chats')
            .select('*')
            .inFilter('id', chatIds)
            .order('updated_at', ascending: false);
      }

      // For each chat, get other participant info and last message
      for (final chat in chats) {
        final chatId = chat['id'] as int;

        // Get other participant
        final otherParticipant = await _supabase
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chatId)
            .neq('user_id', userId)
            .maybeSingle();

        String? otherUserId;
        String? otherUserName;
        String? otherUserImage;

        if (otherParticipant != null) {
          otherUserId = otherParticipant['user_id'] as String;
          final userInfo = await _supabase
              .from('users')
              .select('name, profile_image')
              .eq('id', otherUserId)
              .maybeSingle();
          
          otherUserName = userInfo?['name'] as String?;
          otherUserImage = userInfo?['profile_image'] as String?;
        }

        // Get last message
        final lastMsg = await _supabase
            .from('messages')
            .select('content, created_at')
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        // Upsert to local DB
        await _db.into(_db.localChats).insertOnConflictUpdate(
          LocalChatsCompanion(
            id: Value(chatId),
            name: Value(chat['name'] as String?),
            type: Value(chat['type'] as String? ?? 'direct'),
            createdAt: Value(DateTime.parse(chat['created_at'] as String)),
            updatedAt: Value(DateTime.parse(chat['updated_at'] as String)),
            otherUserId: Value(otherUserId),
            otherUserName: Value(otherUserName),
            otherUserImage: Value(otherUserImage),
            lastMessage: Value(lastMsg?['content'] as String?),
            lastMessageAt: Value(lastMsg != null 
                ? DateTime.parse(lastMsg['created_at'] as String) 
                : null),
            isSynced: const Value(true),
          ),
        );
      }

      // Update sync timestamp
      await _db.updateSyncTime('chats', DateTime.now());
      debugPrint('✅ Synced ${chats.length} chats');
    } catch (e) {
      debugPrint('❌ Chat sync failed: $e');
    }
  }

  @override
  Future<void> syncMessages(int chatId, {bool force = false}) async {
    if (!_connectivity.isOnline) return;

    try {
      // Get last sync time for this chat
      final lastSync = await _db.getLastSyncTime('messages', entityId: chatId.toString());

      // Delta query - use gte (>=) instead of gt (>) to avoid missing boundary messages
      List<dynamic> messages;
      if (lastSync != null && !force) {
        // Subtract 1 second from lastSync to create overlap and ensure no messages are missed
        final querySince = lastSync.subtract(const Duration(seconds: 1));
        messages = await _supabase
            .from('messages')
            .select('*')
            .eq('chat_id', chatId)
            .gte('created_at', querySince.toIso8601String())
            .order('created_at', ascending: true);
        debugPrint('🔄 Delta sync for chat $chatId (since ${querySince.toIso8601String()})');
      } else {
        // Full sync - fetch ALL messages
        messages = await _supabase
            .from('messages')
            .select('*')
            .eq('chat_id', chatId)
            .order('created_at', ascending: true);
        debugPrint('🔄 Full sync for chat $chatId${force ? " (forced)" : " (first sync)"}');
      }

      // Upsert to local DB
      final companions = messages.map((msg) => LocalMessagesCompanion(
        remoteId: Value(msg['id'] as int),
        chatId: Value(chatId),
        senderId: Value(msg['sender_id'] as String),
        content: Value(msg['content'] as String),
        createdAt: Value(DateTime.parse(msg['created_at'] as String)),
        editedAt: Value(msg['edited_at'] != null 
            ? DateTime.parse(msg['edited_at'] as String) 
            : null),
        syncStatus: const Value('synced'),
        syncedAt: Value(DateTime.now()),
        isDeleted: const Value(false),
      )).toList();

      if (companions.isNotEmpty) {
        await _db.upsertMessages(companions);
      }

      // Update sync timestamp
      await _db.updateSyncTime('messages', DateTime.now(), entityId: chatId.toString());
      debugPrint('✅ Synced ${messages.length} messages for chat $chatId');
    } catch (e) {
      debugPrint('❌ Message sync failed for chat $chatId: $e');
    }
  }

  @override
  Future<void> pushPendingChanges() async {
    if (!_connectivity.isOnline) return;

    final pendingMessages = await _db.getPendingMessages();
    
    for (final msg in pendingMessages) {
      if (msg.syncStatus == 'pending' && !msg.isDeleted) {
        // Get chat to find recipient
        final chat = await getChatById(msg.chatId);
        if (chat?.otherUserId != null) {
          // Use existing clientMessageId or generate new one for legacy messages
          final clientMessageId = msg.clientMessageId ?? _uuid.v4();
          await _syncMessageToRemote(
            msg.id,
            msg.chatId,
            msg.content,
            chat!.otherUserId!,
            clientMessageId,
          );
        }
      }
    }
  }

  @override
  Future<void> performFullSync() async {
    debugPrint('🔄 Starting full sync...');
    await syncChats();
    
    // Sync messages for all cached chats
    final chats = await (_db.select(_db.localChats)).get();
    for (final chat in chats) {
      await syncMessages(chat.id);
    }
    
    await pushPendingChanges();
    debugPrint('✅ Full sync complete');
  }
}
