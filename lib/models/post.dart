/// A model representing a post in the app.
class Post {
  final String postId;
  final String userId;
  final String content;
  final List<String> likes;
  final int likesCount;
  final String? groupId;
  final String? eventId;
  final String? imageUrl; // New field
  final String? createdAt; // New field

  /// Creates a [Post] instance.
  Post({
    required this.postId,
    required this.userId,
    required this.content,
    required this.likes,
    required this.likesCount,
    this.groupId,
    this.eventId,
    this.imageUrl,
    this.createdAt,
  });

  /// Throws [FormatException] if required fields are missing or invalid.
  factory Post.fromMap(Map<String, dynamic> map, String id) {
    if (map['userId'] is! String || map['userId'] == '') {
      throw const FormatException('Invalid or missing userId');
    }
    // Allow content to be empty or null, default to empty string if invalid
    final content = map['content'] is String ? map['content'] as String : '';
    if (map['likes'] != null && map['likes'] is! List) {
      throw const FormatException('Invalid likes format');
    }
    if (map['likesCount'] != null && map['likesCount'] is! int) {
      throw const FormatException('Invalid likesCount format');
    }

    return Post(
      postId: id,
      userId: map['userId'],
      content: content,
      likes: List<String>.from(map['likes'] ?? []),
      likesCount: map['likesCount'] as int? ?? 0,
      groupId: map['groupId'] as String?,
      eventId: map['eventId'] as String?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: map['createdAt'] as String?,
    );
  }

  /// Converts the [Post] to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'likes': likes,
      'likesCount': likesCount,
      'groupId': groupId,
      'eventId': eventId,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}