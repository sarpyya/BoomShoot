import 'dart:io';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/models/event.dart';
import 'package:bs/models/group.dart';
import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

class CameraScreen extends StatefulWidget {
  final String userId;

  const CameraScreen({super.key, required this.userId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  File? _capturedImage;
  bool _isMobile = false;
  bool _isUploading = false;
  final TextEditingController _contentController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedEventId;
  List<Group> _groups = [];
  List<Event> _events = [];

  int _selectedCameraIndex = 0;
  List<CameraDescription> _availableCameras = [];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkDevice();
    _loadGroupsAndEvents();

    // Initialize animation controller for button animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _checkDevice() async {
    try {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        developer.log('Non-mobile platform detected', name: 'CameraScreen');
        setState(() {
          _isMobile = false;
        });
        return;
      }

      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final isTablet = androidInfo.isPhysicalDevice &&
            (androidInfo.model.toLowerCase().contains('tablet'));
        setState(() {
          _isMobile = !isTablet;
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final isTablet = iosInfo.model.toLowerCase().contains('ipad');
        setState(() {
          _isMobile = !isTablet;
        });
      }

      if (_isMobile) {
        await _initializeCamera();
      }
    } catch (e, stackTrace) {
      developer.log('Error checking device: $e',
          name: 'CameraScreen', stackTrace: stackTrace);
      setState(() {
        _isMobile = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        developer.log('No cameras available', name: 'CameraScreen');
        setState(() {
          _isMobile = false;
        });
        return;
      }
      _controller = CameraController(
        _availableCameras[_selectedCameraIndex],
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    } catch (e, stackTrace) {
      developer.log('Error initializing camera: $e',
          name: 'CameraScreen', stackTrace: stackTrace);
      setState(() {
        _isMobile = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    });

    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _loadGroupsAndEvents() async {
    try {
      final groups = await FirebaseDataService().getUserGroups(widget.userId);
      final events = await FirebaseDataService().getEvents();
      setState(() {
        _groups = groups;
        _events = events;
      });
    } catch (e, stackTrace) {
      developer.log('Error loading groups/events: $e',
          name: 'CameraScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar grupos/eventos: $e')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      if (_controller == null || !_controller!.value.isInitialized) {
        throw 'Camera not initialized';
      }
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
      });
      developer.log('Picture taken: ${image.path}', name: 'CameraScreen');
    } catch (e, stackTrace) {
      developer.log('Error taking picture: $e',
          name: 'CameraScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }

  Future<void> _uploadPost() async {
    if (_capturedImage == null || _isUploading) return;
    setState(() {
      _isUploading = true;
    });
    try {
      final imageUrl =
      await FirebaseDataService().uploadPostImage(_capturedImage!);
      if (imageUrl == null) {
        throw 'Error uploading image';
      }
      await FirebaseDataService().createPost(
        userId: widget.userId,
        content: _contentController.text,
        imageUrl: imageUrl,
        groupId: _selectedGroupId,
        eventId: _selectedEventId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación creada')),
      );
      setState(() {
        _capturedImage = null;
        _contentController.clear();
        _selectedGroupId = null;
        _selectedEventId = null;
      });
      context.go('/home');
    } catch (e, stackTrace) {
      developer.log('Error uploading post: $e',
          name: 'CameraScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear publicación: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cámara'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('La cámara solo está disponible en dispositivos móviles'),
        ),
      );
    }

    if (_controller == null || _initializeControllerFuture == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cámara'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _capturedImage == null
          ? FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return Stack(
              children: [
                CameraPreview(_controller!),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Bottom bar with camera controls
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Empty space or placeholder for balance (if needed)
                      const SizedBox(width: 48),
                      // Animated FloatingActionButton for taking a picture
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: FloatingActionButton(
                              onPressed: _takePicture,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.camera_alt, color: Colors.white),
                            ),
                          );
                        },
                      ),
                      // Switch camera button
                      IconButton(
                        icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      )
          : Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Image.file(
                  _capturedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Añade una descripción a tu foto',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Grupo (opcional)',
                        ),
                        value: _selectedGroupId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Ninguno'),
                          ),
                          ..._groups.map((group) => DropdownMenuItem(
                            value: group.groupId,
                            child: Text(group.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGroupId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Evento (opcional)',
                        ),
                        value: _selectedEventId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Ninguno'),
                          ),
                          ..._events.map((event) => DropdownMenuItem(
                            value: event.eventId,
                            child: Text(event.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedEventId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Fixed bottom bar for "Publicar" and "Descartar" buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _capturedImage != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Publicar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _capturedImage = null;
                            _contentController.clear();
                            _selectedGroupId = null;
                            _selectedEventId = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Descartar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}