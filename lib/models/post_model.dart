import 'user_model.dart';

class Post {
  final int id;
  final User author;
  final String content;
  final String? imageUrl;
  final String? localImagePath; // For locally picked images
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<String> tags;

  Post({
    required this.id,
    required this.author,
    required this.content,
    this.imageUrl,
    this.localImagePath,
    required this.timestamp,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.tags,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      author: User(
        id: map['user_id']?.toString() ?? '', 
        name: map['author_name'] ?? 'Unknown User',
        email: '',
        phone: '',
        role: UserRole.petOwner,
        profileImage: map['author_image'] ?? '',
      ),
      content: map['content'] ?? '',
      imageUrl: map['image_url'],
      timestamp: DateTime.parse(map['created_at']),
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      isLiked: map['is_liked'] ?? false, // Support mapped is_liked if query provides it
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Post copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return Post(
      id: id,
      author: author,
      content: content,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      timestamp: timestamp,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      tags: tags,
    );
  }
}
