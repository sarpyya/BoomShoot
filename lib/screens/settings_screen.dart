import 'package:bs/providers/auth_provider.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:bs/providers/theme_provider.dart';
import 'dart:developer' as developer;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _themeMode = 'system';
  int _autoPlaySpeed = 4;
  String _language = 'es';
  Map<String, bool> _visibility = {
    'isPublic': true,
    'allowFollow': true,
    'allowFriendRequest': true,
    'allowMessages': true,
  };
  bool _isLoading = false;
  bool _isSaving = false;

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      if (userId == null) throw Exception('User not authenticated');
      final settings = await FirebaseDataService().getUserSettings(userId);
      final user = await FirebaseDataService().getUserById(userId);
      setState(() {
        _notificationsEnabled = settings['notificationsEnabled'] ?? true;
        _themeMode = settings['theme'] ?? 'system';
        _autoPlaySpeed = settings['autoPlaySpeed'] ?? 4;
        _language = settings['language'] ?? 'es';
        if (user != null) {
          _visibility = Map<String, bool>.from(user.visibility);
        }
      });
    } catch (e) {
      _showSnackBar('Error al cargar ajustes: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      if (userId == null) throw Exception('User not authenticated');
      await FirebaseDataService().saveUserSettings(
        userId: userId,
        settingsUpdate: {
          'notificationsEnabled': _notificationsEnabled,
          'theme': _themeMode,
          'autoPlaySpeed': _autoPlaySpeed,
          'language': _language,
        },
      );
      final user = await FirebaseDataService().getUserById(userId);
      if (user == null) throw Exception('User not found');
      await FirebaseDataService().updateUserProfile(
        userId: userId,
        username: user.username,
        interests: user.interests,
        bio: user.bio,
        profilePicture: user.profilePicture,
        visibility: _visibility,
      );
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
          selectedThemeMode = ThemeMode.system;
      }
      Provider.of<ThemeProvider>(context, listen: false).setThemeMode(selectedThemeMode);
      _showSnackBar('Ajustes guardados');
    } catch (e) {
      _showSnackBar('Error al guardar ajustes: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirm = await _showSignOutDialog();
    if (confirm != true) return;

    try {
      developer.log('Attempting sign-out', name: 'SettingsScreen');
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      developer.log('Sign-out successful, navigating to /login', name: 'SettingsScreen');
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      _showSnackBar('Error al cerrar sesión: $e', isError: true);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await _showDeleteAccountDialog();
    if (confirm != true) return;

    try {
      developer.log('Attempting account deletion', name: 'SettingsScreen');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      if (userId == null) throw Exception('User not authenticated');
      await FirebaseDataService().usersRef.doc(userId).delete();
      final relationships = await FirebaseDataService().relationshipsRef
          .where('sourceUserId', isEqualTo: userId)
          .get();
      for (var doc in relationships.docs) {
        await doc.reference.delete();
      }
      final reverseRelationships = await FirebaseDataService().relationshipsRef
          .where('targetUserId', isEqualTo: userId)
          .get();
      for (var doc in reverseRelationships.docs) {
        await doc.reference.delete();
      }
      await authProvider.signOut();
      developer.log('Account deletion successful, navigating to /login', name: 'SettingsScreen');
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      _showSnackBar('Error al eliminar cuenta: $e', isError: true);
    }
  }

  Future<bool?> _showSignOutDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text('Cerrar Sesión', style: GoogleFonts.poppins(color: colorScheme.primary)),
          content: Text('¿Estás seguro de que quieres cerrar sesión?', style: GoogleFonts.poppins()),
          backgroundColor: colorScheme.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: colorScheme.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Cerrar Sesión', style: GoogleFonts.poppins(color: colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteAccountDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text('Eliminar Cuenta', style: GoogleFonts.poppins(color: colorScheme.error)),
          content: Text('Esta acción es irreversible. ¿Estás seguro de que quieres eliminar tu cuenta?', style: GoogleFonts.poppins()),
          backgroundColor: colorScheme.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: colorScheme.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Eliminar', style: GoogleFonts.poppins(color: colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: isError ? Colors.white : Theme.of(context).colorScheme.onSurface)),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.surface,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cuenta'),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person, color: colorScheme.primary),
                    title: Text('Editar Perfil', style: GoogleFonts.poppins(fontSize: 16)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/profile'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: colorScheme.error),
                    title: Text('Eliminar Cuenta', style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.error)),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
            _buildSectionTitle('Notificaciones'),
            _buildCard(
              child: SwitchListTile(
                title: Text('Habilitar Notificaciones', style: GoogleFonts.poppins(fontSize: 16)),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSettings();
                },
                activeColor: colorScheme.primary,
                secondary: Icon(Icons.notifications, color: colorScheme.primary),
              ),
            ),
            _buildSectionTitle('Apariencia'),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Tema', style: GoogleFonts.poppins(fontSize: 16)),
                    subtitle: Text(_themeMode == 'system' ? 'Sistema' : _themeMode == 'light' ? 'Claro' : 'Oscuro'),
                    leading: Icon(Icons.brightness_6, color: colorScheme.primary),
                    trailing: DropdownButton<String>(
                      value: _themeMode,
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('Sistema')),
                        DropdownMenuItem(value: 'light', child: Text('Claro')),
                        DropdownMenuItem(value: 'dark', child: Text('Oscuro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _themeMode = value;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Velocidad de Auto-Play', style: GoogleFonts.poppins(fontSize: 16)),
                    subtitle: Text('$_autoPlaySpeed segundos'),
                    leading: Icon(Icons.speed, color: colorScheme.primary),
                    trailing: DropdownButton<int>(
                      value: _autoPlaySpeed,
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('2')),
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 4, child: Text('4')),
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 6, child: Text('6')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _autoPlaySpeed = value;
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionTitle('Privacidad'),
            _buildCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Perfil Público', style: GoogleFonts.poppins(fontSize: 16)),
                    subtitle: const Text('Permitir que otros vean tu perfil'),
                    value: _visibility['isPublic'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _visibility['isPublic'] = value;
                      });
                    },
                    activeColor: colorScheme.primary,
                    secondary: Icon(Icons.visibility, color: colorScheme.primary),
                  ),
                  SwitchListTile(
                    title: Text('Permitir Seguidores', style: GoogleFonts.poppins(fontSize: 16)),
                    subtitle: const Text('Permitir que otros te sigan'),
                    value: _visibility['allowFollow'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _visibility['allowFollow'] = value;
                      });
                    },
                    activeColor: colorScheme.primary,
                    secondary: Icon(Icons.person_add, color: colorScheme.primary),
                  ),
                  SwitchListTile(
                    title: Text('Permitir Solicitudes de Amistad', style: GoogleFonts.poppins(fontSize: 16)),
                    subtitle: const Text('Permitir que otros envíen solicitudes de amistad'),
                    value: _visibility['allowFriendRequest'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _visibility['allowFriendRequest'] = value;
                      });
                    },
                    activeColor: colorScheme.primary,
                    secondary: Icon(Icons.group_add, color: colorScheme.primary),
                  ),
                  SwitchListTile(
                    title: Text('Permitir Mensajes', style: GoogleFonts.poppins(fontSize: 16)),
                    subtitle: const Text('Permitir que otros te envíen mensajes'),
                    value: _visibility['allowMessages'] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _visibility['allowMessages'] = value;
                      });
                    },
                    activeColor: colorScheme.primary,
                    secondary: Icon(Icons.message, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                        : Text('Guardar Privacidad', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            ),
            _buildSectionTitle('Idioma'),
            _buildCard(
              child: ListTile(
                title: Text('Idioma', style: GoogleFonts.poppins(fontSize: 16)),
                subtitle: Text(_language == 'es' ? 'Español' : 'English'),
                leading: Icon(Icons.language, color: colorScheme.primary),
                trailing: DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _language = value;
                      });
                      _saveSettings();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text('Cerrar Sesión', style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}