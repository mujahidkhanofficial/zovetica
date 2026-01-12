import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/local/database.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../core/sync/sync_engine.dart';
import '../services/supabase_service.dart';
import '../services/global_chat_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import '../widgets/offline_banner.dart';
import '../widgets/cached_avatar.dart';
import '../utils/app_notifications.dart';

class SimpleChatScreen extends StatefulWidget {
  final int chatId;
  final String friendId;
  final String friendName;
  final String? friendImage;

  const SimpleChatScreen({
    super.key,
    required this.chatId,
    required this.friendId,
    required this.friendName,
    this.friendImage,
  });

  @override
  State<SimpleChatScreen> createState() => _SimpleChatScreenState();
}

class _SimpleChatScreenState extends State<SimpleChatScreen> {
  final ChatRepository _chatRepo = ChatRepositoryImpl();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseService.currentUser?.id;
    
    // Trigger background sync for this chat
    SyncEngine.instance.syncChat(widget.chatId);
    
    // Mark this chat as active in GlobalChatManager (no badge increments)
    GlobalChatManager.instance.setActiveChat(widget.chatId);
    
    // Mark chat as read
    GlobalChatManager.instance.markChatAsRead(widget.chatId);
  }

  @override
  void dispose() {
    // Clear active chat when leaving
    GlobalChatManager.instance.setActiveChat(null);
    
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp-style background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryDiagonal,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              // Use CachedAvatar for offline image caching
              child: CachedAvatar(
                imageUrl: widget.friendImage,
                name: widget.friendName,
                radius: 18,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.friendName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: OfflineAwareBody(
        child: Column(
          children: [
            // Messages List - Now using local-first repository
            Expanded(
              child: StreamBuilder<List<MessageData>>(
                stream: _chatRepo.watchMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _currentUserId;
                      final prevMessage = index > 0 ? messages[index - 1] : null;
                      final showTimestamp = _shouldShowTimestamp(prevMessage, message);

                      return Column(
                        children: [
                          if (showTimestamp) _buildTimestamp(message.createdAt),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageData message, bool isMe) {
    final content = message.content;
    final timeStr = DateFormat('h:mm a').format(message.createdAt);
    
    // Show sync status indicator for pending messages
    final isPending = message.isPending;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                gradient: isMe ? AppGradients.primaryCta : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMe ? 12 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : AppColors.charcoal,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white.withOpacity(0.7) : AppColors.slate.withOpacity(0.6),
                        ),
                      ),
                      // Show clock icon for pending messages
                      if (isMe && isPending) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ] else if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String label;
    if (messageDate == today) {
      label = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.slate.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  bool _shouldShowTimestamp(MessageData? prevMessage, MessageData currentMessage) {
    if (prevMessage == null) return true;
    
    // Show timestamp if more than 1 hour apart
    return currentMessage.createdAt.difference(prevMessage.createdAt).inMinutes > 60;
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white, // Clean white background
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColors.primary,
                style: const TextStyle(
                  color: AppColors.charcoal,
                  fontSize: 15,
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Type your message',
                  filled: false,
                  hintStyle: TextStyle(
                    color: AppColors.slate.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryCta,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _sendMessage,
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          SizedBox(height: 16),
          Text(
            'Unable to load messages',
            style: TextStyle(fontSize: 16, color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryCta.scale(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Say hi! 👋',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Clear input immediately for better UX
    setState(() {
      _messageController.clear();
    });

    try {
      // Now uses repository for local-first optimistic write
      await _chatRepo.sendMessage(
        chatId: widget.chatId,
        content: content,
        recipientId: widget.friendId,
      );
      
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(context, 'Failed to send: $e');
      
      // Restore message on error
      setState(() {
        _messageController.text = content;
      });
    }
  }
}
