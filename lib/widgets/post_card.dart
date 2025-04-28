import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/comment.dart';
import '../models/event.dart';
import '../models/group.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onViewComments;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onViewComments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.secondary.withOpacity(0.3)), // Subtle border with secondary color
      ),
      color: colorScheme.surface, // Cream in light mode, warm dark in dark mode
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              post.createdAt != null ? timeago.format(DateTime.parse(post.createdAt!)) : 'Unknown time',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSecondary, // Black in light mode, light grayish-cream in dark mode
              ),
            ),
          ),
          // Image with Username Overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.imageUrl ?? 'https://via.placeholder.com/400',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.secondary.withOpacity(0.2), // Fallback color with secondary tint
                    child: Icon(
                      Icons.image,
                      size: 50,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: FutureBuilder<User?>(
                  future: FirebaseDataService().getUserById(post.userId),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user?.username ?? 'Unknown',
                        style: TextStyle(
                          color: colorScheme.onPrimary, // White in both modes
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Group/Event Info
          if (post.groupId != null || post.eventId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (post.groupId != null)
                    FutureBuilder<List<Group>>(
                      future: FirebaseDataService().getUserGroups(currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(
                            color: colorScheme.primary,
                          );
                        }
                        final groups = snapshot.data ?? [];
                        final group = groups.firstWhereOrNull((g) => g.groupId == post.groupId);
                        return Text(
                          group != null ? 'Grupo: ${group.name}' : 'Grupo desconocido',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSecondary,
                          ),
                        );
                      },
                    ),
                  if (post.groupId != null && post.eventId != null) const SizedBox(width: 16),
                  if (post.eventId != null)
                    FutureBuilder<List<Event>>(
                      future: FirebaseDataService().getEvents(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(
                            color: colorScheme.primary,
                          );
                        }
                        final events = snapshot.data ?? [];
                        final event = events.firstWhereOrNull((e) => e.eventId == post.eventId);
                        return Text(
                          event != null ? 'Evento: ${event.name}' : 'Evento desconocido',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSecondary,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              post.content,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSecondary,
              ),
            ),
          ),
          // Actions and Comments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.likes.contains(currentUserId) ? Icons.favorite : Icons.favorite_border,
                        color: post.likes.contains(currentUserId)
                            ? Colors.red
                            : colorScheme.onSurface,
                      ),
                      onPressed: onLike,
                    ),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        color: colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Share not implemented',
                              style: TextStyle(color: colorScheme.onSecondary),
                            ),
                            backgroundColor: colorScheme.surface,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onViewComments,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
                  ),
                  child: Text(
                    'View Comments',
                    style: TextStyle(
                      color: colorScheme.onPrimary, // White in both modes
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Comments Preview
          FutureBuilder<List<Comment>>(
            future: FirebaseDataService().getComments(post.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                );
              }
              final comments = snapshot.data ?? [];
              final previewComments = comments.take(3).toList();
              return Column(
                children: [
                  ...previewComments.map(
                        (comment) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: FutureBuilder<User?>(
                        future: FirebaseDataService().getUserById(comment.userId),
                        builder: (context, userSnapshot) {
                          final user = userSnapshot.data;
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${user?.username ?? 'Unknown'}: ${comment.content}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                comment.timestamp.isNotEmpty
                                    ? timeago.format(DateTime.parse(comment.timestamp))
                                    : 'Unknown time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSecondary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (comments.length > 3)
                    TextButton(
                      onPressed: onViewComments,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                      child: Text(
                        'View ${comments.length - 3} more comments',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}