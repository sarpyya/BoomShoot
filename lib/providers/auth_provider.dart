import 'package:bs/models/user.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class AuthProvider with ChangeNotifier {
  String? _userId;
  User? _user;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseDataService _dataService = FirebaseDataService();
  late final GoogleSignIn _googleSignIn;

  String? get userId => _userId;
  User? get user => _user;
  bool get isAuthenticated => _userId != null;

  AuthProvider() {
    _googleSignIn = kIsWeb
        ? GoogleSignIn(
      clientId: _getClientId(),
      scopes: ['email', 'profile'],
    )
        : GoogleSignIn(scopes: ['email', 'profile']);

    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _clearUser();
      } else {
        await _setUserFromFirebase(firebaseUser);
      }
    });
  }

  String? _getClientId() {
    if (kIsWeb) {
      return '577575467607-p4eq30585a72017gvr10mekpu00j1l88.apps.googleusercontent.com';
    }
    return null;
  }

  Future<void> _setUserFromFirebase(firebase_auth.User firebaseUser) async {
    try {
      _userId = firebaseUser.uid;
      await _dataService.updateLastLogin(firebaseUser.uid);
      _user = await _dataService.getUserById(firebaseUser.uid);

      if (_user == null) {
        _user = User(
          userId: firebaseUser.uid,
          username: firebaseUser.displayName ?? 'Usuario',
          email: firebaseUser.email ?? firebaseUser.uid,
          profilePicture: firebaseUser.photoURL,
          interests: [],
          bio: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await _dataService.createUser(
          userId: _user!.userId,
          username: _user!.username,
          email: _user!.email,
          profilePicture: _user!.profilePicture,
          interests: _user!.interests,
          bio: _user!.bio,
          createdAt: _user!.createdAt,
          updatedAt: _user!.updatedAt,
          lastLogin: _user!.lastLogin,
        );
      }

      developer.log('AuthProvider: User set to ${_user!.userId}', name: 'AuthProvider');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Error setting user: $e', name: 'AuthProvider', stackTrace: stackTrace);
      _clearUser();
      rethrow;
    }
  }

  void _clearUser() {
    _userId = null;
    _user = null;
    developer.log('AuthProvider: User cleared', name: 'AuthProvider');
    notifyListeners();
  }

  /// Refreshes the user data from Firebase and Firestore.
  Future<void> refreshUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _setUserFromFirebase(currentUser);
    } else {
      _clearUser();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      firebase_auth.User? firebaseUser;

      if (kIsWeb) {
        final provider = firebase_auth.GoogleAuthProvider();
        provider.addScope('email profile');
        provider.setCustomParameters({'client_id': _getClientId()!});
        final userCredential = await _auth.signInWithPopup(provider);
        firebaseUser = userCredential.user;
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          developer.log('Google Sign-In cancelled', name: 'AuthProvider');
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      }

      if (firebaseUser != null) {
        await _setUserFromFirebase(firebaseUser);
      } else {
        throw Exception('No user returned from Google Sign-In');
      }
    } catch (e, stackTrace) {
      developer.log('Google Sign-In error: $e', name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        await _setUserFromFirebase(firebaseUser);
      } else {
        throw Exception('No user returned from email sign-in');
      }
    } catch (e, stackTrace) {
      developer.log('Email Sign-In error: $e', name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final now = DateTime.now();
        final user = User(
          userId: firebaseUser.uid,
          username: username.trim(),
          email: email.trim(),
          interests: [],
          bio: '',
          createdAt: now,
          updatedAt: now,
          lastLogin: now,
        );
        await _dataService.createUser(
          userId: user.userId,
          username: user.username,
          email: user.email,
          profilePicture: user.profilePicture,
          interests: user.interests,
          bio: user.bio,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          lastLogin: user.lastLogin,
        );
        _userId = firebaseUser.uid;
        _user = user;
        developer.log('AuthProvider: User signed up: ${user.userId}', name: 'AuthProvider');
        notifyListeners();
      } else {
        throw Exception('No user returned from sign-up');
      }
    } catch (e, stackTrace) {
      developer.log('Sign-up error: $e', name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _clearUser();
    } catch (e, stackTrace) {
      developer.log('Sign-out error: $e', name: 'AuthProvider', stackTrace: stackTrace);
      rethrow;
    }
  }
}