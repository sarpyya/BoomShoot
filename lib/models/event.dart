class Event {
  final String eventId;
  final String name;
  final String creatorId;
  final String startTime;
  final String endTime;
  final List<String> participants;
  final String createdAt;
  final String? placeId;
  final List<String> photos;
  final String? imageUrl;
  final String? address; // Human-readable address
  final String? location; // Coordinates (lat,lng)
  final String? description;
  final List<String> interests;
  final String visibility;

  Event({
    required this.eventId,
    required this.name,
    required this.creatorId,
    required this.startTime,
    required this.endTime,
    required this.participants,
    required this.createdAt,
    this.placeId,
    required this.photos,
    this.imageUrl,
    this.address,
    this.location, // New field for coordinates
    this.description,
    this.interests = const [],
    this.visibility = 'public',
  });

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    if (map['name'] is! String || map['name'] == '') {
      throw const FormatException('Invalid or missing name');
    }
    if (map['creatorId'] is! String || map['creatorId'] == '') {
      throw const FormatException('Invalid or missing creatorId');
    }
    if (map['startTime'] is! String || map['startTime'] == '') {
      throw const FormatException('Invalid or missing startTime');
    }
    if (map['endTime'] is! String || map['endTime'] == '') {
      throw const FormatException('Invalid or missing endTime');
    }
    if (map['createdAt'] is! String || map['createdAt'] == '') {
      throw const FormatException('Invalid or missing createdAt');
    }
    if (map['participants'] != null && map['participants'] is! List) {
      throw const FormatException('Invalid participants format');
    }
    if (map['photos'] != null && map['photos'] is! List) {
      throw const FormatException('Invalid photos format');
    }
    if (map['interests'] != null && map['interests'] is! List) {
      throw const FormatException('Invalid interests format');
    }

    return Event(
      eventId: id,
      name: map['name'],
      creatorId: map['creatorId'],
      startTime: map['startTime'],
      endTime: map['endTime'] ?? Event.calculateEndTime(2),
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: map['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
      placeId: map['placeId'] as String?,
      photos: List<String>.from(map['photos'] ?? []),
      imageUrl: map['imageUrl'] as String?,
      address: map['address'] as String?, // Readable address
      location: map['location'] as String? ?? map['address'] as String?, // Coordinates (fallback to old address field for backward compatibility)
      description: map['description'] as String?,
      interests: List<String>.from(map['interests'] ?? []),
      visibility: map['visibility'] as String? ?? 'public',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'creatorId': creatorId,
      'startTime': startTime,
      'endTime': endTime,
      'participants': participants,
      'createdAt': createdAt,
      'placeId': placeId,
      'photos': photos,
      'imageUrl': imageUrl,
      'address': address,
      'location': location, // Store coordinates separately
      'description': description,
      'interests': interests,
      'visibility': visibility,
    };
  }

  Event copyWith({
    String? eventId,
    String? name,
    String? creatorId,
    String? startTime,
    String? endTime,
    List<String>? participants,
    String? createdAt,
    String? placeId,
    List<String>? photos,
    String? imageUrl,
    String? address,
    String? location,
    String? description,
    List<String>? interests,
    String? visibility,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      placeId: placeId ?? this.placeId,
      photos: photos ?? this.photos,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      location: location ?? this.location,
      description: description ?? this.description,
      interests: interests ?? this.interests,
      visibility: visibility ?? this.visibility,
    );
  }

  static String calculateEndTime(int hours) {
    final now = DateTime.now().toUtc();
    final end = now.add(Duration(hours: hours));
    return end.toIso8601String();
  }
}
