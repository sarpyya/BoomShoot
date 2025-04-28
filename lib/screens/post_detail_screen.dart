import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/comment.dart';
import 'package:bs/models/post.dart';
import 'package:bs/models/user.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/event.dart';
import '../models/group.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final String userId;

  const PostDetailScreen({super.key, required this.postId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicación')),
      body: FutureBuilder<Post?>(
        future: FirebaseDataService()
            .getPostsByUser(userId)
            .then((posts) => posts.firstWhere((p) => p.postId == postId)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final post = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.createdAt != null
                      ? timeago.format(DateTime.parse(post.createdAt!))
                      : 'Unknown time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (post.imageUrl != null)
                  Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image),
                  ),
                if (post.groupId != null || post.eventId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        if (post.groupId != null)
                          FutureBuilder<Group?>(
                            future: FirebaseDataService()
                                .getUserGroups(userId)
                                .then((groups) => groups
                                .firstWhere((g) => g.groupId == post.groupId)),
                            builder: (context, snapshot) {
                              final group = snapshot.data;
                              return Text(
                                group != null
                                    ? 'Grupo: ${group.name}'
                                    : 'Grupo desconocido',
                                style: const TextStyle(
                                    fontSize: 14, fontStyle: FontStyle.italic),
                              );
                            },
                          ),
                        if (post.groupId != null && post.eventId != null)
                          const SizedBox(width: 16),
                        if (post.eventId != null)
                          FutureBuilder<Event?>(
                            future: FirebaseDataService()
                                .getEvents()
                                .then((events) => events
                                .firstWhere((e) => e.eventId == post.eventId)),
                            builder: (context, snapshot) {
                              final event = snapshot.data;
                              return Text(
                                event != null
                                    ? 'Evento: ${event.name}'
                                    : 'Evento desconocido',
                                style: const TextStyle(
                                    fontSize: 14, fontStyle: FontStyle.italic),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(post.content, style: const TextStyle(fontSize: 16)),
                ),
                Text('Likes: ${post.likesCount}'),
                const Divider(),
                FutureBuilder<List<Comment>>(
                  future: FirebaseDataService().getComments(postId),
                  builder: (context, commentSnapshot) {
                    if (commentSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final comments = commentSnapshot.data ?? [];
                    return Column(
                      children: comments
                          .map(
                            (comment) => ListTile(
                          title: FutureBuilder<User?>(
                            future: FirebaseDataService()
                                .getUserById(comment.userId),
                            builder: (context, userSnapshot) {
                              final user = userSnapshot.data;
                              return Text(user?.username ?? 'Unknown');
                            },
                          ),
                          subtitle: Text(comment.content),
                          trailing: Text(
                            comment.timestamp.isNotEmpty
                                ? timeago
                                .format(DateTime.parse(comment.timestamp))
                                : 'Unknown time',
                          ),
                        ),
                      )
                          .toList(),
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