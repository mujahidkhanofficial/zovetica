import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/friend_service.dart';
import '../services/user_service.dart';

/// Simplified chat service that works directly with friendships
/// No complex RLS bypass - clean, simple, reliable
class SimpleChatService {
  final SupabaseClient _client;
  final FriendService _friendService;
  final UserService _userService;

  SimpleChatService({
    SupabaseClient? client,
    FriendService? friendService,
    UserService? userService,
  })  : _client = client ?? SupabaseService.client,
        _friendService = friendService ?? FriendService(),
        _userService = userService ?? UserService(client: client);

  /// Get all chats for current user with friend data pre-loaded
  Stream<List<Map<String, dynamic>>> getMyChatsStream() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('chat_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((participations) async {
          try {
            if (participations.isEmpty) return <Map<String, dynamic>>[];

            // Get all my friends first - this is our source of truth
            final friends = await _friendService.getFriends();
            final friendMap = {for (var f in friends) f['id']: f};

            final chatIds = participations
                .map((p) => p['chat_id'] as int)
                .toList();
            
            final List<Map<String, dynamic>> enrichedChats = [];

            for (final chatId in chatIds) {
              try {
                // Get chat info
                final chat = await _client
                    .from('chats')
                    .select()
                    .eq('id', chatId)
                    .maybeSingle();

                if (chat == null) continue;

                // Get the OTHER participant (not me)
                final otherParticipant = await _client
                    .from('chat_participants')
                    .select('user_id')
                    .eq('chat_id', chatId)
                    .neq('user_id', userId)
                    .maybeSingle();

                if (otherParticipant == null) continue;

                final otherId = otherParticipant['user_id'] as String;
                
                // Get friend data - they MUST be in our friend list
                final friendData = friendMap[otherId];
                if (friendData == null) {
                  debugPrint('Chat $chatId with non-friend $otherId - skipping');
                  continue;
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
                  'created_at': chat['created_at'],
                  'updated_at': chat['updated_at'],
                  'friend': {
                    'id': friendData['id'],
                    'name': friendData['name'],
                    'profile_image': friendData['profile_image'],
                  },
                  'last_message': lastMsg,
                });
              } catch (e) {
                debugPrint('Error loading chat $chatId: $e');
              }
            }

            // Sort by most recent activity
            enrichedChats.sort((a, b) {
              final t1Str = a['last_message']?['created_at'] ?? a['updated_at'];
              final t2Str = b['last_message']?['created_at'] ?? b['updated_at'];
              
              final t1 = DateTime.tryParse(t1Str ?? '') ?? DateTime(2000);
              final t2 = DateTime.tryParse(t2Str ?? '') ?? DateTime(2000);
              return t2.compareTo(t1);
            });

            return enrichedChats;
          } catch (e) {
            debugPrint('Error in getMyChatsStream: $e');
            return <Map<String, dynamic>>[];
          }
        });
  }

  /// Create or get existing chat with a friend
  Future<int> createOrGetChatWithFriend(String friendId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    try {
      // First, verify they are actually our friend
      final friendship = await _client
          .from('friendships')
          .select()
          .or('and(requester_id.eq.$myId,receiver_id.eq.$friendId),and(requester_id.eq.$friendId,receiver_id.eq.$myId)')
          .eq('status', 'accepted')
          .maybeSingle();

      if (friendship == null) {
        throw Exception('Can only chat with accepted friends');
      }

      // Check if chat already exists
      // Get my chat IDs
      final myChats = await _client
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', myId);

      final myChatIds = (myChats as List)
          .map((c) => c['chat_id'] as int)
          .toList();

      if (myChatIds.isNotEmpty) {
        // Check if friend is in any of these chats
        final commonChat = await _client
            .from('chat_participants')
            .select('chat_id')
            .eq('user_id', friendId)
            .inFilter('chat_id', myChatIds)
            .maybeSingle();

        if (commonChat != null) {
          return commonChat['chat_id'] as int;
        }
      }

      // Create new chat
      final newChat = await _client
          .from('chats')
          .insert({'type': 'private'})
          .select()
          .single();

      final chatId = newChat['id'] as int;

      // Add both participants
      await _client.from('chat_participants').insert([
        {'chat_id': chatId, 'user_id': myId},
        {'chat_id': chatId, 'user_id': friendId},
      ]);

      return chatId;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      rethrow;
    }
  }

  /// Get messages stream for a chat
  Stream<List<Map<String, dynamic>>> getMessagesStream(int chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((messages) {
          return messages.map((msg) {
            return {
              'id': msg['id'],
              'chat_id': msg['chat_id'],
              'sender_id': msg['sender_id'],
              'content': msg['content'],
              'created_at': msg['created_at'],
              'edited_at': msg['edited_at'],
            };
          }).toList();
        });
  }

  /// Send a message
  Future<void> sendMessage(int chatId, String content, String recipientId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) throw Exception('Not logged in');

    if (content.trim().isEmpty) return;

    try {
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': myId,
        'content': content.trim(),
      });

      // Update chat's updated_at
      await _client
          .from('chats')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', chatId);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Delete a message (only sender can delete)
  Future<bool> deleteMessage(int messageId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      await _client
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', myId);
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }
}
