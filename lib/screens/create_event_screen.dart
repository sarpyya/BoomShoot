import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/event.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

import '../services/place_service.dart';

class CreateEventScreen extends StatefulWidget {
  final String userId;

  const CreateEventScreen({super.key, required this.userId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  String? _imageUrl;
  LatLng? _selectedLocation;
  String? _geocodedAddress;
  bool _isLoading = false;
  bool _isGeocoding = false;
  bool _isFetchingSuggestions = false;
  final List<String> _selectedInterests = [];
  late GoogleMapController _mapController;
  bool _isMapControllerInitialized = false;
  bool _isMapReady = false;

  // Autocomplete-related variables
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isShowingSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _addressFocusNode = FocusNode();
  Timer? _debounce;

  final FirebaseDataService _dataService = FirebaseDataService();
  final ImagePicker _picker = ImagePicker();
  final Map<LatLng, String> _addressCache = {};

  // Default location: Santiago, Chile
  static const LatLng _defaultLocation = LatLng(-33.4489, -70.6693);
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: _defaultLocation,
    zoom: 12,
  );
  late final PlacesService _placesService;

  // Available interests
  final List<String> _availableInterests = [
    "Music",
    "Sports",
    "Art",
    "Technology",
    "Food",
    "Travel",
    "Photography",
    "Gaming",
    "Fashion",
    "Fitness",
    "Literature",
    "Nature"
  ];

  // Google Maps API key loaded from .env
  static final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _placesService = PlacesService(apiKey: googleMapsApiKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    });

