/// A model representing a user in the app.
class User {
  final String userId;
  final String username;
  final String email;
  final String? profilePicture;
  final List<String> interests; // Added

  /// Creates a [User] instance.
  User({
    required this.userId,
    required this.username,
    required this.email,
    this.profilePicture,
    this.interests = const [], // Default to empty list
  });

  /// Creates a [User] from a Firestore document map.
  /// Throws [FormatException] if required fields are missing or invalid.
  factory User.fromMap(Map<String, dynamic> map) {
    if (map['userId'] is! String || map['userId'] == '') {
      throw const FormatException('Invalid or missing userId');
    }
    if (map['username'] is! String || map['username'] == '') {
      throw const FormatException('Invalid or missing username');
    }
    if (map['email'] is! String || map['email'] == '') {
      throw const FormatException('Invalid or missing email');
    }

    return User(
      userId: map['userId'],
      username: map['username'],
      email: map['email'],
      profilePicture: map['profilePicture'] as String?,
      interests: List<String>.from(map['interests'] ?? []),
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
    };
  }
}