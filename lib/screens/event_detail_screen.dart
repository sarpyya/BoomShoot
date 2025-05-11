import 'package:flutter/material.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/event.dart';
import 'package:bs/models/user.dart';
import 'package:bs/models/post.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:developer' as developer;

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final FirebaseDataService _dataService = FirebaseDataService();
  Event? _event;
  User? _creator;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<Marker> _markers = {};
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _fetchEventData();
    // Start auto-play after photos are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_event?.photos.isNotEmpty ?? false) {
        _startAutoPlay();
      }
    });
  }

  Future<void> _fetchEventData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch event
      final event = await _dataService.getEventById(widget.eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      // Fetch creator
      final creator = await _dataService.getUserById(event.creatorId);

      // Fetch posts
      final allPosts = await _dataService.getPosts();
      final eventPosts = allPosts.where((post) => post.eventId == event.eventId).toList();

      // Create marker if location is available
      if (event.location != null) {
        final coords = event.location!.split(',');
        if (coords.length == 2) {
          try {
            final lat = double.parse(coords[0]);
            final lng = double.parse(coords[1]);
            _markers.add(
              Marker(
                markerId: MarkerId(event.eventId),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: event.name,
                  snippet: event.address ?? 'Sin dirección proporcionada',
                ),
              ),
            );
          } catch (e) {
            developer.log('Error parsing event location: $e', name: 'EventDetailScreen');
          }
        }
      }

      setState(() {
        _event = event;
        _creator = creator;
        _posts = eventPosts;
        _isLoading = false;
      });

      // Start auto-play if photos are available
      if (event.photos.isNotEmpty) {
        _startAutoPlay();
      }
    } catch (e) {
      developer.log('Error fetching event data: $e', name: 'EventDetailScreen');
      setState(() {
        _errorMessage = 'Error al cargar el evento: $e';
        _isLoading = false;
      });
    }
  }

  void _startAutoPlay() {
    if (_event!.photos.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted && _pageController.hasClients) {
          setState(() {
            _currentPage = (_currentPage + 1) % _event!.photos.length;
          });
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_event?.name ?? 'Detalles del Evento'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: TextStyle(color: colorScheme.error)))
          : _event == null
          ? const Center(child: Text('Evento no encontrado'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image or Photos Carousel
            if (_event!.photos.isNotEmpty)
              Container(
                height: 140, // Match EventMiniCarousel height
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: colorScheme.surface.withValues(alpha: 0.5), // Match EventMiniCarousel
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _event!.photos.length,
                  itemBuilder: (context, index) {
                    final photoUrl = _event!.photos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: colorScheme.onSurface.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.image,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (_event!.imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _event!.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      width: double.infinity,
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.image,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event!.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_event!.description != null)
                    Text(
                      _event!.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.parse(_event!.startTime))} - ${DateFormat('h:mm a').format(DateTime.parse(_event!.endTime))}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_event!.address != null)
                    Row(
                      children: [
                        Icon(Icons.location_on, color: colorScheme.secondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _event!.address!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
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
                    'Participantes: ${_event!.participants.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (_event!.interests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: _event!.interests.map((interest) {
                        return Chip(
                          label: Text(interest),
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          labelStyle: TextStyle(color: colorScheme.onSurface),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Map Section (if location is available)
            if (_event!.location != null && _markers.isNotEmpty)
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _markers.first.position,
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            // Posts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Publicaciones Relacionadas',
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