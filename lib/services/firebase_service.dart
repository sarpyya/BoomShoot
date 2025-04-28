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
  final List<CancelToken> _dioCancelTokens = []; // Track Dio requests

  FirebaseDataService() {
    _cloudinary = CloudinaryPublic('dmqgpi1zb', 'BoomShoot');
  }

  CollectionReference get eventsRef => _firestore.collection('events');
  CollectionReference get groupsRef => _firestore.collection('groups');
  CollectionReference get relationshipsRef =>
      _firestore.collection('relationships');
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get postsRef => _firestore.collection('posts');
  CollectionReference get placesRef => _firestore.collection('places');

  // Existing methods (unchanged)
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

  Future<void> addUser(User user) async {
    try {
      await usersRef.doc(user.userId).set(user.toMap());
      developer.log('User added: ${user.username}', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error adding user: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

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

  Future<List<Group>> getUserGroups(String userId) async {
    try {
      final snapshot =
      await groupsRef.where('members', arrayContains: userId).get();
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      developer.log('Error getting user groups for $userId: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

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

  Future<void> addComment(String postId, Comment comment) async {
    try {
      if (postId.isEmpty) throw Exception('Post ID cannot be blank');
      if (comment.commentId.isEmpty) throw Exception('Comment ID cannot be blank');
      await postsRef
          .doc(postId)
          .collection('comments')
          .doc(comment.commentId)
          .set(comment.toMap());
      developer.log('Added comment to post $postId', name: 'FirebaseDataService');
    } catch (e) {
      developer.log('Error adding comment: $e', name: 'FirebaseDataService');
      rethrow;
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    try {
      if (postId.isEmpty) throw Exception('Post ID cannot be blank');
      final snapshot = await postsRef
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => Comment.fromMap(doc.data())).toList();
    } catch (e) {
      developer.log('Error getting comments for post $postId: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

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

  Future<void> deletePost(String postId) async {
    try {
      if (postId.isEmpty) throw Exception('Post ID cannot be blank');
      await postsRef.doc(postId).delete();
      final commentsSnapshot =
      await postsRef.doc(postId).collection('comments').get();
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      final likesSnapshot =
      await postsRef.doc(postId).collection('likes').get();
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
    _dioCancelTokens.add(cancelToken); // Track Dio request
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
      _dioCancelTokens.remove(cancelToken); // Clean up
    }
  }

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
        createdAt: DateTime.now().toIso8601String(),
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
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(path, resourceType: CloudinaryResourceType.Image),
      );
      developer.log('Photo uploaded to Cloudinary: ${response.secureUrl}',
          name: 'FirebaseDataService');
      return response.secureUrl;
    } catch (e) {
      developer.log('Error uploading photo to Cloudinary: $e',
          name: 'FirebaseDataService');
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required String username,
    String? profilePicture,
    required List<String> interests,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'username': username,
        'profilePicture': profilePicture,
        'interests': interests,
      });
      developer.log('Updated profile for user $userId',
          name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error updating profile for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String?> uploadProfilePicture(XFile image) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path,
            resourceType: CloudinaryResourceType.Image),
      );
      developer.log('Uploaded profile picture: ${response.secureUrl}',
          name: 'FirebaseDataService');
      return response.secureUrl;
    } catch (e, stackTrace) {
      developer.log('Error uploading profile picture: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> saveUserSettings({
    required String userId,
    required bool notificationsEnabled,
    required String theme,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.set(
        {
          'settings': {
            'notificationsEnabled': notificationsEnabled,
            'theme': theme,
          },
        },
        SetOptions(merge: true), // Merge with existing document, create if it doesn't exist
      );
      developer.log('Saved settings for user $userId', name: 'FirebaseDataService');
    } catch (e, stackTrace) {
      developer.log('Error saving settings for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final settings = doc.data()?['settings'] as Map<String, dynamic>?;
        developer.log('Fetched settings for user $userId: $settings',
            name: 'FirebaseDataService');
        return settings;
      }
      developer.log('No settings found for user $userId', name: 'FirebaseDataService');
      return null;
    } catch (e, stackTrace) {
      developer.log('Error fetching settings for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createGroup({
    required String name,
    required String description,
    String? imageUrl,
    required String creatorId,
  }) async {
    try {
      final groupRef = _firestore.collection('groups').doc();
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

  Future<List<Post>> getPostsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs
          .map((doc) => Post.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      developer.log('Error fetching posts for user $userId: $e',
          name: 'FirebaseDataService', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> joinGroup(String groupId, String userId) async {
    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
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

  void dispose() {
    developer.log('Disposing FirebaseDataService', name: 'FirebaseDataService');
    // Cancel Dio requests
    for (var cancelToken in _dioCancelTokens) {
      cancelToken.cancel('FirebaseDataService disposed');
    }
    _dioCancelTokens.clear();
    // Cancel Firestore stream subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    // Clear caches
    _postCache.clear();
    _eventCache.clear();
    developer.log('Cleared caches and canceled all requests/subscriptions',
        name: 'FirebaseDataService');
  }
}