import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FriendService {
  final _client = SupabaseService.client;
  final String _tableName = 'friendships';

  /// Get status of friendship between current user and [otherUserId]
  /// Returns: 'none', 'pending_sent', 'pending_received', 'accepted', 'blocked'
  Future<String> getFriendshipStatus(String otherUserId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return 'none';

    try {
      final response = await _client
          .from(_tableName)
          .select()
          .or('and(requester_id.eq.$myId,receiver_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,receiver_id.eq.$myId)')
          .maybeSingle();

      if (response == null) return 'none';

      final status = response['status'] as String;
      final requesterId = response['requester_id'] as String;

      if (status == 'pending') {
        return requesterId == myId ? 'pending_sent' : 'pending_received';
      }
      return status; // 'accepted' or 'blocked'
    } catch (e) {
      print('Error checking friendship status: $e');
      return 'none';
    }
  }

  /// Send a friend request
  Future<bool> sendFriendRequest(String receiverId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      await _client.from(_tableName).insert({
        'requester_id': myId,
        'receiver_id': receiverId,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  /// Accept a friend request
  Future<bool> acceptFriendRequest(String senderId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      // Find the specific request where I am the receiver
      await _client
          .from(_tableName)
          .update({'status': 'accepted'})
          .match({'requester_id': senderId, 'receiver_id': myId});
      return true;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  /// Remove friend or cancel request
  Future<bool> removeFriendship(String otherUserId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    try {
      await _client
          .from(_tableName)
          .delete()
          .or('and(requester_id.eq.$myId,receiver_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,receiver_id.eq.$myId)');
      return true;
    } catch (e) {
      print('Error removing friendship: $e');
      return false;
    }
  }
  /// Get pending friend requests
  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return [];

    try {
      // 1. Get received requests
      final response = await _client
          .from(_tableName)
          .select('requester_id')
          .match({'receiver_id': myId, 'status': 'pending'});

      if (response == null || (response as List).isEmpty) return [];

      final requesterIds = (response as List).map((r) => r['requester_id']).toList();

      // 2. Fetch profiles
      final profiles = await _client
          .from('users')
          .select()
          .inFilter('id', requesterIds);

      return List<Map<String, dynamic>>.from(profiles);
    } catch (e) {
      print('Error fetching friend requests: $e');
      return [];
    }
  }

  /// Get all friends
  Future<List<Map<String, dynamic>>> getFriends() async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return [];

    try {
      // 1. Get all accepted friendships
      final response = await _client
          .from(_tableName)
          .select()
          .or('and(requester_id.eq.$myId,status.eq.accepted),and(receiver_id.eq.$myId,status.eq.accepted)');

      if (response == null || (response as List).isEmpty) return [];

      // 2. Extract friend IDs
      final friendIds = (response as List).map((r) {
        return r['requester_id'] == myId ? r['receiver_id'] : r['requester_id'];
      }).toList();

      // 3. Fetch profiles
      final profiles = await _client
          .from('users')
          .select()
          .inFilter('id', friendIds);

      return List<Map<String, dynamic>>.from(profiles);
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }
}
