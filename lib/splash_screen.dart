import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:bs/photo_sharing_app_initializer.dart';
import 'package:bs/providers/theme_provider.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isAppInitialized = false;
  bool _hasNavigated = false;
  BuildContext? _navigatorContext;
  bool _listenerAdded = false; // Track if listener is added

  @override
  void initState() {
    super.initState();
    developer.log('SplashScreen: initState called', name: 'SplashScreen');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
      ),
    );

    developer.log('SplashScreen: Starting animation', name: 'SplashScreen');
    _animationController.forward();
    developer.log('SplashScreen: Starting app initialization', name: 'SplashScreen');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      developer.log('SplashScreen: Simulating app initialization', name: 'SplashScreen');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
        });
        developer.log('SplashScreen: Initialization completed', name: 'SplashScreen');
        _tryNavigate();
      }
    } catch (e, stackTrace) {
      developer.log('SplashScreen: Error during app initialization: $e', name: 'SplashScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
        });
        _tryNavigate();
      }
    }
  }

  void _tryNavigate() {
    if (_hasNavigated || !_isAppInitialized || _animationController.status != AnimationStatus.completed || _navigatorContext == null) {
      developer.log(
        'SplashScreen: Skipping navigation - hasNavigated: $_hasNavigated, isAppInitialized: $_isAppInitialized, animationStatus: ${_animationController.status}, navigatorContext: ${_navigatorContext != null}',
        name: 'SplashScreen',
      );
      return;
    }
    developer.log('SplashScreen: Performing navigation to PhotoSharingAppInitializer', name: 'SplashScreen');
    _navigateToMainApp(_navigatorContext!);
  }

  void _navigateToMainApp(BuildContext navigatorContext) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    try {
      Navigator.of(navigatorContext).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            developer.log('SplashScreen: Building PhotoSharingAppInitializer', name: 'SplashScreen');
            return const PhotoSharingAppInitializer();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            developer.log('SplashScreen: Building transition for PhotoSharingAppInitializer', name: 'SplashScreen');
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e, stackTrace) {
      developer.log('SplashScreen: Navigation error: $e', name: 'SplashScreen', stackTrace: stackTrace);
      Navigator.of(navigatorContext).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Navigation Error: Failed to load PhotoSharingAppInitializer'),
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    developer.log('SplashScreen: Disposing', name: 'SplashScreen');
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('SplashScreen: Building UI', name: 'SplashScreen');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
      ),
      home: Builder(
        builder: (BuildContext navigatorContext) {
          _navigatorContext = navigatorContext;
          if (!_listenerAdded) {
            _listenerAdded = true;
            _animationController.addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                developer.log('SplashScreen: Animation completed', name: 'SplashScreen');
                _tryNavigate();
              }
            });
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/main_scene.json',
                        controller: _animationController,
                        fit: BoxFit.contain,
                        onLoaded: (composition) {
                          if (composition == null) {
                            developer.log('SplashScreen: Failed to load main_scene.json animation', name: 'SplashScreen');
                          } else {
                            developer.log('SplashScreen: Lottie animation loaded successfully', name: 'SplashScreen');
                          }
                        },
                        errorBuilder: (context, error, stackTrace) {
                          developer.log('SplashScreen: Error loading animation: $error', name: 'SplashScreen', stackTrace: stackTrace);
                          return const Icon(
                            Icons.camera_alt,
                            size: 100,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'BoomShoot',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture the Moment',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}