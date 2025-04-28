class Group {
  final String groupId;
  final String name;
  final String description;
  final String? imageUrl;
  final String creatorId;
  final List<String> memberIds;
  final List<String> postIds;
  final String createdAt;

  Group({
    required this.groupId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.creatorId,
    required this.memberIds,
    required this.postIds,
    required this.createdAt,
  });

  factory Group.fromMap(Map<String, dynamic> data, String groupId) {
    return Group(
      groupId: groupId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      postIds: List<String>.from(data['postIds'] ?? []),
      createdAt: data['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'postIds': postIds,
      'createdAt': createdAt,
    };
  }
}