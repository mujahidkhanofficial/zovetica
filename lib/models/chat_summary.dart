import 'package:flutter/foundation.dart';
import 'chat_message.dart';

/// Represents a chat summary with metadata
@immutable
class ChatSummary {
  final int id;
  final String type; // 'private' or 'group'
  final DateTime updatedAt;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const ChatSummary({
    required this.id,
    required this.type,
    required this.updatedAt,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
  });

  /// Create from enriched chat data
  factory ChatSummary.fromMap(Map<String, dynamic> map) {
    final participantsList = (map['participants'] as List?)
            ?.map((p) => ChatParticipant.fromMap(p as Map<String, dynamic>))
            .toList() ??
        [];

    final lastMsgMap = map['last_message'] as Map<String, dynamic>?;

    return ChatSummary(
      id: map['id'] as int,
      type: map['type'] as String? ?? 'private',
      updatedAt: DateTime.parse(map['updated_at'] as String),
      participants: participantsList,
      lastMessage: lastMsgMap != null ? ChatMessage.fromMap(lastMsgMap) : null,
      unreadCount: map['unread_count'] as int? ?? 0,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
      'last_message_id': lastMessage?.id,
    };
  }

  /// Get other participant (for private chats)
  ChatParticipant? getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (e) {
      return null;
    }
  }

  /// Get chat display name
  String getDisplayName(String currentUserId) {
    if (type == 'group') {
      // For groups, could use group name (not implemented yet)
      return 'Group Chat';
    } else {
      final other = getOtherParticipant(currentUserId);
      return other?.name ?? 'Unknown';
    }
  }

  /// Get chat display image
  String? getDisplayImage(String currentUserId) {
    if (type == 'group') {
      return null;
    } else {
      final other = getOtherParticipant(currentUserId);
      return other?.profileImage;
    }
  }

  /// Create copy with modifications
  ChatSummary copyWith({
    int? id,
    String? type,
    DateTime? updatedAt,
    List<ChatParticipant>? participants,
    ChatMessage? lastMessage,
    int? unreadCount,
  }) {
    return ChatSummary(
      id: id ?? this.id,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSummary && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents a chat participant
@immutable
class ChatParticipant {
  final String id;
  final String name;
  final String? profileImage;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.profileImage,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: map['id'] as String,
      name: map['name'] as String,
      profileImage: map['profile_image'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profile_image': profileImage,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
