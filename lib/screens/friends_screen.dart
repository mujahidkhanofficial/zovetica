import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../widgets/widgets.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendService.getFriends();
      final requests = await _friendService.getFriendRequests();
      if (mounted) {
        setState(() {
          _friends = friends;
          _requests = requests;
        });
      }
    } catch (e) {
      debugPrint('Error fetching friends data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(String userId) async {
    final success = await _friendService.acceptFriendRequest(userId);
    if (success) {
      _fetchData(); // Refresh both lists
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request accepted!')));
    }
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    final chatId = await _chatService.createChat(user['id']);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: user['name'] ?? 'User',
            otherUserImage: user['profile_image'] ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        title: const Text('My Network', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.charcoal)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.charcoal),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Friends (${_friends.length})'),
            Tab(text: 'Requests (${_requests.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildRequestsList(),
              ],
            ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return _buildEmptyState('No friends yet', Icons.people_outline);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final user = _friends[index];
        return _buildUserCard(user, isRequest: false);
      },
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return _buildEmptyState('No pending requests', Icons.mail_outline);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final user = _requests[index];
        return _buildUserCard(user, isRequest: true);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {required bool isRequest}) {
    final String userId = user['id'] ?? ''; // Assuming ID is present
    final String name = user['name'] ?? 'Unknown User';
    final String imageUrl = user['profile_image'] ?? '';

    return GestureDetector(
      onTap: () {
          // Navigate to profile
           Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
          );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            CachedAvatar(
              imageUrl: imageUrl,
              name: name,
              radius: 24,
              backgroundColor: AppColors.primary.withAlpha(26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.charcoal),
              ),
            ),
            if (isRequest)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _acceptRequest(userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              )
            else
               IconButton(
                 icon: const Icon(Icons.message_rounded, color: AppColors.secondary),
                 onPressed: () => _openChat(user),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.slate.withAlpha(77)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.slate, fontSize: 16)),
        ],
      ),
    );
  }
}
