import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lottie/lottie.dart';
import '../models/comment.dart';
import '../models/event.dart';
import '../models/group.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class PostCard extends StatefulWidget {
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
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  List<Comment> _comments = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await FirebaseDataService().getComments(widget.post.postId);
    if (mounted) {
      setState(() {
        _comments = comments;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El comentario no puede estar vacío',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    // Debounce submission
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        _isSubmitting = true;
      });

      try {
        final comment = Comment(
          commentId: '',
          postId: widget.post.postId,
          userId: widget.currentUserId,
          content: _commentController.text.trim(),
          timestamp: DateTime.now().toIso8601String(),
        );
        await FirebaseDataService().addComment(widget.post.postId, comment);
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Lottie.asset(
                  'assets/icons/success.json',
                  width: 24,
                  height: 24,
                  repeat: false,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comentario publicado',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        await _loadComments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al publicar el comentario: $e',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    });
  }

  void _sharePost() {
    final shareLink = 'https://boomshoot.app/post/${widget.post.postId}';
    Share.share(
      shareLink,
      subject: 'Mira este post en BoomShoot: ${widget.post.content}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha:0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha:0.5),
            blurRadius: 6,
            offset: const Offset(2, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            widget.post.createdAt != null
                ? timeago.format(DateTime.parse(widget.post.createdAt!))
                : 'Unknown time',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          // Image with Username Overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.post.imageUrl ?? 'https://via.placeholder.com/400',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Lottie.asset(
                          'assets/icons/loading.json',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: FutureBuilder<User?>(
                  future: FirebaseDataService().getUserById(widget.post.userId),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha:0.8),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha:0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        user?.username ?? 'Unknown',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Group/Event Info
          if (widget.post.groupId != null || widget.post.eventId != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (widget.post.groupId != null)
                    FutureBuilder<Group?>(
                      future: FirebaseDataService().getGroupById(widget.post.groupId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Lottie.asset(
                            'assets/icons/loading.json',
                            width: 20,
                            height: 20,
                          );
                        }
                        final group = snapshot.data;
                        return Text(
                          group != null ? 'Grupo: ${group.name}' : 'Grupo desconocido',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.secondary,
                          ),
                        );
                      },
                    ),
                  if (widget.post.groupId != null && widget.post.eventId != null)
                    const SizedBox(width: 12),
                  if (widget.post.eventId != null)
                    FutureBuilder<Event?>(
                      future: FirebaseDataService().getEventById(widget.post.eventId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Lottie.asset(
                            'assets/icons/loading.json',
                            width: 20,
                            height: 20,
                          );
                        }
                        final event = snapshot.data;
                        return Text(
                          event != null ? 'Evento: ${event.name}' : 'Evento desconocido',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.secondary,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          // Content
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.post.content,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Actions and Comments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      widget.post.likes.contains(widget.currentUserId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: widget.post.likes.contains(widget.currentUserId)
                          ? Colors.red
                          : colorScheme.secondary,
                    ),
                    onPressed: () async {
                      try {
                        await FirebaseDataService()
                            .toggleLike(widget.post.postId, widget.currentUserId);
                        widget.onLike();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error al dar me gusta: $e',
                              style: TextStyle(color: colorScheme.onError),
                            ),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      }
                    },
                  ),
                  Text(
                    '${widget.post.likesCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      size: 20,
                      color: colorScheme.secondary,
                    ),
                    onPressed: _sharePost,
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onViewComments,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${_comments.length} comentarios',
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Comments Preview
          if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No hay comentarios aún.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.secondary,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._comments.take(3).mapIndexed(
                      (index, comment) => Padding(
                    key: ValueKey('comment_${comment.commentId}'),
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FutureBuilder<User?>(
                      future: FirebaseDataService().getUserById(comment.userId),
                      builder: (context, userSnapshot) {
                        final user = userSnapshot.data;
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: user?.username ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const TextSpan(text: ': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              TextSpan(
                                text: comment.content,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.secondary,
                                ),
                              ),
                              TextSpan(
                                text: '  ${comment.timestamp.isNotEmpty
                                    ? timeago.format(DateTime.parse(comment.timestamp))
                                    : 'Unknown time'}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_comments.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: widget.onViewComments,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ver ${_comments.length - 3} comentarios más',
                        style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          // Comment Input Box
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _commentController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    hintStyle: TextStyle(
                        fontSize: 12,
                        color: colorScheme.outline),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.send,
                  size: 20,
                  color: _isSubmitting
                      ? colorScheme.outline
                      : colorScheme.primary,
                ),
                onPressed: _isSubmitting ? null : _submitComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

