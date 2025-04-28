class Place {
  final String placeId;
  final String name;
  final String address;
  final String organizerId;
  final List<String> images;
  final double rating;

  Place({
    required this.placeId,
    required this.name,
    required this.address,
    required this.organizerId,
    required this.images,
    required this.rating,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      placeId: map['placeId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      organizerId: map['organizerId'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'organizerId': organizerId,
      'images': images,
      'rating': rating,
    };
  }
}