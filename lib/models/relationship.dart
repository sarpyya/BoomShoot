import 'package:cloud_firestore/cloud_firestore.dart';

class Relationship {
  final String relationshipId;
  final String sourceUserId; // el que realiza la acción
  final String targetUserId; // el receptor de la acción
  final String type; // friend, follow, favorite, report, block, etc.
  final DateTime createdAt;

  Relationship({
    required this.relationshipId,
    required this.sourceUserId,
    required this.targetUserId,
    required this.type,
    required this.createdAt,
  });

  factory Relationship.fromMap(Map<String, dynamic> map) {
    return Relationship(
      relationshipId: map['relationshipId'] ?? '',
      sourceUserId: map['sourceUserId'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      type: map['type'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'relationshipId': relationshipId,
      'sourceUserId': sourceUserId,
      'targetUserId': targetUserId,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
