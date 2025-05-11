import 'package:flutter/material.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/group.dart';
import 'package:bs/models/post.dart';
import 'package:bs/models/user.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'dart:developer' as developer;
import 'package:bs/main.dart';

import '../photo_sharing_app_initializer.dart';
import '../providers/auth_provider.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final FirebaseDataService _dataService = FirebaseDataService();
  Group? _group;
  List<Post> _posts = [];
  User? _creator;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch group
      final group = await _dataService.getGroupById(widget.groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Fetch creator
      final creator = await _dataService.getUserById(group.creatorId);

      // Fetch posts
      final allPosts = await _dataService.getPosts();
      final groupPosts = allPosts.where((post) => group.postIds.contains(post.postId)).toList();

      setState(() {
        _group = group;
        _creator = creator;
        _posts = groupPosts;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching group data: $e', name: 'GroupDetailScreen');
      setState(() {
        _errorMessage = 'Error loading group: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup(String userId) async {
    try {
      await _dataService.joinGroup(widget.groupId, userId);
      setState(() {
        _group = _group!.copyWith(
          memberIds: [..._group!.memberIds, userId],
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unido al grupo exitosamente')),
      );
    } catch (e) {
      developer.log('Error joining group: $e', name: 'GroupDetailScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al unirse al grupo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = context.watch<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_group?.name ?? 'Detalles del Grupo'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: TextStyle(color: colorScheme.error)))
          : _group == null
          ? const Center(child: Text('Grupo no encontrado'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Image
            if (_group!.imageUrl != null)
              Image.network(
                _group!.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: colorScheme.surface,
                  child: Icon(Icons.error, color: colorScheme.error),
                ),
              ),
            // Group Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _group!.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _group!.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, color: colorScheme.secondary),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          if (_creator != null) {
                            context.push('/profile?userId=${_creator!.userId}');
                          }
                        },
                        child: Text(
                          _creator?.username ?? 'Creador Desconocido',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Miembros: ${_group!.memberIds.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (userId != null)
                    ElevatedButton(
                      onPressed: _group!.memberIds.contains(userId)
                          ? null
                          : () => _joinGroup(userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        disabledBackgroundColor: colorScheme.surface,
                      ),
                      child: Text(
                        _group!.memberIds.contains(userId)
                            ? 'Ya estás en el grupo'
                            : 'Unirse al Grupo',
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text('Inicia sesión para unirte'),
                    ),
                ],
              ),
            ),
            // Posts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Publicaciones del Grupo',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _posts.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No hay publicaciones disponibles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: post.imageUrl != null
                        ? NetworkImage(post.imageUrl!)
                        : null,
                    child: post.imageUrl == null
                        ? Icon(Icons.image, color: colorScheme.secondary)
                        : null,
                  ),
                  title: Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    context.push('/post/${post.postId}');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}