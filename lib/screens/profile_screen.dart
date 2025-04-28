import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/post.dart';
import 'package:bs/models/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bs/widgets/custom_scaffold.dart'; // Asegúrate de importar tu CustomScaffold

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _username;
  List<String>? _interests;
  String? _profilePicture;
  bool _isEditing = false;
  final TextEditingController _usernameController = TextEditingController();
  final List<String> _availableInterests = [
    'photography',
    'travel',
    'music',
    'art',
    'food',
    'sports',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageUrl = await FirebaseDataService().uploadProfilePicture(image);
      if (imageUrl != null) {
        setState(() {
          _profilePicture = imageUrl;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseDataService().updateUserProfile(
          userId: widget.userId,
          username: _usernameController.text,
          profilePicture: _profilePicture,
          interests: _interests!,
        );
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perfil actualizado',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar perfil: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScaffold(
      title: 'Perfil',
      showBackButton: true,
      body: FutureBuilder<User?>(
        future: FirebaseDataService().getUserById(widget.userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
              ),
            );
          }
          if (userSnapshot.hasError || !userSnapshot.hasData) {
            return Center(
              child: Text(
                'Error: ${userSnapshot.error}',
                style: TextStyle(
                  color: colorScheme.onSurface, // Light yellowish-orange in light mode, pale yellowish-cream in dark mode
                ),
              ),
            );
          }
          final user = userSnapshot.data!;
          _username ??= user.username;
          _interests ??= user.interests;
          _profilePicture ??= user.profilePicture;
          _usernameController.text = _username!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                          backgroundImage: _profilePicture != null && _profilePicture!.isNotEmpty
                              ? NetworkImage(_profilePicture!)
                              : null,
                          child: _profilePicture == null || _profilePicture!.isEmpty
                              ? Icon(
                            Icons.person,
                            size: 50,
                            color: colorScheme.onSurface,
                          )
                              : null,
                        ),
                        if (_isEditing)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (!_isEditing) {
                          _usernameController.text = _username!;
                          _interests = user.interests;
                          _profilePicture = user.profilePicture;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
                      foregroundColor: colorScheme.onPrimary, // White text/icon
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 3,
                    ),
                    child: Text(
                      _isEditing ? 'Cancelar' : 'Editar Perfil',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombre de usuario',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary, // Dark brown in light mode, muted dark brown in dark mode
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextFormField(
                        controller: _usernameController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu nombre de usuario',
                          hintStyle: TextStyle(color: colorScheme.onSecondary.withValues(alpha: 0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.secondary, // Muted mustard yellow in light mode, darker mustard yellow in dark mode
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.onSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.onSecondary.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.onSecondary,
                              width: 2,
                            ),
                          ),
                        ),
                        style: TextStyle(color: colorScheme.onSecondary),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre de usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Correo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Intereses',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: _availableInterests.map((interest) {
                          final isSelected = _interests!.contains(interest);
                          return FilterChip(
                            label: Text(
                              interest,
                              style: TextStyle(
                                color: isSelected ? colorScheme.onPrimary : colorScheme.onPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
                            backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
                            checkmarkColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: colorScheme.onPrimary.withValues(alpha: 0.5),
                              ),
                            ),
                            onSelected: _isEditing
                                ? (selected) {
                              setState(() {
                                if (selected) {
                                  _interests!.add(interest);
                                } else {
                                  _interests!.remove(interest);
                                }
                              });
                            }
                                : null,
                          );
                        }).toList(),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Guardar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mis Publicaciones',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Post>>(
                  future: FirebaseDataService().getPostsByUser(widget.userId),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                        ),
                      );
                    }
                    if (postSnapshot.hasError) {
                      return Text(
                        'Error: ${postSnapshot.error}',
                        style: TextStyle(color: colorScheme.onSecondary),
                      );
                    }
                    final posts = postSnapshot.data ?? [];
                    if (posts.isEmpty) {
                      return Text(
                        'No hay publicaciones',
                        style: TextStyle(color: colorScheme.onSecondary),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () => context.go('/post/${post.postId}'),
                          child: Card(
                            elevation: 2,
                            color: colorScheme.surface, // Cream in light mode, warm dark in dark mode
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.onSecondary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                post.imageUrl ?? 'https://via.placeholder.com/150',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.image,
                                  color: colorScheme.onPrimary,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}