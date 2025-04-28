class Relationship {
  final String relationshipId;

  Relationship({required this.relationshipId});

  factory Relationship.fromMap(Map<String, dynamic> map) {
    return Relationship(relationshipId: map['relationshipId'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'relationshipId': relationshipId};
  }
}