import 'package:flutter/material.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bs/providers/auth_provider.dart';
import 'dart:developer' as developer;

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String? _errorMessage;
  final FirebaseDataService _dataService = FirebaseDataService();
  final AuthProvider _authProvider;
  static const String _themeKey = 'themeMode';
  bool _isLoading = false;

  ThemeMode get themeMode => _themeMode;
  String? get errorMessage => _errorMessage;

  ThemeProvider(this._authProvider) {
    _init();
  }

  Future<void> _init() async {
    await _loadLocalThemeMode();
    final userId = _authProvider.userId;
    if (userId != null && userId.isNotEmpty) {
      await _loadThemeModeFromFirebase(userId);
    }
  }

  Future<void> _loadLocalThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? 'system';
      _themeMode = _themeModeFromString(themeString);
      notifyListeners();
      developer.log('Tema cargado localmente: $themeString', name: 'ThemeProvider');
    } catch (e) {
      developer.log('Error al cargar el tema local: $e', name: 'ThemeProvider');
      _errorMessage = 'Error al cargar el tema local: $e';
      notifyListeners();
    }
  }

  Future<void> _loadThemeModeFromFirebase(String userId) async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final settings = await _dataService.getUserSettings(userId);
      final themeString = settings['theme'] as String? ?? 'system';
      final firebaseTheme = _themeModeFromString(themeString);

      if (_themeMode != firebaseTheme) {
        _themeMode = firebaseTheme;
        // Save to SharedPreferences for consistency
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themeKey, themeString);
        notifyListeners();
        developer.log('Tema actualizado desde Firebase: $themeString', name: 'ThemeProvider');
      }
    } catch (e) {
      developer.log('Error cargando tema desde Firebase: $e', name: 'ThemeProvider');
      _errorMessage = 'Error al cargar el tema desde Firebase: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      final themeString = _themeModeToString(mode);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeString);

      // Save to Firebase if user is authenticated
      final userId = _authProvider.userId;
      if (userId != null && userId.isNotEmpty) {
        await _dataService.saveUserSettings(
          userId: userId,
          settingsUpdate: {'theme': themeString},
        );
      }

      _errorMessage = null;
      notifyListeners();
      developer.log('Tema guardado: $themeString', name: 'ThemeProvider');
    } catch (e) {
      developer.log('Error guardando tema: $e', name: 'ThemeProvider');
      _errorMessage = 'Error al guardar el tema: $e';
      notifyListeners();
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}


// Basado en el diseño de PostCard
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFF59D2A), // Orange
  brightness: Brightness.light,
  primary: const Color(0xFFF59D2A),
  onPrimary: const Color(0xFFFFFFFF),
  secondary: const Color(0xFF424242),
  onSecondary: const Color(0xFF9E9E9E),
  surface: const Color(0xFFFAFAFA),
  onSurface: const Color(0xFF212121),
  background: const Color(0xFFFAFAFA),
  onBackground: const Color(0xFF212121),
  error: const Color(0xFFE53935),
  onError: const Color(0xFFFFFFFF),
  outline: const Color(0xFFBDBDBD),
  shadow: const Color(0xFF000000),
  inverseSurface: const Color(0xFF303030),
  onInverseSurface: const Color(0xFFFFFFFF),
  primaryContainer: const Color(0xFFFFE0B2),
  onPrimaryContainer: const Color(0xFF212121),
  secondaryContainer: const Color(0xFFEEEEEE),
  onSecondaryContainer: const Color(0xFF212121),
  tertiary: const Color(0xFF757575),
  onTertiary: const Color(0xFFFFFFFF),
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFF59D2A), // Consistent with light
  brightness: Brightness.dark,
  primary: const Color(0xFFF59D2A),
  onPrimary: const Color(0xFF000000),
  secondary: const Color(0xFFEEEEEE),
  onSecondary: const Color(0xFF616161),
  surface: const Color(0xFF212121),
  onSurface: const Color(0xFFFAFAFA),
  background: const Color(0xFF212121),
  onBackground: const Color(0xFFFAFAFA),
  error: const Color(0xFFE53935),
  onError: const Color(0xFFFFFFFF),
  outline: const Color(0xFF757575),
  shadow: const Color(0xFF000000),
  inverseSurface: const Color(0xFFFAFAFA),
  onInverseSurface: const Color(0xFF212121),
  primaryContainer: const Color(0xFF424242),
  onPrimaryContainer: const Color(0xFFFFFFFF),
  secondaryContainer: const Color(0xFF424242),
  onSecondaryContainer: const Color(0xFFFAFAFA),
  tertiary: const Color(0xFF9E9E9E),
  onTertiary: const Color(0xFFFFFFFF),
);