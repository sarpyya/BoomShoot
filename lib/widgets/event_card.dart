import 'package:flutter/material.dart';

import '../models/event.dart';

// Card grande (normal)
class EventCardNormal extends StatelessWidget {
  final Event event;

  const EventCardNormal({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.secondary.withValues(alpha: 0.3), // Border with secondary color
          width: 1,
        ),
      ),
      elevation: 4,
      color: colorScheme.surface, // Use surface color for card background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              event.imageUrl ?? '',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 180,
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                child: Icon(
                  Icons.event,
                  size: 50,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // Use primary color for event name
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.secondary, // Use secondary color for icons
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.address ?? 'Unknown location',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface, // Use onSurface for text
                        ),
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
                      color: colorScheme.secondary, // Use secondary color for icons
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.startTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface, // Use onSurface for text
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.onSurface, // Use surface color for background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3), // Border with secondary color
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
            backgroundImage: event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? NetworkImage(event.imageUrl!)
                : null,
            child: event.imageUrl == null || event.imageUrl!.isEmpty
                ? Icon(
              Icons.event,
              size: 32,
              color: colorScheme.onSurface,
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary, // Use primary color for event name
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: colorScheme.onSecondary, // Use secondary color for icons
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.address ?? 'Unknown location',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSecondary, // Use onSurface for text
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colorScheme.onSecondary, // Use secondary color for icons
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.startTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondary, // Use onSurface for text
                      ),
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

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    if (_pageController.hasClients) {
      _currentPage++;
      if (_currentPage >= widget.miniCards.length) _currentPage = 0;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 120, // Increased height to accommodate padding
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: colorScheme.surface.withValues(alpha: 0.5), // Subtle background for the carousel
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
    _pageController.dispose();
    super.dispose();
  }
}