    _addressController.addListener(_onAddressChanged);
    _addressFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    developer.log('Disposing CreateEventScreen', name: 'CreateEventScreen');
    _debounce?.cancel();
    _placesService.dispose();
    _dataService.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _addressFocusNode.removeListener(_onFocusChanged);
    _addressFocusNode.dispose();
    _hideSuggestions();
    if (_isMapControllerInitialized) {
      _mapController.dispose();
    }
    super.dispose();
  }

  void _onPopInvokedWithResult(bool didPop, dynamic result) {
    developer.log(
        'Pop invoked, cargando: $_isLoading, fetching: $_isFetchingSuggestions, geocoding: $_isGeocoding',
        name: 'CreateEventScreen');
    if (didPop) return;
    if (_isLoading || _isFetchingSuggestions || _isGeocoding) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'espera...',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _onFocusChanged() {
    developer.log(
        'Address field focus: ${_addressFocusNode.hasFocus}, suggestions: ${_addressSuggestions.length}',
        name: 'CreateEventScreen');
    if (_addressFocusNode.hasFocus && _addressSuggestions.isNotEmpty) {
      _showSuggestions();
    } else {
      _hideSuggestions();
    }
  }

  String _lastQuery = '';
  Future<void> _onAddressChanged() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _addressSuggestions = [];
          _isShowingSuggestions = false;
          _isFetchingSuggestions = false;
        });
      }
      _hideSuggestions();
      _lastQuery = '';
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        _isFetchingSuggestions = true;
      });

      if (query == _lastQuery) {
        if (mounted) {
          setState(() {
            _isFetchingSuggestions = false;
          });
        }
        return;
      }

      final suggestions = await _placesService.fetchSuggestions(query);

      if (mounted) {
        setState(() {
          _addressSuggestions = suggestions;
          _isShowingSuggestions = _addressSuggestions.isNotEmpty;
          _isFetchingSuggestions = false;
        });
      }

      _lastQuery = query;

      if (_addressFocusNode.hasFocus && _isShowingSuggestions) {
        _showSuggestions();
      } else {
        _hideSuggestions();
      }
    });
  }

  void _showSuggestions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    _hideSuggestions();
    if (_addressSuggestions.isEmpty || !_isShowingSuggestions) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.surface, // Cream in light mode, warm dark in dark mode
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _addressSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _addressSuggestions[index];
                  return ListTile(
                    tileColor: colorScheme.secondary,
                    title: Text(
                      suggestion['escribe tu direccion..'],
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onPrimary, // Light yellowish-orange in light mode, pale yellowish-cream in dark mode
                      ),
                    ),
                    onTap: () async {
                      _addressController.text = suggestion['Describe tu evento...'];
                      _addressController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _addressController.text.length),
                      );
                      if (mounted) {
                        setState(() {
                          _addressSuggestions = [];
                          _isShowingSuggestions = false;
                        });
                      }
                      _hideSuggestions();
                      await _updateLocationFromAddress(suggestion['place_id']);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    developer.log('Hiding suggestions, overlay: $_overlayEntry',
        name: 'CreateEventScreen');
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _updateLocationFromAddress(String placeId) async {
    try {
      if (googleMapsApiKey.isEmpty) {
        throw Exception(
            'Google Maps API key is not configured. Please set GOOGLE_MAPS_API_KEY in the .env file and ensure dotenv.load() is called in main.dart.');
      }

      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapsApiKey&fields=geometry';
      developer.log('Fetching place details for place_id: $placeId',
          name: 'CreateEventScreen');

      final response = await http.get(Uri.parse(url));
      developer.log('Place Details response status: ${response.statusCode}',
          name: 'CreateEventScreen');
      developer.log('Place Details response body: ${response.body}',
          name: 'CreateEventScreen');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final latLng = LatLng(location['lat'], location['lng']);
          if (mounted) {
            setState(() {
              _selectedLocation = latLng;
              _addressCache[latLng] = _addressController.text;
            });
          }
          if (_isMapControllerInitialized) {
            _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
          }
        } else {
          developer.log('Place Details failed: ${data['status']}',
              name: 'CreateEventScreen');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error fetching location: ${data['status']}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        }
      } else {
        developer.log(
            'Place Details request failed: ${response.statusCode} - ${response.body}',
            name: 'CreateEventScreen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error fetching location: ${response.statusCode}',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error fetching place details: $e', name: 'CreateEventScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching location: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Theme(
          data: theme.copyWith(
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
              onPrimary: colorScheme.onSurface, // White in both modes
              surface: colorScheme.secondary, // Cream in light mode, warm dark in dark mode
              onSurface: colorScheme.onPrimary, // Light yellowish-orange in light mode, pale yellowish-cream in dark mode
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return Theme(
            data: theme.copyWith(
              colorScheme: colorScheme.copyWith(
                primary: colorScheme.primary,
                onPrimary: colorScheme.onSurface,
                surface: colorScheme.secondary,
                onSurface: colorScheme.onPrimary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (mounted) {
          setState(() {
            if (isStart) {
              _startTime = selectedDateTime;
              if (_endTime != null && _endTime!.isBefore(_startTime!)) {
                _endTime = null;
              }
            } else {
              if (_startTime != null && selectedDateTime.isBefore(_startTime!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'El final debe ser posterior al inicio',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                );
                return;
              }
              _endTime = selectedDateTime;
            }
          });
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
        final imageUrl = await _dataService.uploadPhoto(pickedFile.path, widget.userId);
        if (mounted) {
          setState(() {
            _imageUrl = imageUrl;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error uploading image: $e', name: 'CreateEventScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error uploading image: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
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

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
          if (_isMapControllerInitialized) {
            _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
          }
        });
      }

      await _updateAddressFromLatLng(latLng);
    } catch (e) {
      developer.log('Error getting current location: $e', name: 'CreateEventScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting location: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAddressFromLatLng(LatLng latLng) async {
    if (_addressCache.containsKey(latLng)) {
      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
          _geocodedAddress = _addressCache[latLng]!;
          _addressController.text = _geocodedAddress!;
          _isGeocoding = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isGeocoding = true;
      });
    }

    try {
      if (googleMapsApiKey.isEmpty) {
        throw Exception(
            'Google Maps API key is not configured. Please set GOOGLE_MAPS_API_KEY in the .env file and ensure dotenv.load() is called in main.dart.');
      }

      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$googleMapsApiKey';
      developer.log('Attempting reverse geocoding with URL: $url (API key redacted)',
          name: 'CreateEventScreen');

      final response = await http.get(Uri.parse(url));
      developer.log('HTTP response status: ${response.statusCode}',
          name: 'CreateEventScreen');
      developer.log('HTTP response body: ${response.body}', name: 'CreateEventScreen');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('HTTP response data: $data', name: 'CreateEventScreen');

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final address = result['formatted_address'] as String;

          _addressCache[latLng] = address;

          if (mounted) {
            setState(() {
              _selectedLocation = latLng;
              _geocodedAddress = address;
              _addressController.text = address;
              _isGeocoding = false;
            });
          }
          developer.log('Successfully reverse geocoded: $address',
              name: 'CreateEventScreen');
          return;
        } else {
          developer.log('Reverse geocoding failed: ${data['status']}',
              name: 'CreateEventScreen');
          throw Exception('Reverse geocoding failed: ${data['status']}');
        }
      } else {
        developer.log(
            'HTTP request failed: ${response.statusCode} - ${response.body}',
            name: 'CreateEventScreen');
        throw Exception('HTTP request failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error reverse geocoding: $e', name: 'CreateEventScreen');

      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
          _geocodedAddress = 'Ubicación no disponible';
          _addressController.text = _geocodedAddress!;
          _isGeocoding = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error resolviendo dirección: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor seleccione una fecha y hora',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor seleccione una ubicación',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor seleccione al menos un interés',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final event = Event(
        eventId: '',
        name: _nameController.text,
        creatorId: widget.userId,
        startTime: _startTime!.toUtc().toIso8601String(),
        endTime: _endTime!.toUtc().toIso8601String(),
        participants: [],
        createdAt: DateTime.now().toUtc().toIso8601String(),
        placeId: null,
        photos: [],
        imageUrl: _imageUrl,
        address: _addressController.text,
        location: '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        interests: _selectedInterests,
        visibility: 'public',
      );

      await _dataService.createEvent(event);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Evento creado exitosamente',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      developer.log('Error creando evento: $e', name: 'CreateEventScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creando evento: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: Scaffold(
        backgroundColor: colorScheme.surface, // Cream in light mode, warm dark in dark mode
        appBar: AppBar(
          backgroundColor: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
          foregroundColor: colorScheme.onPrimary, // White in both modes
          title: Text(
            'Crea tu evento!',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del evento',
                    labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorScheme.onPrimary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: colorScheme.onPrimary),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Interéses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondary, // Dark brown in light mode, muted dark brown in dark mode
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(
                        interest,
                        style: TextStyle(
                          color: isSelected ? colorScheme.onSurface : colorScheme.onPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary, // Dark brown in light mode, muted dark brown in dark mode
                      backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
                      checkmarkColor: colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: TextFormField(
                        controller: _addressController,
                        focusNode: _addressFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Ubicación',
                          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          suffixIcon: _isFetchingSuggestions
                              ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          )
                              : null,
                        ),
                        style: TextStyle(color: colorScheme.onPrimary),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor seleccione una ubicación';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_isGeocoding)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: _isMapReady
                      ? GoogleMap(
                    initialCameraPosition: _initialCameraPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _isMapControllerInitialized = true;
                      if (_selectedLocation != null) {
                        _mapController.animateCamera(
                            CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
                      }
                    },
                    onTap: (LatLng latLng) async {
                      _hideSuggestions();
                      if (mounted) {
                        setState(() {
                          _selectedLocation = latLng;
                          _addressSuggestions = [];
                          _isShowingSuggestions = false;
                        });
                      }
                      _addressFocusNode.unfocus();
                      await _updateAddressFromLatLng(latLng);
                    },
                    markers: _selectedLocation != null
                        ? {
                      Marker(
                        markerId: const MarkerId('event_location'),
                        position: _selectedLocation!,
                        draggable: true,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          colorScheme.brightness == Brightness.light
                              ? BitmapDescriptor.hueOrange // Use a color that contrasts with light map
                              : BitmapDescriptor.hueYellow, // Use a color that contrasts with dark map
                        ),
                        onDragEnd: (newPosition) async {
                          _hideSuggestions();
                          if (mounted) {
                            setState(() {
                              _selectedLocation = newPosition;
                              _addressSuggestions = [];
                              _isShowingSuggestions = false;
                            });
                          }
                          _addressFocusNode.unfocus();
                          await _updateAddressFromLatLng(newPosition);
                        },
                      ),
                    }
                        : {},
                  )
                      : Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                    color: colorScheme.onSurface,
                  )
                      : const Text(
                    'Usar ubicación actual',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Imagen',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _imageUrl != null ? 'imagen seleccionada' : 'sube una imágen',
                    style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.6)),
                  ),
                  trailing: Icon(
                    Icons.add_a_photo,
                    color: colorScheme.onSurface,
                  ),
                  onTap: _pickAndUploadImage,
                  tileColor: colorScheme.secondary.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    _startTime == null
                        ? 'Hora de incio'
                        : 'Inicio: ${_startTime!.toString().substring(0, 16)}',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: colorScheme.onSurface,
                  ),
                  onTap: () => _selectDateTime(context, true),
                  tileColor: colorScheme.secondary.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                ),
                if (_startTime != null) ...[
                  ListTile(
                    title: Text(
                      _endTime == null
                          ? 'Hora de termino'
                          : 'Finaliza: ${_endTime!.toString().substring(0, 16)}',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color: colorScheme.onSurface,
                    ),
                    onTap: () => _selectDateTime(context, false),
                    tileColor: colorScheme.onSecondary.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.primary.withValues(alpha: .3)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.onSurface,
                  ),
                )
                    : ElevatedButton(
                  onPressed: (_startTime == null || _endTime == null) ? null : _createEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Crear Evento',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}