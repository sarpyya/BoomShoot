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
  bool _isMapControllerInitialized = false;
  bool _isLoadingLocation = false;

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
      return events;
    }

    final eventsWithDistance = <_EventWithDistance>[];
    final eventsWithoutLocation = <Event>[];

    for (final event in events) {
      if (event.location == null) {
        eventsWithoutLocation.add(event);
      } else {
        final coords = event.location!.split(',');
        if (coords.length == 2) {
          try {
            final lat = double.parse(coords[0]);
            final lng = double.parse(coords[1]);
            final eventLatLng = LatLng(lat, lng);
            final distance = await _calculateDistance(_currentLocation!, eventLatLng);
            eventsWithDistance.add(_EventWithDistance(event: event, distance: distance));
          } catch (e) {
            developer.log('Error parsing location for event ${event.eventId}: $e', name: 'EventsScreen');
            eventsWithoutLocation.add(event);
          }
        } else {
          eventsWithoutLocation.add(event);
        }
      }
    }

    eventsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return [...eventsWithDistance.map((e) => e.event), ...eventsWithoutLocation];
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
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
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
                  DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(event.startTime)),
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNearbyEventsDialog(List<Event> nearbyEvents) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eventos Cercanos'),
          content: SizedBox(
            width: double.maxFinite,
            child: nearbyEvents.isEmpty
                ? const Text('No hay eventos cercanos.')
                : ListView.builder(
              shrinkWrap: true,
              itemCount: nearbyEvents.length,
              itemBuilder: (context, index) {
                final event = nearbyEvents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: event.imageUrl != null ? NetworkImage(event.imageUrl!) : null,
                      child: event.imageUrl == null ? const Icon(Icons.event) : null,
                    ),
                    title: Text(event.name),
                    subtitle: Text(event.address ?? 'Sin dirección'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEventDetailsBottomSheet(context, event);
                    },
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
              title: const Text('Crear Evento'),
              onTap: () {
                Navigator.pop(context);
                context.go('/create_event');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Crear Grupo'),
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
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showFabMenu(context),
            tooltip: 'Añadir Evento o Grupo',
            child: const Icon(Icons.add),
          ),
          body: RefreshIndicator(
            onRefresh: () => _viewModel.fetchData(widget.userId),
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.errorMessage != null
                ? Center(child: Text(viewModel.errorMessage!))
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
                    child: Text(
                      'Eventos Destacados',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: viewModel.events.isEmpty
                        ? const Center(child: Text('No hay eventos para mostrar.'))
                        : EventCarousel(
                      events: viewModel.events.take(10).toList(), // Mostrar hasta 10 eventos en el carrusel
                      onEventTap: (event) => _showEventDetailsBottomSheet(context, event),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Mapa de Eventos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          FutureBuilder<Set<Marker>>(
                            future: _buildEventMarkers(viewModel.events),
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final sortedEvents = await _sortEventsByDistance(viewModel.events);
                        _showNearbyEventsDialog(sortedEvents);
                      },
                      icon: const Icon(Icons.near_me),
                      label: const Text('Mostrar Eventos Cercanos'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EventCarousel extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEventTap;

  const EventCarousel({super.key, required this.events, required this.onEventTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
    scrollDirection: Axis.horizontal,
    itemCount: events.length,
    separatorBuilder: (context, index) => const SizedBox(width: 12),
    itemBuilder: (context, index) {
    final event = events[index];
    final imageUrl = event.imageUrl ?? (event.photos.isNotEmpty ? event.photos.first : null);
    return GestureDetector(
    onTap: () => onEventTap(event),
    child: SizedBox(
    width: 200,
    child: Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Expanded(
    child: ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
    child: Image.network(
    imageUrl ?? 'https://via.placeholder.com/200x120',
    width: double.infinity,
    height: 120,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Container(
    color: Colors.grey[300],
    child: const Icon(Icons.event, size: 40),
    ),
    ),
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event.address ?? 'Sin dirección',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, y').format(DateTime.parse(event.startTime)),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
    ),
    ],
    ),
    ),
    ),
    );
    },
    );
  }
}

class _EventWithDistance {
  final Event event;
  final double distance;

  _EventWithDistance({required this.event, required this.distance});
}