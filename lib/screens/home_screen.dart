import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:bs/providers/main_view_model.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/widgets/post_card.dart';
import 'package:bs/widgets/event_card.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MainViewModel _viewModel;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define a stable child for Consumer
    const stableChild = SizedBox.shrink();
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        final posts = viewModel.posts;
        final events = viewModel.events;

        return viewModel.isLoading
            ? Center(
          child: Lottie.asset(
            'assets/icons/loading.json',
            width: 150,
            height: 150,
          ),
        )
            : viewModel.errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                viewModel.errorMessage!,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => viewModel.fetchData(widget.userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: () => viewModel.fetchData(widget.userId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (events.isEmpty && !viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No hay eventos disponibles',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                )
              else if (events.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: EventMiniCarousel(
                    miniCards: events
                        .map((event) => EventCardMini(
                      key: ValueKey('event_${event.eventId}'),
                      event: event,
                    ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Publicaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              if (posts.isEmpty && !viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No hay publicaciones disponibles',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ...posts.map(
                    (post) => PostCard(
                  key: ValueKey('post_${post.postId}'),
                  post: post,
                  currentUserId: widget.userId,
                  onLike: () async {
                    await FirebaseDataService()
                        .toggleLike(post.postId, widget.userId);
                    viewModel.fetchData(widget.userId);
                  },
                  onViewComments: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.go('/post/${post.postId}');
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
      child: stableChild,
    );
  }
}