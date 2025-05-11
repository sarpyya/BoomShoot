import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String username;
  final String email;
  final String? profilePicture;
  final List<String> interests;
  final Map<String, dynamic> settings;
  final Map<String, bool> visibility;
  final String? bio; // Added for user biography
  final DateTime? createdAt; // Added for creation timestamp
  final DateTime? updatedAt; // Added for update timestamp
  final DateTime? lastLogin; // Added for last login tracking

  /// Creates a [User] instance with default values for optional fields.
  User({
    required this.userId,
    required this.username,
    required this.email,
    this.profilePicture,
    this.interests = const [],
    this.settings = const {},
    this.visibility = const {
      'isPublic': true,
      'allowFollow': true,
      'allowFriendRequest': true,
      'allowMessages': true,
    },
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  /// Creates a [User] from a Firestore document map.
  /// Provides defaults for missing or invalid fields to ensure compatibility.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'] is String && map['userId'].isNotEmpty ? map['userId'] : 'unknown',
      username: map['username'] is String && map['username'].isNotEmpty ? map['username'] : 'Usuario',
      email: map['email'] is String && map['email'].isNotEmpty ? map['email'] : 'no-email@example.com',
      profilePicture: map['profilePicture'] is String ? map['profilePicture'] : null,
      interests: map['interests'] is List ? List<String>.from(map['interests']) : [],
      settings: map['settings'] is Map ? Map<String, dynamic>.from(map['settings']) : {},
      visibility: map['visibility'] is Map
          ? Map<String, bool>.from(map['visibility'])
          : {
        'isPublic': true,
        'allowFollow': true,
        'allowFriendRequest': true,
        'allowMessages': true,
      },
      bio: map['bio'] is String ? map['bio'] : null,
      createdAt: map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] is Timestamp ? (map['updatedAt'] as Timestamp).toDate() : null,
      lastLogin: map['lastLogin'] is Timestamp ? (map['lastLogin'] as Timestamp).toDate() : null,
    );
  }

  /// Converts the [User] to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'profilePicture': profilePicture,
      'interests': interests,
      'settings': settings,
      'visibility': visibility,
      'bio': bio,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  /// Creates a copy of the [User] with updated fields.
  User copyWith({
    String? userId,
    String? username,
    String? email,
    String? profilePicture,
    List<String>? interests,
    Map<String, dynamic>? settings,
    Map<String, bool>? visibility,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      interests: interests ?? this.interests,
      settings: settings ?? this.settings,
      visibility: visibility ?? this.visibility,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}