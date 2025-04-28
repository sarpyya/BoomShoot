import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bs/providers/main_view_model.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/widgets/post_card.dart';
import 'package:bs/widgets/radial_menu.dart';
import 'package:bs/widgets/event_card.dart';

import '../main.dart';
import '../widgets/custom_scaffold.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MainViewModel _viewModel;
  final Map<String, bool> _expandedDescriptions = {};

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<MainViewModel>(context, listen: false);
    if (!_viewModel.isLoading && _viewModel.posts.isEmpty && _viewModel.events.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.fetchData(widget.userId);
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      Provider.of<AuthProvider>(context, listen: false).signOut();
      Provider.of<MainViewModel>(context, listen: false).reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cerrar sesión: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        );
      }
    }
  }

  void _showRadialMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(50),
      builder: (context) => RadialMenu(userId: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        var posts = viewModel.posts;
        var events = viewModel.events;

        return CustomScaffold(
          showMenuButton: true,
          onMenuPressed: () => _showRadialMenu(context),
          showLogo: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: viewModel.isLoading ? null : _signOut,
              tooltip: 'Cerrar sesión',
            ),
          ],
          body: viewModel.isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          )
              : viewModel.errorMessage != null
              ? Center(
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          )
              : RefreshIndicator(
            onRefresh: () => viewModel.fetchData(widget.userId),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (events.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: EventMiniCarousel(
                              miniCards: events
                                  .map((event) =>
                                  EventCardMini(event: event))
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Publicaciones',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (posts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No hay publicaciones disponibles',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ...posts.map(
                              (post) => PostCard(
                            post: post,
                            currentUserId: widget.userId,
                            onLike: () async {
                              await FirebaseDataService()
                                  .toggleLike(post.postId, widget.userId);
                              viewModel.fetchData(widget.userId);
                            },
                            onViewComments: () =>
                                context.go('/post/${post.postId}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}