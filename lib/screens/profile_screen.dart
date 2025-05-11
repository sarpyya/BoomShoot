import 'package:bs/models/user.dart';
import 'package:bs/providers/auth_provider.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseDataService _dataService = FirebaseDataService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  List<String> _interests = [];
  String? _profilePicture;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      setState(() {
        _usernameController.text = authProvider.user!.username;
        _bioController.text = authProvider.user!.bio ?? '';
        _interests = List.from(authProvider.user!.interests);
        _profilePicture = authProvider.user!.profilePicture;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _dataService.updateUserProfile(
        userId: authProvider.userId!,
        username: _usernameController.text.trim(),
        profilePicture: _profilePicture,
        interests: _interests,
        bio: _bioController.text.trim(),
      );
      await authProvider.refreshUser();
      setState(() {
        _isEditing = false;
      });
    } catch (e, stackTrace) {
      developer.log('Error saving profile: $e', name: 'ProfileScreen', stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Error al guardar el perfil: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        final url = await _dataService.uploadProfilePicture(pickedFile, Provider.of<AuthProvider>(context, listen: false).userId!);
        if (url != null) {
          setState(() {
            _profilePicture = url;
          });
        } else {
          setState(() {
            _errorMessage = 'No se pudo subir la imagen';
          });
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error picking image: $e', name: 'ProfileScreen', stackTrace: stackTrace);
      setState(() {
        _errorMessage = 'Error al subir la imagen: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox();
    }

    return FutureBuilder(
      future: _loadUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Perfil', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditing = true),
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.signOut();
                  context.go('/login');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isEditing
                  ? Form(
                key: _formKey,
                child: Column(
                  key: const ValueKey('edit_form'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _profilePicture != null ? NetworkImage(_profilePicture!) : null,
                              child: _profilePicture == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            if (_isLoading) const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: 'Biografía',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      maxLength: 150,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text('Intereses', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: ['Fotografía', 'Viajes', 'Arte', 'Música'].map((interest) {
                        final isSelected = _interests.contains(interest);
                        return ChoiceChip(
                          label: Text(interest, style: GoogleFonts.poppins()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _interests.add(interest);
                              } else {
                                _interests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: colorScheme.primary,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text('Guardar', style: GoogleFonts.poppins(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: Text('Cancelar', style: GoogleFonts.poppins(color: colorScheme.primary)),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(color: colorScheme.error, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              )
                  : Column(
                key: const ValueKey('view_profile'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profilePicture != null ? NetworkImage(_profilePicture!) : null,
                      child: _profilePicture == null ? const Icon(Icons.person, size: 50) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _usernameController.text,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bioController.text.isEmpty ? 'Sin biografía' : _bioController.text,
                    style: GoogleFonts.poppins(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Intereses',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _interests.isEmpty
                        ? [Text('Sin intereses', style: GoogleFonts.poppins())]
                        : _interests
                        .map((interest) => Chip(
                      label: Text(interest, style: GoogleFonts.poppins()),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Miembro desde: ${_formatDate(authProvider.user!.createdAt)}',
                    style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(color: colorScheme.error, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Desconocido';
    return '${date.day}/${date.month}/${date.year}';
  }
}