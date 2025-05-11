import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/event.dart';
import 'package:provider/provider.dart';
import 'package:bs/main.dart'; // For AuthProvider
import 'dart:developer' as developer;
import 'dart:async';

import '../photo_sharing_app_initializer.dart';
import '../providers/auth_provider.dart';

class GalleryScreen extends StatefulWidget {
  final String eventId;

  const GalleryScreen({super.key, required this.eventId});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final FirebaseDataService _dataService = FirebaseDataService();
  Future<Event?>? _eventFuture;
  int _currentCarouselIndex = 0;
  final PageController _carouselController = PageController(viewportFraction: 0.8);
  Timer? _autoPlayTimer;
  bool _isUserInteracting = false;
  int _autoPlaySpeed = 4; // Default to 4 seconds
  bool _isLoadingSettings = false;

  @override
  void initState() {
    super.initState();
    _eventFuture = _dataService.getEventById(widget.eventId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAutoPlaySpeed();
      if (mounted) {
        _startAutoPlay();
      }
    });
  }

  Future<void> _loadAutoPlaySpeed() async {
    setState(() {
      _isLoadingSettings = true;
    });
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        final settings = await _dataService.getUserSettings(userId);
        setState(() {
          _autoPlaySpeed = (settings['autoPlaySpeed'] as int?) ?? 4;
        });
      }
    } catch (e) {
      developer.log('Error loading auto-play speed: $e', name: 'GalleryScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar velocidad de auto-play: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel(); // Ensure previous timer is canceled
    if (_eventFuture != null) {
      _eventFuture!.then((event) {
        if (event != null && event.photos.length > 1 && mounted) {
          _autoPlayTimer?.cancel();
          _autoPlayTimer = Timer.periodic(Duration(seconds: _autoPlaySpeed), (timer) {
            if (mounted && !_isUserInteracting && _carouselController.hasClients) {
              setState(() {
                _currentCarouselIndex = (_currentCarouselIndex + 1) % event.photos.length;
              });
              _carouselController.animateToPage(
                _currentCarouselIndex,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      });
    }
  }

  void _showErrorSnackbar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }

  void _stopAutoPlayTemporarily() {
    _isUserInteracting = true;
    _autoPlayTimer?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isUserInteracting) {
        _isUserInteracting = false;
        _startAutoPlay();
      }
    });
  }

  void _prevSlide() {
    if (_currentCarouselIndex > 0) {
      _stopAutoPlayTemporarily();
      setState(() => _currentCarouselIndex--);
      _carouselController.animateToPage(
        _currentCarouselIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextSlide(List<String> photos) {
    if (_currentCarouselIndex < photos.length - 1) {
      _stopAutoPlayTemporarily();
      setState(() => _currentCarouselIndex++);
      _carouselController.animateToPage(
        _currentCarouselIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Galería del Evento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () {
              context.push('/event/${widget.eventId}');
            },
            tooltip: 'Ver Detalles del Evento',
          ),
        ],
      ),
      body: FutureBuilder<Event?>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoadingSettings) {
            return Center(
              child: SpinKitCircle(color: colorScheme.primary, size: 50),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            developer.log('Error fetching event: $error', name: 'GalleryScreen');
            _showErrorSnackbar('Error al cargar el evento: $error');
            return Center(
              child: Text(
                'Error al cargar el evento',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            developer.log('Event not found for eventId: ${widget.eventId}', name: 'GalleryScreen');
            _showErrorSnackbar('Evento no encontrado');
            return Center(
              child: Text(
                'Evento no encontrado',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            );
          }

          final event = snapshot.data!;
          final photos = event.photos;

          developer.log('Event loaded: ${event.eventId}, photos: ${photos.length}', name: 'GalleryScreen');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Fotos de ${event.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: photos.isEmpty
                    ? Center(
                  child: Text(
                    'No hay fotos disponibles',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                )
                    : Column(
                  children: [
                    // Carousel
                    SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _carouselController,
                            itemCount: photos.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentCarouselIndex = index;
                                _stopAutoPlayTemporarily();
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhotoViewer(
                                          photos: photos,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: photos[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => SpinKitCircle(
                                        color: colorScheme.primary,
                                        size: 50,
                                      ),
                                      errorWidget: (context, url, error) {
                                        developer.log(
                                            'Error loading photo: ${photos[index]}, error: $error',
                                            name: 'GalleryScreen');
                                        return Container(
                                          color: colorScheme.onSurface.withOpacity(0.1),
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: colorScheme.error,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (photos.length > 1) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.chevron_left, size: 40),
                                color: colorScheme.secondary,
                                onPressed: _prevSlide,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.chevron_right, size: 40),
                                color: colorScheme.secondary,
                                onPressed: () => _nextSlide(photos),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Page Indicator
                    if (photos.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            photos.length,
                                (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              width: 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentCarouselIndex == index
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Full-Screen Photo Viewer with Auto-Play
class PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoViewer({super.key, required this.photos, required this.initialIndex});

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  Timer? _autoPlayTimer;
  bool _isUserInteracting = false;
  final FirebaseDataService _dataService = FirebaseDataService();
  int _autoPlaySpeed = 4;
  bool _isLoadingSettings = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAutoPlaySpeed();
      if (widget.photos.length > 1 && mounted) {
        _startAutoPlay();
      }
    });
  }

  Future<void> _loadAutoPlaySpeed() async {
    setState(() {
      _isLoadingSettings = true;
    });
    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        final settings = await _dataService.getUserSettings(userId);
        setState(() {
          _autoPlaySpeed = (settings['autoPlaySpeed'] as int?) ?? 4;
        });
      }
    } catch (e) {
      developer.log('Error loading auto-play speed: $e', name: 'PhotoViewer');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar velocidad de auto-play: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(Duration(seconds: _autoPlaySpeed), (timer) {
      if (mounted && !_isUserInteracting && _pageController.hasClients) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.photos.length;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlayTemporarily() {
    _isUserInteracting = true;
    _autoPlayTimer?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isUserInteracting) {
        _isUserInteracting = false;
        _startAutoPlay();
      }
    });
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
      backgroundColor: Colors.black,
      body: _isLoadingSettings
          ? Center(
        child: SpinKitCircle(color: colorScheme.primary, size: 50),
      )
          : Stack(
        children: [
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            onInteractionStart: (_) => _stopAutoPlayTemporarily(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _stopAutoPlayTemporarily();
                });
              },
              itemBuilder: (context, index) {
                return Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => SpinKitCircle(
                      color: colorScheme.primary,
                      size: 50,
                    ),
                    errorWidget: (context, url, error) {
                      developer.log(
                          'Error loading full-screen photo: ${widget.photos[index]}, error: $error',
                          name: 'PhotoViewer');
                      return Container(
                        color: colorScheme.onSurface.withOpacity(0.1),
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: colorScheme.error,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Close Button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Page Indicator
          if (widget.photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photos.length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}