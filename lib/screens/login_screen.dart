import 'package:bs/providers/auth_provider.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  bool _showEmailLogin = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).signInWithGoogle();
      // Navigation handled by GoRouter's refreshListenable
    } catch (e, stackTrace) {
      developer.log('Google Sign-In error: $e', name: 'LoginScreen', stackTrace: stackTrace);
      setState(() {
        _errorMessage = _parseError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // Navigation handled by GoRouter's refreshListenable
    } catch (e, stackTrace) {
      developer.log('Email Sign-In error: $e', name: 'LoginScreen', stackTrace: stackTrace);
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
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('clientid') || errorStr.contains('invalid_client')) {
      return 'Error de configuración: Client ID no válido.';
    } else if (errorStr.contains('storagerelay') || errorStr.contains('redirect_uri')) {
      return 'Error de configuración: URI de redirección no válida.';
    } else if (errorStr.contains('network') || errorStr.contains('failed to connect')) {
      return 'Error de red: Verifica tu conexión a internet.';
    } else if (errorStr.contains('popup-closed') || errorStr.contains('cancelled')) {
      return 'El inicio de sesión fue cancelado.';
    } else if (errorStr.contains('wrong-password')) {
      return 'Contraseña incorrecta.';
    } else if (errorStr.contains('user-not-found')) {
      return 'No se encontró un usuario con este correo.';
    } else if (errorStr.contains('invalid-email')) {
      return 'Correo electrónico no válido.';
    }
    return 'Error al iniciar sesión: $error';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Photo Sharing',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conecta y comparte momentos',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showEmailLogin
                            ? Form(
                          key: _formKey,
                          child: Column(
                            key: const ValueKey('email_form'),
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Correo electrónico',
                                  labelStyle: GoogleFonts.poppins(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa tu correo';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Correo no válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  labelStyle: GoogleFonts.poppins(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa tu contraseña';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading || _isGoogleLoading ? null : _signInWithEmail,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  'Iniciar sesión',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showEmailLogin = false;
                                    _errorMessage = null;
                                  });
                                },
                                child: Text(
                                  'Volver',
                                  style: GoogleFonts.poppins(color: colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                        )
                            : Column(
                          key: const ValueKey('google_login'),
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading || _isGoogleLoading ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 2,
                                side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                              ),
                              icon: _isGoogleLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : Image.asset(
                                'assets/google_logo.png',
                                height: 24,
                              ),
                              label: Text(
                                _isGoogleLoading ? 'Cargando...' : 'Continuar con Google',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading || _isGoogleLoading
                                  ? null
                                  : () {
                                setState(() {
                                  _showEmailLogin = true;
                                  _errorMessage = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              icon: const Icon(Icons.email, size: 24),
                              label: Text(
                                'Iniciar con correo',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context.go('/signup'),
                              child: Text(
                                '¿No tienes cuenta? Regístrate',
                                style: GoogleFonts.poppins(color: colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
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