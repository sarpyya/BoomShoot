class Review {
  final String reviewId;
  final String eventId;
  final String userId;
  final double rating;
  final String comment;

  Review({
    required this.reviewId,
    required this.eventId,
    required this.userId,
    required this.rating,
    required this.comment,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      reviewId: map['reviewId'] ?? '',
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'eventId': eventId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
    };
  }
}