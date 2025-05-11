import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:bs/models/comment.dart';
import 'package:bs/models/event.dart';
import 'package:bs/models/group.dart';
import 'package:bs/models/place.dart';
import 'package:bs/models/post.dart';
import 'package:bs/models/relationship.dart';
import 'package:bs/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';

class FirebaseDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CloudinaryPublic _cloudinary;
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, List<Post>> _postCache = {};
  final Map<String, List<Event>> _eventCache = {};
  final List<CancelToken> _dioCancelTokens = [];

  FirebaseDataService() {
    _cloudinary = CloudinaryPublic('dmqgpi1zb', 'BoomShoot');
  }

  CollectionReference get eventsRef => _firestore.collection('events');
  CollectionReference get groupsRef => _firestore.collection('groups');
  CollectionReference get relationshipsRef => _firestore.collection('relationships');
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get postsRef => _firestore.collection('posts');
  CollectionReference get placesRef => _firestore.collection('places');

  // Add photo to event
  Future<void> addPhotoToEvent(String eventId, String photoUrl) async {
    try {
      if (eventId.isEmpty) {
        developer.log('addPhotoToEvent: Invalid eventId: empty or blank',
            name: 'FirebaseDataService');
        throw Exception('Event ID cannot be blank');
      }
      if (photoUrl.isEmpty) {
        developer.log('addPhotoToEvent: Invalid photoUrl: empty or blank',
            name: 'FirebaseDataService');
        throw Exception('Photo URL cannot be blank');
      }

      final eventRef = eventsRef.doc(eventId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(eventRef);
        if (!snapshot.exists) {
          developer.log('addPhotoToEvent: Event $eventId does not exist',
              name: 'FirebaseDataService');
          throw Exception('Event does not exist');
        }

        final data = snapshot.data();
        if (data == null) {
          developer.log('addPhotoToEvent: Snapshot data is null for event $eventId',
              name: 'FirebaseDataService');
          throw Exception('Event data is null');
        }

        try {
          final eventData = data as Map<String, dynamic>;
          final event = Event.fromMap(eventData, snapshot.id);
          final updatedPhotos = List<String>.from(event.photos)..add(photoUrl);
          transaction.update(eventRef, {'photos': updatedPhotos});
          developer.log('addPhotoToEvent: Added photo $photoUrl to event $eventId',
              name: 'FirebaseDataService');
        } catch (e) {
          developer.log('addPhotoToEvent: Failed to parse event $eventId: $e',
              name: 'FirebaseDataService');
          throw Exception('Invalid event data: $e');
        }
      });
    } catch (e, stackTrace) {
      developer.log('addPhotoToEvent: Error adding photo to event $eventId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Upload photo and add to event
  Future<void> uploadAndAddPhotoToEvent(String eventId, File photoFile) async {
    try {
      final photoUrl = await uploadPhoto(photoFile.path, eventId);
      await addPhotoToEvent(eventId, photoUrl);
      developer.log(
          'uploadAndAddPhotoToEvent: Successfully uploaded and added photo to event $eventId',
          name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('uploadAndAddPhotoToEvent: Error for event $eventId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Get posts
  Future<List<Post>> getPosts() async {
    if (_postCache['posts'] != null) {
      developer.log('Returning cached posts', name: 'FirebaseDataService');
      return _postCache['posts']!;
    }
    try {
      final snapshot = await postsRef.get();
      final posts = snapshot.docs
          .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      _postCache['posts'] = posts;
      return posts;
    } catch (e) {
      developer.log('Error getting posts: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      if (postId.isEmpty) throw Exception('Post ID cannot be blank');
      final doc = await postsRef.doc(postId).get();
      return doc.exists ? Post.fromMap(doc.data() as Map<String, dynamic>, doc.id) : null;
    } catch (e) {
      developer.log('Error getting post $postId: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get events
  Future<List<Event>> getEvents() async {
    try {
      final querySnapshot = await _firestore.collection('events').get();
      return querySnapshot.docs
          .map((doc) => Event.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      developer.log('Error fetching events: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Get groups
  Future<List<Group>> getGroups() async {
    try {
      final snapshot = await groupsRef.get();
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      developer.log('Error getting groups: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get relationships
  Future<List<Relationship>> getRelationships() async {
    try {
      final snapshot = await relationshipsRef.get();
      return snapshot.docs
          .map((doc) => Relationship.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error getting relationships: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get users
  Future<List<User>> getUsers() async {
    try {
      final snapshot = await usersRef.get();
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error getting users: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    if (userId.isEmpty) {
      developer.log('Invalid userId: empty or blank',
          name: 'FirebaseDataService');
      return null;
    }
    try {
      final doc = await usersRef.doc(userId).get();
      return doc.exists ? User.fromMap(doc.data() as Map<String, dynamic>) : null;
    } catch (e) {
      developer.log('Error getting user $userId: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Add user
  Future<void> addUser(User user) async {
    try {
      await usersRef.doc(user.userId).set(user.toMap());
      developer.log('User added: ${user.username}', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error adding user: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Update user interests
  Future<void> updateUserInterests(String userId, List<String> interests) async {
    try {
      await usersRef.doc(userId).update({'interests': interests});
      developer.log('Updated interests for user $userId',
          name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error updating user interests: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get user groups
  Future<List<Group>> getUserGroups(String userId) async {
    try {
      final snapshot =
      await groupsRef.where('memberIds', arrayContains: userId).get();
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      developer.log('Error getting user groups for $userId: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Create event
  Future<void> createEvent(Event event) async {
    try {
      if (event.name.isEmpty) throw Exception('Event name cannot be blank');
      if (event.creatorId.isEmpty) throw Exception('Creator ID cannot be blank');
      if (event.startTime.isEmpty) throw Exception('Start time cannot be blank');
      if (event.placeId != null) {
        final placeDoc = await placesRef.doc(event.placeId).get();
        if (!placeDoc.exists) throw Exception('Place ID does not exist');
        final place = Place.fromMap(placeDoc.data() as Map<String, dynamic>);
        if (place.organizerId != event.creatorId) {
          throw Exception('Creator is not the organizer of the place');
        }
      }
      final eventRef = eventsRef.doc();
      final eventWithId = event.copyWith(
        eventId: eventRef.id,
        endTime: event.endTime.isEmpty ? Event.calculateEndTime(24) : event.endTime,
        participants: event.participants.isEmpty ? [event.creatorId] : event.participants,
        createdAt: event.createdAt.isEmpty
            ? DateTime.now().toUtc().toIso8601String()
            : event.createdAt,
      );
      await eventRef.set(eventWithId.toMap());
      developer.log('Created event: ${eventWithId.name}',
          name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error creating event: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Add comment
  Future<void> addComment(String postId, Comment comment) async {
    try {
      if (postId.isEmpty) throw Exception('Post ID cannot be blank');
      final commentRef = postsRef.doc(postId).collection('comments').doc();
      final commentWithId = Comment(
        commentId: commentRef.id,
        postId: postId,
        userId: comment.userId,
        content: comment.content,
        timestamp: comment.timestamp,
      );
      await commentRef.set(commentWithId.toMap());
      developer.log('Added comment ${commentRef.id} to post $postId',
          name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error adding comment: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get comments
  Future<List<Comment>> getComments(String postId) async {
    try {
      if (postId.isEmpty) throw Exception('Post ID cannot be blank');
      final snapshot = await postsRef
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), postId: postId))
          .toList();
    } catch (e) {
      developer.log('Error getting comments for post $postId: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Toggle like
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();
      if (postSnapshot.exists) {
        final data = postSnapshot.data()!;
        final likes = List<String>.from(data['likes'] ?? []);
        final currentLikesCount = data['likesCount'] as int? ?? 0;
        if (likes.contains(userId)) {
          likes.remove(userId);
          await postRef.update({
            'likes': likes,
            'likesCount': currentLikesCount - 1,
          });
        } else {
          likes.add(userId);
          await postRef.update({
            'likes': likes,
            'likesCount': currentLikesCount + 1,
          });
        }
        developer.log('Toggled like for post $postId by user $userId',
            name: 'FirebaseDataService');
      }
    } catch (e, stackTrace) {
      developer.log('Error toggling like for post $postId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      if (postId.isEmpty) throw Exception('Post ID cannot be blank');
      await postsRef.doc(postId).delete();
      final commentsSnapshot = await postsRef.doc(postId).collection('comments').get();
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      final likesSnapshot = await postsRef.doc(postId).collection('likes').get();
      for (var doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }
      developer.log('Deleted post $postId', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error deleting post $postId: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Upload post image
  Future<String?> uploadPostImage(File image) async {
    final String cloudName = 'dmqgpi1zb';
    final String apiKey = '747633771146777';
    final String apiSecret = 'AN8Katr3rj4t8Ydvia9jZq-1D7M';

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final paramsToSign = 'timestamp=$timestamp';
    final signature = generateSignature(paramsToSign, apiSecret);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: p.basename(image.path)),
      'api_key': apiKey,
      'timestamp': timestamp.toString(),
      'signature': signature,
    });

    final dio = Dio();
    final cancelToken = CancelToken();
    _dioCancelTokens.add(cancelToken);
    try {
      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: formData,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final url = response.data['secure_url'];
        developer.log('[Cloudinary] Upload OK: $url', name: 'FirebaseDataService');
        return url;
      } else {
        developer.log('[Cloudinary] Upload error: ${response.statusCode}',
            name: 'FirebaseDataService');
        return null;
      }
    } catch (e) {
      developer.log('[Cloudinary] Exception: $e', name: 'FirebaseDataService');
      return null;
    } finally {
      _dioCancelTokens.remove(cancelToken);
    }
  }

  // Generate Cloudinary signature
  String generateSignature(String paramsToSign, String apiSecret) {
    final signString = '$paramsToSign$apiSecret';
    final bytes = utf8.encode(signString);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  Future<void> createPost({
    required String userId,
    required String content,
    required String imageUrl,
    String? groupId,
    String? eventId,
  }) async {
    try {
      final postRef = _firestore.collection('posts').doc();
      final post = Post(
        postId: postRef.id,
        userId: userId,
        content: content,
        imageUrl: imageUrl,
        likes: [],
        likesCount: 0,
        groupId: groupId,
        eventId: eventId,
        createdAt: DateTime.now().toIso8601String()
      );
      await postRef.set(post.toMap());
      developer.log('Created post ${postRef.id}', name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error creating post: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String> uploadPhoto(String path, String userId) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('File does not exist: $path');
      }
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('File size exceeds 10MB: ${fileSize / (1024 * 1024)}MB');
      }
      developer.log('Uploading file: $path, size: ${fileSize / (1024 * 1024)}MB',
          name: 'FirebaseDataService');
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      developer.log('Photo uploaded to Cloudinary: ${response.secureUrl}',
          name: 'FirebaseDataService');
      return response.secureUrl;
    } catch (e) {
      if (e is DioException && e.response != null) {
        developer.log('Cloudinary response: ${e.response?.data}',
            name: 'FirebaseDataService');
      }
      developer.log('Error uploading photo to Cloudinary: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }
  Future<void> createUser({
    required String userId,
    required String username,
    required String email,
    String? profilePicture,
    List<String>? interests,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
  }) async {
    try {
      final user = User(
        userId: userId,
        username: username,
        email: email,
        profilePicture: profilePicture,
        interests: interests ?? [],
        bio: bio ?? '',
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: updatedAt ?? DateTime.now(),
        lastLogin: lastLogin ?? DateTime.now(),
      );
      await usersRef.doc(userId).set(user.toMap());
      developer.log('User created: $userId', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error creating user: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  Future<void> updateLastLogin(String userId) async {
    try {
      await usersRef.doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      developer.log('Last login updated for user $userId', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error updating last login: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }
  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required String username,
    String? profilePicture,
    required List<String> interests,
    String? bio,
    Map<String, bool>? visibility,
  }) async {
    try {
      final updateData = {
        'username': username,
        'interests': interests,
        'bio': bio,
        'profilePicture': profilePicture,
        'visibility': visibility,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await usersRef.doc(userId).update(updateData);
      developer.log('Profile updated for user $userId', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error updating profile: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }
  Future<int> getFollowerCount(String userId) async {
    try {
      final snapshot = await relationshipsRef
          .where('targetUserId', isEqualTo: userId)
          .where('type', isEqualTo: 'follow')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      developer.log('Error getting follower count: $e', name: 'FirebaseDataService');
      return 0;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await relationshipsRef
          .where('sourceUserId', isEqualTo: userId)
          .where('type', isEqualTo: 'follow')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      developer.log('Error getting following count: $e', name: 'FirebaseDataService');
      return 0;
    }
  }

  Future<int> getFriendCount(String userId) async {
    try {
      final snapshot = await relationshipsRef
          .where('type', isEqualTo: 'friend')
          .where('sourceUserId', isEqualTo: userId)
          .get();
      final reverseSnapshot = await relationshipsRef
          .where('type', isEqualTo: 'friend')
          .where('targetUserId', isEqualTo: userId)
          .get();
      return snapshot.docs.length + reverseSnapshot.docs.length;
    } catch (e) {
      developer.log('Error getting friend count: $e', name: 'FirebaseDataService');
      return 0;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture(XFile image, String userId) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      developer.log('Uploaded profile picture: ${response.secureUrl}', name: 'FirebaseDataService');
      return response.secureUrl;
    } catch (e, stackTrace) {
      developer.log('Error uploading profile picture: $e', name: 'FirebaseDataService', stackTrace: stackTrace);
      return null;
    }
  }


  // Save user settings
  Future<void> saveUserSettings({
    required String userId,
    required Map<String, dynamic> settingsUpdate,
  }) async {
    try {
      if (settingsUpdate.containsKey('theme')) {
        final theme = settingsUpdate['theme'] as String?;
        if (theme != null && !['light', 'dark', 'system'].contains(theme)) {
          throw ArgumentError('Invalid theme value: $theme. Must be "light", "dark", or "system".');
        }
      }
      if (settingsUpdate.containsKey('notificationsEnabled')) {
        final notificationsEnabled = settingsUpdate['notificationsEnabled'];
        if (notificationsEnabled != null && notificationsEnabled is! bool) {
          throw ArgumentError('notificationsEnabled must be a boolean');
        }
      }

      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception('User $userId does not exist');
      }

      final currentSettings = Map<String, dynamic>.from(userDoc.data()!['settings'] ?? {});
      currentSettings.addAll(settingsUpdate);

      await userRef.set(
        {'settings': currentSettings},
        SetOptions(merge: true),
      );
      developer.log('Saved settings for user $userId: $currentSettings',
          name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error saving settings for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Get user settings
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final settings = Map<String, dynamic>.from(doc.data()?['settings'] ?? {});
        settings.putIfAbsent('notificationsEnabled', () => true);
        settings.putIfAbsent('theme', () => 'system');
        developer.log('Fetched settings for user $userId: $settings',
            name: 'FirebaseDataService');
        return settings;
      }
      developer.log('No settings found for user $userId, returning defaults',
          name: 'FirebaseDataService');
      return {
        'notificationsEnabled': true,
        'theme': 'system',
      };
    } catch (e, stackTrace) {
      developer.log('Error fetching settings for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Create group
  Future<void> createGroup({
    required String name,
    required String description,
    String? imageUrl,
    required String creatorId,
  }) async {
    try {
      final groupRef = groupsRef.doc();
      final group = Group(
        groupId: groupRef.id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        creatorId: creatorId,
        memberIds: [creatorId],
        postIds: [],
        createdAt: DateTime.now().toIso8601String(),
      );
      await groupRef.set(group.toMap());
      developer.log('Created group ${groupRef.id}', name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error creating group: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Get posts by user
  Future<List<Post>> getPostsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts').where('userId', isEqualTo: userId).get();
      return querySnapshot.docs
          .map((doc) => Post.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      developer.log('Error fetching posts for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Join group
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      final groupRef = groupsRef.doc(groupId);
      await groupRef.update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
      developer.log('User $userId joined group $groupId',
          name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error joining group $groupId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Get group by ID
  Future<Group?> getGroupById(String groupId) async {
    try {
      if (groupId.isEmpty) throw Exception('Group ID cannot be blank');
      final doc = await groupsRef.doc(groupId).get();
      return doc.exists ? Group.fromMap(doc.data() as Map<String, dynamic>, doc.id) : null;
    } catch (e) {
      developer.log('Error getting group $groupId: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      if (eventId.isEmpty) throw Exception('Event ID cannot be blank');
      final doc = await eventsRef.doc(eventId).get();
      return doc.exists ? Event.fromMap(doc.data() as Map<String, dynamic>, doc.id) : null;
    } catch (e) {
      developer.log('Error getting event $eventId: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  // Search groups
  Future<List<Group>> searchGroups(String query) async {
    try {
      final snapshot = await groupsRef
          .where('visibility', isEqualTo: 'public')
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      developer.log('Error buscando grupos: $e', name: 'FirebaseDataService');
      return [];
    }
  }

  // Search events
  Future<List<Event>> searchEvents(String query) async {
    try {
      final snapshot = await eventsRef
          .where('visibility', isEqualTo: 'public')
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();
      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      developer.log('Error buscando eventos: $e', name: 'FirebaseDataService');
      return [];
    }
  }

  // Search comments
  Future<List<Comment>> searchComments(String query) async {
    List<Comment> results = [];
    try {
      final postSnapshot = await postsRef.where('visibility', isEqualTo: 'public').get();
      for (final postDoc in postSnapshot.docs) {
        final postId = postDoc.id;
        final commentsSnapshot = await postsRef
            .doc(postId)
            .collection('comments')
            .where('content', isGreaterThanOrEqualTo: query)
            .where('content', isLessThanOrEqualTo: '$query\uf8ff')
            .get();
        final comments = commentsSnapshot.docs
            .map((doc) => Comment.fromMap(doc.data(), postId: postId));
        results.addAll(comments);
      }
    } catch (e) {
      developer.log('Error buscando comentarios: $e', name: 'FirebaseDataService');
    }
    return results;
  }

  // Create relationship
  Future<void> createRelationship({
    required String sourceUserId,
    required String targetUserId,
    required String type,
  }) async {
    try {
      final id = '${sourceUserId}_${targetUserId}_$type';
      final relationship = Relationship(
        relationshipId: id,
        sourceUserId: sourceUserId,
        targetUserId: targetUserId,
        type: type,
        createdAt: DateTime.now(),
      );
      await relationshipsRef.doc(id).set(relationship.toMap());
      developer.log('Created relationship $id', name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error creating relationship: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Remove relationship
  Future<void> removeRelationship({
    required String sourceUserId,
    required String targetUserId,
    required String type,
  }) async {
    try {
      final id = '${sourceUserId}_${targetUserId}_$type';
      await relationshipsRef.doc(id).delete();
      developer.log('Removed relationship $id', name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error removing relationship: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Check if relationship exists
  Future<bool> hasRelationship({
    required String sourceUserId,
    required String targetUserId,
    required String type,
  }) async {
    try {
      final id = '${sourceUserId}_${targetUserId}_$type';
      final doc = await relationshipsRef.doc(id).get();
      return doc.exists;
    } catch (e, stackTrace) {
      developer.log('Error checking relationship: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Search users (updated to respect visibility)
  Future<List<User>> searchUsers(String query) async {
    try {
      final snapshot = await usersRef
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .where('visibility.isPublic', isEqualTo: true) // Only return public users
          .get();
      return snapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error buscando usuarios: $e', name: 'FirebaseDataService');
      return [];
    }
  }

  // NEW: Toggle follow
  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId.isEmpty || targetUserId.isEmpty) {
        throw Exception('User IDs cannot be empty');
      }
      if (currentUserId == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      final userRef = usersRef.doc(targetUserId);
      final userSnapshot = await userRef.get();
      if (!userSnapshot.exists) {
        throw Exception('Target user does not exist');
      }

      final data = userSnapshot.data() as Map<String, dynamic>;
      final followers = List<String>.from(data['followers'] ?? []);
      final isFollowing = followers.contains(currentUserId);

      await _firestore.runTransaction((transaction) async {
        if (isFollowing) {
          // Unfollow
          transaction.update(userRef, {
            'followers': FieldValue.arrayRemove([currentUserId]),
          });
          await removeRelationship(
            sourceUserId: currentUserId,
            targetUserId: targetUserId,
            type: 'follow',
          );
          developer.log('User $currentUserId unfollowed $targetUserId',
              name: 'FirebaseDataService');
        } else {
          // Follow
          transaction.update(userRef, {
            'followers': FieldValue.arrayUnion([currentUserId]),
          });
          await createRelationship(
            sourceUserId: currentUserId,
            targetUserId: targetUserId,
            type: 'follow',
          );
          developer.log('User $currentUserId followed $targetUserId',
              name: 'FirebaseDataService');
        }
      });
    } catch (e, stackTrace) {
      developer.log('Error toggling follow for user $targetUserId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // NEW: Send friend request
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    try {
      if (currentUserId.isEmpty || targetUserId.isEmpty) {
        throw Exception('User IDs cannot be empty');
      }
      if (currentUserId == targetUserId) {
        throw Exception('Cannot send friend request to yourself');
      }

      final targetUserRef = usersRef.doc(targetUserId);
      final targetUserSnapshot = await targetUserRef.get();
      if (!targetUserSnapshot.exists) {
        throw Exception('Target user does not exist');
      }

      final targetData = targetUserSnapshot.data() as Map<String, dynamic>;
      final friendRequests = List<String>.from(targetData['friendRequests'] ?? []);
      final friends = List<String>.from(targetData['friends'] ?? []);

      if (friends.contains(currentUserId)) {
        throw Exception('Already friends');
      }
      if (friendRequests.contains(currentUserId)) {
        throw Exception('Friend request already sent');
      }

      // Check if the target user has sent a friend request to the current user
      final currentUserRef = usersRef.doc(currentUserId);
      final currentUserSnapshot = await currentUserRef.get();
      if (!currentUserSnapshot.exists) {
        throw Exception('Current user does not exist');
      }

      final currentData = currentUserSnapshot.data() as Map<String, dynamic>;
      final currentFriendRequests = List<String>.from(currentData['friendRequests'] ?? []);

      await _firestore.runTransaction((transaction) async {
        if (currentFriendRequests.contains(targetUserId)) {
          // Mutual friend request: establish friendship
          transaction.update(targetUserRef, {
            'friends': FieldValue.arrayUnion([currentUserId]),
            'friendRequests': FieldValue.arrayRemove([currentUserId]),
          });
          transaction.update(currentUserRef, {
            'friends': FieldValue.arrayUnion([targetUserId]),
            'friendRequests': FieldValue.arrayRemove([targetUserId]),
          });
          await createRelationship(
            sourceUserId: currentUserId,
            targetUserId: targetUserId,
            type: 'friend',
          );
          await createRelationship(
            sourceUserId: targetUserId,
            targetUserId: currentUserId,
            type: 'friend',
          );
          developer.log('Friendship established between $currentUserId and $targetUserId',
              name: 'FirebaseDataService');
        } else {
          // Send friend request
          transaction.update(targetUserRef, {
            'friendRequests': FieldValue.arrayUnion([currentUserId]),
          });
          developer.log('Friend request sent from $currentUserId to $targetUserId',
              name: 'FirebaseDataService');
        }
      });
    } catch (e, stackTrace) {
      developer.log('Error sending friend request to $targetUserId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // NEW: Get user friends
  Future<List<String>> getUserFriends(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }
      final userSnapshot = await usersRef.doc(userId).get();
      if (!userSnapshot.exists) {
        throw Exception('User does not exist');
      }
      final data = userSnapshot.data() as Map<String, dynamic>;
      final friends = List<String>.from(data['friends'] ?? []);
      developer.log('Fetched friends for user $userId: $friends',
          name: 'FirebaseDataService');
      return friends;
    } catch (e, stackTrace) {
      developer.log('Error fetching friends for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Dispose
  void dispose() {
    developer.log('Disposing FirebaseDataService', name: 'FirebaseDataService');
    for (var cancelToken in _dioCancelTokens) {
      cancelToken.cancel('FirebaseDataService disposed');
    }
    _dioCancelTokens.clear();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _postCache.clear();
    _eventCache.clear();
    developer.log('Cleared caches and canceled all requests/subscriptions',
        name: 'FirebaseDataService');
  }

  Future<void> migrateUsers() async {
    try {
      final users = await usersRef.get();
      final batch = _firestore.batch();
      for (var user in users.docs) {
        final data = user.data() as Map<String, dynamic>;
        final updates = <String, dynamic>{};
        if (data['bio'] == null) {
          updates['bio'] = '';
        }
        if (data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }
        if (data['updatedAt'] == null) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
        }
        if (data['lastLogin'] == null) {
          updates['lastLogin'] = FieldValue.serverTimestamp();
        }
        if (updates.isNotEmpty) {
          batch.update(user.reference, updates);
        }
      }
      await batch.commit();
      developer.log('User migration completed', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Migration error: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }
}