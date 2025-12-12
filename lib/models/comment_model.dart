import 'user_model.dart';

class Comment {
  final int id;
  final User author;
  final String content;
  final DateTime timestamp;
  final int likesCount;
  final bool isLiked;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      // We often need to join user table to get author details. 
      // Assuming Supabase query returns 'user:users(...)'
      author: map['user'] != null ? User.fromMap(map['user']) : User(
          id: map['user_id'] ?? '',
          name: 'User',
          role: UserRole.petOwner,
          email: '', phone: '', profileImage: ''
      ),
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['created_at']),
      likesCount: map['likes_count'] ?? 0,
      isLiked: map['is_liked'] ?? false, // Mapped from query
    );
  }

  Comment copyWith({
    String? content,
    int? likesCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id,
      author: author,
      content: content ?? this.content,
      timestamp: timestamp,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
