class Comment {
  final String commentId;
  final String postId;
  final String userId;
  final String content;
  final String timestamp;

  Comment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.content,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      commentId: map['commentId'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'content': content,
      'timestamp': timestamp,
    };
  }
}