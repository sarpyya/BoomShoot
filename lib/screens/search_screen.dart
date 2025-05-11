import 'package:flutter/material.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/user.dart';
import 'package:bs/models/group.dart';
import 'package:bs/models/event.dart';
import 'package:bs/models/comment.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class SearchScreen extends StatefulWidget {
  final String userId;

  const SearchScreen({super.key, required this.userId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseDataService _dataService = FirebaseDataService();
  String _searchQuery = '';
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  List<User> _userResults = [];
  List<Group> _groupResults = [];
  List<Event> _eventResults = [];
  List<Comment> _commentResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _dataService.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    } else {
      setState(() {
        _userResults = [];
        _groupResults = [];
        _eventResults = [];
        _commentResults = [];
      });
    }
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
      });
    } catch (e) {
      developer.log('Error getting current location: $e', name: 'SearchScreen');
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
            developer.log('Error parsing location for event ${event.eventId}: $e', name: 'SearchScreen');
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

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _dataService.searchUsers(_searchQuery);
      final groups = await _dataService.searchGroups(_searchQuery);
      final events = await _dataService.searchEvents(_searchQuery);
      final sortedEvents = await _sortEventsByDistance(events);
      final comments = await _dataService.searchComments(_searchQuery);

      setState(() {
        _userResults = users;
        _groupResults = groups;
        _eventResults = sortedEvents;
        _commentResults = comments;
      });
    } catch (e) {
      developer.log('Error performing search: $e', name: 'SearchScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildUserTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
        child: user.profilePicture == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.username),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.visibility['allowFollow'] ?? true)
            FutureBuilder<bool>(
              future: _dataService.hasRelationship(
                sourceUserId: widget.userId,
                targetUserId: user.userId,
                type: 'follow',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                }
                final isFollowing = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
                  onPressed: () async {
                    try {
                      await _dataService.toggleFollow(widget.userId, user.userId);
                      setState(() {}); // Refresh UI
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                );
              },
            ),
          if (user.visibility['allowFriendRequest'] ?? true)
            FutureBuilder<bool>(
              future: _dataService.hasRelationship(
                sourceUserId: widget.userId,
                targetUserId: user.userId,
                type: 'friend_request',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                }
                final hasSentRequest = snapshot.data ?? false;
                return IconButton(
                  icon: const Icon(Icons.group_add),
                  onPressed: hasSentRequest
                      ? null
                      : () async {
                    try {
                      await _dataService.sendFriendRequest(widget.userId, user.userId);
                      setState(() {}); // Refresh UI
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                );
              },
            ),
          if (user.visibility['allowMessages'] ?? true)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                context.go('/messages/${user.userId}');
              },
            ),
        ],
      ),
      onTap: () {
        context.go('/profile/${user.userId}');
      },
    );
  }

  Widget _buildGroupTile(Group group) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: group.imageUrl != null ? NetworkImage(group.imageUrl!) : null,
        child: group.imageUrl == null ? const Icon(Icons.group) : null,
      ),
      title: Text(group.name),
      subtitle: FutureBuilder<List<String>>(
        future: _dataService.getUserFriends(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading...');
          }
          final friends = snapshot.data ?? [];
          final friendCount = group.memberIds.where((id) => friends.contains(id)).length;
          final memberText = '${group.memberIds.length} miembros';
          final friendText = friendCount > 0 ? ' ($friendCount amigos)' : '';
          return Text('$memberText$friendText');
        },
      ),
      onTap: () {
        context.go('/group/${group.groupId}');
      },
    );
  }

  Widget _buildEventTile(Event event) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: event.imageUrl != null ? NetworkImage(event.imageUrl!) : null,
        child: event.imageUrl == null ? const Icon(Icons.event) : null,
      ),
      title: Text(event.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.address ?? 'No address provided'),
          Text(
            DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(event.startTime)),
            style: const TextStyle(color: Colors.grey),
          ),
          if (_currentLocation != null && event.location != null)
            FutureBuilder<double>(
              future: () async {
                final coords = event.location!.split(',');
                if (coords.length == 2) {
                  final lat = double.parse(coords[0]);
                  final lng = double.parse(coords[1]);
                  return await _calculateDistance(_currentLocation!, LatLng(lat, lng));
                }
                return double.infinity;
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Calculating distance...');
                }
                final distance = snapshot.data ?? double.infinity;
                return Text(
                  distance.isFinite ? '${(distance / 1000).toStringAsFixed(1)} km away' : 'Distance unavailable',
                  style: const TextStyle(color: Colors.grey),
                );
              },
            ),
        ],
      ),
      onTap: () {
        context.go('/event/${event.eventId}');
      },
    );
  }

  Widget _buildCommentTile(Comment comment) {
    return ListTile(
      leading: const Icon(Icons.comment),
      title: Text(comment.content, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: FutureBuilder<User?>(
        future: _dataService.getUserById(comment.userId),
        builder: (context, snapshot) {
          return Text(snapshot.data?.username ?? 'Unknown user');
        },
      ),
      onTap: () {
        context.go('/post/${comment.postId}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users, groups, events...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Groups'),
              Tab(text: 'Events'),
              Tab(text: 'Comments'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _userResults.isEmpty && _searchQuery.isNotEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: _userResults.length,
              itemBuilder: (context, index) => _buildUserTile(_userResults[index]),
            ),
            _groupResults.isEmpty && _searchQuery.isNotEmpty
                ? const Center(child: Text('No groups found'))
                : ListView.builder(
              itemCount: _groupResults.length,
              itemBuilder: (context, index) => _buildGroupTile(_groupResults[index]),
            ),
            _eventResults.isEmpty && _searchQuery.isNotEmpty
                ? const Center(child: Text('No events found'))
                : ListView.builder(
              itemCount: _eventResults.length,
              itemBuilder: (context, index) => _buildEventTile(_eventResults[index]),
            ),
            _commentResults.isEmpty && _searchQuery.isNotEmpty
                ? const Center(child: Text('No comments found'))
                : ListView.builder(
              itemCount: _commentResults.length,
              itemBuilder: (context, index) => _buildCommentTile(_commentResults[index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventWithDistance {
  final Event event;
  final double distance;

  _EventWithDistance({required this.event, required this.distance});
}