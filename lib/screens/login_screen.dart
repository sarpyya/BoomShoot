import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseDataService _dataService = FirebaseDataService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _googleSignIn = kIsWeb
        ? GoogleSignIn(
      clientId: _getClientId(),
      scopes: ['email', 'profile'],
    )
        : GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }

  String? _getClientId() {
    if (kIsWeb) {
      return '577575467607-p4eq30585a72017gvr10mekpu00j1l88.apps.googleusercontent.com';
    }
    return null;
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      firebase_auth.User? firebaseUser;

      if (kIsWeb) {
        developer.log('Starting Google Sign-In for web', name: 'LoginScreen');
        final provider = firebase_auth.GoogleAuthProvider();
        provider.addScope('email profile');
        provider.setCustomParameters({
          'client_id': _getClientId()!,
        });

        final userCredential = await _auth.signInWithPopup(provider);
        firebaseUser = userCredential.user;

        developer.log('Firebase sign-in successful, user: ${firebaseUser?.email}',
            name: 'LoginScreen');
      } else {
        developer.log('Starting Google Sign-In process (mobile)', name: 'LoginScreen');
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          developer.log('Google Sign-In cancelled by user (mobile)', name: 'LoginScreen');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        developer.log('Google Sign-In successful, user: ${googleUser.email}',
            name: 'LoginScreen');
        final googleAuth = await googleUser.authentication;

        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      }

      if (firebaseUser != null) {
        final existingUser = await _dataService.getUserById(firebaseUser.uid);
        User user;
        bool hasInterests = false;

        if (existingUser != null && existingUser.interests.isNotEmpty) {
          user = existingUser;
          hasInterests = true;
        } else {
          user = User(
            userId: firebaseUser.uid,
            username: firebaseUser.displayName ?? 'Usuario',
            email: firebaseUser.email ?? firebaseUser.uid,
            profilePicture: firebaseUser.photoURL,
            interests: existingUser?.interests ?? [],
          );
          await _dataService.addUser(user);
        }

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<AuthProvider>(context, listen: false).setUser(firebaseUser?.uid);
            final destination = hasInterests ? '/home' : '/interest_selection?userId=${firebaseUser?.uid}';
            developer.log('Navigating to $destination', name: 'LoginScreen');
            context.go(destination);
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No se pudo obtener el usuario autenticado';
        });
      }
    } catch (e, stackTrace) {
      developer.log('Error signing in with Google: $e',
          name: 'LoginScreen', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = _parseError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _parseError(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('clientId')) {
      return 'Error de configuración: Client ID no configurado correctamente.';
    } else if (errorStr.contains('storagerelay')) {
      return 'Error de configuración: URI de redirección no válida.';
    } else if (errorStr.contains('network')) {
      return 'Error de red: Verifica tu conexión a internet.';
    } else if (errorStr.contains('popup-closed')) {
      return 'El inicio de sesión fue cancelado por el usuario.';
    }
    return 'Error al iniciar sesión con Google: $error';
  }

  @override
  void dispose() {
    _googleSignIn.disconnect().catchError((e) {
      developer.log('Error disconnecting GoogleSignIn: $e', name: 'LoginScreen');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                elevation: 4,
                color: colorScheme.surface.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Iniciar sesión',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.login, size: 24),
                        label: Text(
                          _isLoading ? 'Cargando...' : 'Continuar con Google',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}