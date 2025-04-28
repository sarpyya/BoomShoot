import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/comment.dart';
import 'package:bs/models/event.dart';
import 'package:bs/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class MainViewModel extends ChangeNotifier {
  final FirebaseDataService _dataService = FirebaseDataService();
  List<Post> _posts = [];
  List<Event> _events = [];
  Map<String, List<Comment>> _postComments = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastUserId;
  DateTime? _lastFetchTime;
  bool _disposed = false; // moved here for clarity

  // Simplified getters
  List<Post> get posts => _posts;
  List<Event> get events => _events;
  Map<String, List<Comment>> get postComments => _postComments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchData(String userId) async {
    if (_isLoading ||
        _lastUserId == userId &&
            _lastUserId != null &&
            _lastFetchTime != null &&
            DateTime.now().difference(_lastFetchTime!).inSeconds < 10) {
      developer.log('Skipping fetchData: Already loading or recently fetched', name: 'MainViewModel');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastUserId = userId;
    _lastFetchTime = DateTime.now();

    notifyListeners(); // Notify listeners that we are loading

    try {
      developer.log('Fetching data for user: $userId', name: 'MainViewModel');
      final posts = await _dataService.getPosts();
      final events = await _dataService.getEvents();
      final postComments = <String, List<Comment>>{};

      for (var post in posts) {
        final comments = await _dataService.getComments(post.postId);
        postComments[post.postId] = comments;
      }

      // Update state only if not disposed
      if (!_disposed) {
        _posts = posts;
        _events = events;
        _postComments = postComments;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }

    } catch (e, stackTrace) {
      developer.log('Error fetching data: $e', name: 'MainViewModel', stackTrace: stackTrace);

      // Handle different error types
      if (e is FirebaseException) {
        _errorMessage = 'Firebase Error: ${e.message}';
      } else {
        _errorMessage = 'Error al cargar los datos: $e';
      }

      _isLoading = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  void reset() {
    _posts = [];
    _events = [];
    _postComments = {};
    _isLoading = false;
    _errorMessage = null;
    _lastUserId = null;
    _lastFetchTime = null;

    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    developer.log('Disposing MainViewModel', name: 'MainViewModel');
    _disposed = true; // Set disposed flag before calling super.dispose
    super.dispose();
  }

  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
