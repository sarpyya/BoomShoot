import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

final lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF9E7437), // Medium brown as the seed color
  brightness: Brightness.light,
  primary: const Color(0xFF573700),   // Dark brown for primary actions (buttons)
  secondary: const Color(0xFFE6B575), // Muted mustard yellow for secondary actions
  surface: const Color(0xFFFFE29F),   // Very light yellowish-cream for surfaces
  onSurface: const Color(0xFFFBC987), // Light yellowish-orange for text/icons on surfaces
  onPrimary: const Color(0xFF573700),           // White for text/icons on primary
  onSecondary: Colors.black,          // Black for text/icons on secondary
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6B5025), // Darker shade of medium brown
  brightness: Brightness.dark,
  primary: const Color(0xFF8A6F47),   // Muted dark brown for primary actions
  secondary: const Color(0xFFA07C3F), // Darker mustard yellow for secondary actions
  surface: const Color(0xFF2A2520),   // Warm dark grayish-brown for surfaces
  onSurface: const Color(0xFF4A3D3D), // Pale yellowish-cream for text/icons on surfaces
  onPrimary: Colors.white,            // White for text/icons on primary
  onSecondary: const Color(0xFFE0E0E0), // Light grayish-cream for text/icons on secondary
);