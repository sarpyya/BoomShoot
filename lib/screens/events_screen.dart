import 'package:flutter/material.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/event.dart';
import 'package:bs/models/user.dart';
import 'package:bs/providers/main_view_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

class EventsScreen extends StatefulWidget {
  final String userId;

  const EventsScreen({super.key, required this.userId});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final MainViewModel _viewModel;
  final Map<String, bool> _expandedDescriptions = {};
  LatLng? _currentLocation;
  late GoogleMapController _mapController;
  bool _showMapView = false;
  bool _isMapControllerInitialized = false;
  bool _isLoadingLocation = false; // Track loading state for location

  static const LatLng _defaultLocation = LatLng(-33.4489, -70.6693);
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: _defaultLocation,
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<MainViewModel>(context, listen: false);
    if (!_viewModel.isLoading && _viewModel.events.isEmpty) {
      _viewModel.fetchData(widget.userId);
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        if (_isMapControllerInitialized) {
          _mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 12));
        }
      });
    } catch (e) {
      developer.log('Error getting current location: $e', name: 'EventsScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<double> _calculateDistance(LatLng point1, LatLng point2) async {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  Future<List<Event>> _sortEventsByDistance(List<Event> events) async {
    if (_currentLocation == null) {
      return events; // Return unsorted events if location isn't available
    }

    List<Event> eventsWithLocation = events.where((event) {
      if (event.location == null) return false;
      final coords = event.location!.split(',');
      return coords.length == 2;
    }).toList();

    List<Event> eventsWithoutLocation = events.where((event) => event.location == null).toList();

    // Combine sorted events with location and events without location
    return [...eventsWithLocation, ...eventsWithoutLocation];
  }

  Future<Set<Marker>> _buildEventMarkers(List<Event> events) async {
    final Set<Marker> markers = {};

    for (final event in events) {
      if (event.location == null) continue;

      final coords = event.location!.split(',');
      if (coords.length != 2) continue;

      try {
        final lat = double.parse(coords[0]);
        final lng = double.parse(coords[1]);
        final latLng = LatLng(lat, lng);

        markers.add(
          Marker(
            markerId: MarkerId(event.eventId),
            position: latLng,
            infoWindow: InfoWindow(
              title: event.name,
              snippet: event.address ?? 'No address provided',
              onTap: () {
                _showEventDetailsBottomSheet(context, event);
              },
            ),
            onTap: () {
              _mapController.showMarkerInfoWindow(MarkerId(event.eventId));
            },
          ),
        );
      } catch (e) {
        developer.log('Error parsing location for event ${event.eventId}: $e', name: 'EventsScreen');
      }
    }

    return markers;
  }

  void _showEventDetailsBottomSheet(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.address ?? event.placeId ?? 'No address provided',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy, h:mm a').format(DateTime.parse(event.startTime)),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (event.description != null && event.description!.isNotEmpty) ...[
              Text(
                event.description!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
            FutureBuilder<User?>(
              future: FirebaseDataService().getUserById(event.creatorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final user = snapshot.data;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!)
                          : null,
                      child: user?.profilePicture == null
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?.username ?? 'Unknown Organizer',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 150,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Create Event'),
              onTap: () {
                Navigator.pop(context);
                context.go('/create_event');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Create Group'),
              onTap: () {
                Navigator.pop(context);
                context.go('/create_group');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Eventos'),
            actions: [
              IconButton(
                icon: Icon(_showMapView ? Icons.list : Icons.map),
                onPressed: () {
                  setState(() {
                    _showMapView = !_showMapView;
                  });
                },
                tooltip: _showMapView ? 'List View' : 'Map View',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showFabMenu(context),
            tooltip: 'Add Event or Group',
            child: const Icon(Icons.add),
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.errorMessage != null
              ? Center(child: Text(viewModel.errorMessage!))
              : _showMapView
              ? _buildMapView(viewModel.events)
              : _buildListView(viewModel.events),
        );
      },
    );
  }

  Widget _buildListView(List<Event> events) {
    return FutureBuilder<List<Event>>(
      future: _sortEventsByDistance(events),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sortedEvents = snapshot.data ?? events;

        return RefreshIndicator(
          onRefresh: () => _viewModel.fetchData(widget.userId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (sortedEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No hay eventos disponibles'),
                ),
              // Carrusel horizontal (máximo 10)
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedEvents.length > 10 ? 10 : sortedEvents.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final event = sortedEvents[index];
                    return SizedBox(
                      width: 300,
                      child: EventCard(
                        event: event,
                        isExpanded: _expandedDescriptions[event.eventId] ?? false,
                        onToggleExpand: () {
                          setState(() {
                            _expandedDescriptions[event.eventId] =
                            !(_expandedDescriptions[event.eventId] ?? false);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Lista vertical completa
              ...sortedEvents.map(
                    (event) => EventCard(
                  event: event,
                  isExpanded: _expandedDescriptions[event.eventId] ?? false,
                  onToggleExpand: () {
                    setState(() {
                      _expandedDescriptions[event.eventId] =
                      !(_expandedDescriptions[event.eventId] ?? false);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildMapView(List<Event> events) {
    return Stack(
      children: [
        FutureBuilder<Set<Marker>>(
          future: _buildEventMarkers(events),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final markers = snapshot.data ?? {};
            return GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _isMapControllerInitialized = true;
                if (_currentLocation != null) {
                  _mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 12));
                }
              },
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            );
          },
        ),
        if (_isLoadingLocation)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const EventCard({
    super.key,
    required this.event,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl ?? (event.photos.isNotEmpty ? event.photos.first : null);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            ClipOval(
              child: Image.network(
                imageUrl ?? 'https://via.placeholder.com/80',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.event, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenido flexible
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          event.address ?? event.placeId ?? 'No address provided',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy, h:mm a').format(DateTime.parse(event.startTime)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (event.interests.isNotEmpty) ...[
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: event.interests.map((interest) {
                        return Chip(
                          label: Text(interest, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                  ],

                  AnimatedCrossFade(
                    firstChild: Text(
                      event.description ?? 'No description available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    secondChild: Text(
                      event.description ?? 'No description available',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  if (event.description != null && event.description!.isNotEmpty)
                    TextButton(
                      onPressed: onToggleExpand,
                      child: Text(isExpanded ? 'See Less' : 'See More'),
                    ),

                  const SizedBox(height: 8),

                  FutureBuilder<User?>(
                    future: FirebaseDataService().getUserById(event.creatorId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final user = snapshot.data;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: user?.profilePicture != null
                                ? NetworkImage(user!.profilePicture!)
                                : null,
                            child: user?.profilePicture == null
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              user?.username ?? 'Unknown Organizer',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
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
class EventCarousel extends StatelessWidget {
  final List<Event> events;
  final Map<String, bool> expandedDescriptions;
  final Function(String) onToggleExpand;

  EventCarousel({
    required this.events,
    required this.expandedDescriptions,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final limitedEvents = events.length > 10 ? events.sublist(0, 10) : events;

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: limitedEvents.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = limitedEvents[index];
          return SizedBox(
            width: 300,
            child: EventCard(
              event: event,
              isExpanded: expandedDescriptions[event.eventId] ?? false,
              onToggleExpand: () => onToggleExpand(event.eventId),
            ),
          );
        },
      ),
    );
  }
}