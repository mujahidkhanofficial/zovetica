import 'package:flutter/foundation.dart';

/// Represents a chat message
@immutable
class ChatMessage {
  final int id;
  final int chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isSynced;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.editedAt,
    this.isSynced = true,
  });

  /// Create from Supabase map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int,
      chatId: map['chat_id'] as int,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      editedAt: map['edited_at'] != null 
          ? DateTime.parse(map['edited_at'] as String) 
          : null,
      isSynced: true,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Create copy with modifications
  ChatMessage copyWith({
    int? id,
    int? chatId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isSynced,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChatMessage(id: $id, chatId: $chatId, content: $content)';
}
