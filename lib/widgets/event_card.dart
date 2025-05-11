import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import 'dart:developer' as developer;
import 'dart:async';

// Card grande (normal)
class EventCardNormal extends StatelessWidget {
  final Event event;

  const EventCardNormal({
    super.key,
    required this.event,
  });

  void _openGallery(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventId = event.eventId;
      context.push('/gallery/$eventId');
      developer.log('Navigating to /gallery/$eventId', name: 'EventCardNormal');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: event.imageUrl ?? '',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: 200,
                color: colorScheme.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: 200,
                color: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.event,
                  size: 60,
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.address ?? 'Ubicación desconocida',
                        style: TextStyle(
                          fontSize: 14, // Reduced font size to prevent overflow
                          color: colorScheme.secondary,
                        ),
                        overflow: TextOverflow.ellipsis, // Add ellipsis for long addresses
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.startTime,
                      style: TextStyle(
                        fontSize: 14, // Reduced font size to prevent overflow
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                      onPressed: () {
                        final shareLink = 'https://test-31f21.firebaseapp.com/gallery/${event.eventId}';
                        Share.share(
                          shareLink,
                          subject: '¡Mira las fotos del evento ${event.name}!',
                        );
                        developer.log('Sharing link: $shareLink', name: 'EventCardNormal');
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.photo_library,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      onPressed: () => _openGallery(context),
                      tooltip: 'Ver Galería',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card mini (para el carrusel)
class EventCardMini extends StatelessWidget {
  final Event event;

  const EventCardMini({
    super.key,
    required this.event,
  });

  void _openGallery(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventId = event.eventId;
      context.push('/gallery/$eventId');
      developer.log('Navigating to /gallery/$eventId', name: 'EventCardMini');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.push('/event/${event.eventId}');
          developer.log('Navigating to /event/${event.eventId}', name: 'EventCardMini');
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha:0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha:0.5),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.event,
                      size: 32,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.address ?? 'Sin ubicación',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.startTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.share,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          final shareLink = 'https://test-31f21.firebaseapp.com/gallery/${event.eventId}';
                          Share.share(
                            shareLink,
                            subject: '¡Mira las fotos del evento ${event.name}!',
                          );
                          developer.log('Sharing link: $shareLink', name: 'EventCardMini');
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.photo_library,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => _openGallery(context),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        tooltip: 'Ver Galería',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Carrusel de cards mini
class EventMiniCarousel extends StatefulWidget {
  final List<EventCardMini> miniCards;

  const EventMiniCarousel({super.key, required this.miniCards});

  @override
  _EventMiniCarouselState createState() => _EventMiniCarouselState();
}

class _EventMiniCarouselState extends State<EventMiniCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.miniCards.isEmpty) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.miniCards.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(EventMiniCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.miniCards != widget.miniCards) {
      _autoScrollTimer?.cancel();
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.miniCards.isEmpty) {
      return Container(
        height: 160,
        padding: const EdgeInsets.symmetric(vertical: 32),
        color: colorScheme.surface,
        child:  Center(
          child: Text('No hay eventos disponibles', style: TextStyle(color: colorScheme.secondary)),
        ),
      );
    }

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: colorScheme.surface,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.miniCards.length,
        itemBuilder: (context, index) {
          return widget.miniCards[index];
        },
      ),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}

