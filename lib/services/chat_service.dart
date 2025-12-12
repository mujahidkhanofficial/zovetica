import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/friend_service.dart';
import '../services/user_service.dart';

class ChatService {
  final SupabaseClient _client;
  final NotificationService _notificationService;
  final UserService _userService;
  final FriendService _friendService;

  ChatService({
    SupabaseClient? client, 
    NotificationService? notificationService,
    UserService? userService,
    FriendService? friendService,
  })  : _client = client ?? SupabaseService.client,
        _notificationService = notificationService ?? NotificationService(client: client),
        _userService = userService ?? UserService(client: client),
        _friendService = friendService ?? FriendService();

  // --- Chats ---

  /// Fetch all chats for the current user (simplified version)
  Stream<List<Map<String, dynamic>>> getChatsStream() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Stream.empty();

    // Stream my participations to get my chat IDs
    return _client
        .from('chat_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((participations) async {
          try {
            if (participations.isEmpty) return <Map<String, dynamic>>[];
            
            final chatIds = participations.map((p) => p['chat_id'] as int).toList();
            final List<Map<String, dynamic>> enrichedChats = [];

            // Bypass Strategy: Fetch friends to cross-reference
            final myFriends = await _friendService.getFriends();
            final friendMap = {for (var f in myFriends) f['id']: f};
            
            for (final chatId in chatIds) {
              try {
                // Get chat info
                final chat = await _client
                    .from('chats')
                    .select()
                    .eq('id', chatId)
                    .maybeSingle();
                
                if (chat == null) continue;
                
                // Get all participants for this chat
                final participants = await _client
                    .from('chat_participants')
                    .select('user_id')
                    .eq('chat_id', chatId);
                
                debugPrint('Chat $chatId participants raw: $participants');

                // Get participant user data
                final participantUsers = <Map<String, dynamic>>[];
                bool foundOther = false;

                for (final p in participants) {
                  // STRICTLY skip current user
                  if (p['user_id'] == userId) {
                     continue;
                  }

                  foundOther = true;
                  final userData = await _userService.getUserById(p['user_id']);
                  if (userData != null) {
                    participantUsers.add({
                      'id': userData['id'],
                      'name': userData['name'],
                      'profile_image': userData['profile_image'],
                    });
                  }
                }

                // RECOVERY STRATEGY 1: Check Message History
                if (!foundOther) {
                  try {
                    final otherMsg = await _client
                        .from('messages')
                        .select('sender_id')
                        .eq('chat_id', chatId)
                        .neq('sender_id', userId)
                        .limit(1)
                        .maybeSingle();
                    
                    if (otherMsg != null) {
                      final otherId = otherMsg['sender_id'] as String;
                       // Check if this ID is in our friend list first (faster)
                      if (friendMap.containsKey(otherId)) {
                        final f = friendMap[otherId]!;
                         participantUsers.add({
                          'id': f['id'],
                          'name': f['name'],
                          'profile_image': f['profile_image'],
                        });
                        foundOther = true;
                      } else {
                        // Fetch from user service
                         final userData = await _userService.getUserById(otherId);
                        if (userData != null) {
                          participantUsers.add({
                            'id': userData['id'],
                            'name': userData['name'],
                            'profile_image': userData['profile_image'],
                          });
                          foundOther = true;
                        }
                      }
                    }
                  } catch (e) { /* Ignore */ }
                }

                // RECOVERY STRATEGY 2: Cross-reference Friend List
                // "Is any of my friends in this chat?"
                if (!foundOther && myFriends.isNotEmpty) {
                   try {
                     // Check if any friend is a participant in this chat
                     // We can't query chat_participants directly for *them* usually, 
                     // but sometimes RLS allows checking "where user_id = X" if X is friend?
                     // Let's try to query chat_participants for this chat_id AND user_id IN friendIds
                     final friendIds = myFriends.map((f) => f['id']).toList();
                     
                     // We try to find ONE match
                     for (final fId in friendIds) {
                        final check = await _client
                            .from('chat_participants')
                            .select('user_id')
                            .eq('chat_id', chatId)
                            .eq('user_id', fId)
                            .maybeSingle();
                        
                        if (check != null) {
                           final f = friendMap[fId]!;
                           participantUsers.add({
                            'id': f['id'],
                            'name': f['name'],
                            'profile_image': f['profile_image'],
                          });
                          foundOther = true;
                          break; // Found the partner
                        }
                     }
                   } catch (e) { /* Ignore */ }
                }

                // Fallback
                if (participantUsers.isEmpty) {
                   participantUsers.add({
                    'id': 'unknown',
                    'name': 'Unknown User',
                    'profile_image': '',
                  });
                }
                
                // Get last message
                final lastMsg = await _client
                    .from('messages')
                    .select()
                    .eq('chat_id', chatId)
                    .order('created_at', ascending: false)
                    .limit(1)
                    .maybeSingle();
                
                enrichedChats.add({
                  'id': chat['id'],
                  'type': chat['type'],
                  'updated_at': chat['updated_at'],
                  'participants': participantUsers,
                  'last_message': lastMsg,
                });
              } catch (e) {
                debugPrint('Error processing chat $chatId: $e');
              }
            }
            
            // Sort by most recent message or update
            enrichedChats.sort((a, b) {
              final t1Str = a['last_message']?['created_at'] ?? a['updated_at'];
              final t2Str = b['last_message']?['created_at'] ?? b['updated_at'];
              
              final t1 = DateTime.tryParse(t1Str ?? '') ?? DateTime(2000);
              final t2 = DateTime.tryParse(t2Str ?? '') ?? DateTime(2000);
              return t2.compareTo(t1);
            });
            
            return enrichedChats;
          } catch (e) {
            debugPrint('Error in getChatsStream: $e');
            return <Map<String, dynamic>>[]; 
          }
        });
  }
  
  /// Create or Get existing Chat with a user
  Future<int> createChat(String targetUserId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    // 1. Check for existing private chat between these 2 users
    // Complex query: find chat where participants contains BOTH users AND count is 2.
    // Simplified MVP: Just create new or let user see existing list.
    // Better: Fetch my chats, check if targetUserId is a participant.
    
    // Fetch all my chat IDs
    final myChatsResponse = await _client
        .from('chat_participants')
        .select('chat_id')
        .eq('user_id', myId);
    
    final myChatIds = (myChatsResponse as List).map((c) => c['chat_id'] as int).toList();
    
    if (myChatIds.isNotEmpty) {
      // Check if target is in any of these chats (private only logic omitted for speed)
      final commonChat = await _client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', targetUserId)
          .filter('chat_id', 'in', myChatIds)
          .maybeSingle();
          
      if (commonChat != null) {
        return commonChat['chat_id'] as int;
      }
    }

    // 2. Create new Chat
    final chatResponse = await _client
        .from('chats')
        .insert({'type': 'private'})
        .select()
        .single();
    
    final chatId = chatResponse['id'] as int;

    // 3. Add Participants
    await _client.from('chat_participants').insert([
      {'chat_id': chatId, 'user_id': myId},
      {'chat_id': chatId, 'user_id': targetUserId},
    ]);

    return chatId;
  }

  // --- Messages ---

  /// Get Messages Stream for a specific chat
  Stream<List<Map<String, dynamic>>> getMessagesStream(int chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((maps) => maps); // Allow raw maps for flexibility in UI
  }

  /// Send Message with notification
  Future<void> sendMessage(int chatId, String content, {String? recipientId, String? recipientName}) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return;

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'content': content,
    });

    // Send notification to recipient if provided
    if (recipientId != null && recipientId != myId) {
      final myData = await _userService.getCurrentUser();
      final myName = myData?['name'] ?? 'Someone';
      
      // Truncate message for preview
      final preview = content.length > 50 ? '${content.substring(0, 47)}...' : content;
      
      await _notificationService.createNotification(
        userId: recipientId,
        type: 'message',
        title: myName,
        body: preview,
        relatedId: chatId.toString(),
      );
    }
  }

  /// Check if current user can message target user (must be accepted friends)
  Future<bool> canMessageUser(String targetUserId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      final response = await _client
          .from('friendships')
          .select()
          .or('and(requester_id.eq.$myId,receiver_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,receiver_id.eq.$myId)')
          .eq('status', 'accepted')
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete a chat and all its messages
  Future<bool> deleteChat(int chatId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      // First verify user is a participant
      final participation = await _client
          .from('chat_participants')
          .select()
          .eq('chat_id', chatId)
          .eq('user_id', myId)
          .maybeSingle();

      if (participation == null) return false;

      // Delete messages first (foreign key constraint)
      await _client.from('messages').delete().eq('chat_id', chatId);
      
      // Delete participants
      await _client.from('chat_participants').delete().eq('chat_id', chatId);
      
      // Delete chat
      await _client.from('chats').delete().eq('id', chatId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // =========== Message CRUD Operations ===========

  /// Edit a message (only by sender)
  Future<bool> editMessage(int messageId, String newContent) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      await _client
          .from('messages')
          .update({'content': newContent, 'edited_at': DateTime.now().toIso8601String()})
          .eq('id', messageId)
          .eq('sender_id', myId); // Only sender can edit
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a message (only by sender)
  Future<bool> deleteMessage(int messageId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      await _client
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', myId); // Only sender can delete
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get a single message by ID
  Future<Map<String, dynamic>?> getMessageById(int messageId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('id', messageId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
}
