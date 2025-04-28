import 'package:bs/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../widgets/base_app_bar.dart';
import '../providers/theme_provider.dart'; // Importamos el ThemeProvider
import 'package:bs/main.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _themeMode = 'system';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final settings = await FirebaseDataService().getUserSettings(widget.userId);
      if (settings != null) {
        setState(() {
          _notificationsEnabled = settings['notificationsEnabled'] ?? true;
          _themeMode = settings['theme'] ?? 'system';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar ajustes: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await FirebaseDataService().saveUserSettings(
        userId: widget.userId,
        notificationsEnabled: _notificationsEnabled,
        theme: _themeMode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ajustes guardados',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      );

      // Convertir _themeMode (String) a ThemeMode
      ThemeMode selectedThemeMode;
      switch (_themeMode) {
        case 'system':
          selectedThemeMode = ThemeMode.system;
          break;
        case 'light':
          selectedThemeMode = ThemeMode.light;
          break;
        case 'dark':
          selectedThemeMode = ThemeMode.dark;
          break;
        default:
          selectedThemeMode = ThemeMode.system; // Valor por defecto
      }

      // Actualizamos el tema en el ThemeProvider
      Provider.of<ThemeProvider>(context, listen: false).setTheme(selectedThemeMode);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar ajustes: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      developer.log('Attempting sign-out', name: 'SettingsScreen');
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      Provider.of<AuthProvider>(context, listen: false).signOut();
      developer.log('Sign-out successful, navigating to /login', name: 'SettingsScreen');
      if (mounted) {
        context.go('/login');
      }
    } catch (e, stackTrace) {
      developer.log('Error signing out: $e', name: 'SettingsScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cerrar sesión: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Cream in light mode, warm dark in dark mode
      appBar: const BaseAppBar(title: 'Perfil'),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(
                'Notificaciones',
                style: TextStyle(
                  color: colorScheme.onSecondary, // Black in light mode, light grayish-cream in dark mode
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSettings();
              },
              activeColor: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
              inactiveThumbColor: colorScheme.onSurface.withOpacity(0.5),
              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tema',
              style: TextStyle(
                color: colorScheme.onSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            DropdownButton<String>(
              value: _themeMode,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'system',
                  child: Text('Sistema'),
                ),
                DropdownMenuItem(
                  value: 'light',
                  child: Text('Claro'),
                ),
                DropdownMenuItem(
                  value: 'dark',
                  child: Text('Oscuro'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _themeMode = value;
                  });
                  _saveSettings();
                }
              },
              style: TextStyle(
                color: colorScheme.onSecondary,
                fontSize: 16,
              ),
              dropdownColor: colorScheme.surface,
              iconEnabledColor: colorScheme.onSecondary,
              underline: Container(
                height: 1,
                color: colorScheme.secondary.withOpacity(0.5), // Subtle underline with secondary color
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary, // Muted mustard yellow in light mode, darker mustard yellow in dark mode
                  foregroundColor: colorScheme.onSecondary, // Black in light mode, light grayish-cream in dark mode
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 3,
                ),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    // Text color is inherited from foregroundColor (onSecondary)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}