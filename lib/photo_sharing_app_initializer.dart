import 'dart:async';
import 'package:bs/photo_sharing_app.dart';
import 'package:bs/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:bs/providers/theme_provider.dart';
import 'package:bs/providers/main_view_model.dart';
import 'package:bs/firebase_options.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class PhotoSharingAppInitializer extends StatefulWidget {
  const PhotoSharingAppInitializer({super.key});

  @override
  _PhotoSharingAppInitializerState createState() => _PhotoSharingAppInitializerState();
}

class _PhotoSharingAppInitializerState extends State<PhotoSharingAppInitializer> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    developer.log('PhotoSharingAppInitializer: initState called', name: 'PhotoSharingAppInitializer');
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      developer.log('PhotoSharingAppInitializer: Loading environment variables', name: 'PhotoSharingAppInitializer');
      await dotenv.load(fileName: ".env").timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Failed to load .env file after 5 seconds');
        },
      );
      developer.log('PhotoSharingAppInitializer: Initializing Firebase', name: 'PhotoSharingAppInitializer');
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firebase initialization timed out after 10 seconds');
        },
      );
      developer.log('PhotoSharingAppInitializer: Firebase initialized successfully', name: 'PhotoSharingAppInitializer');

      // Run Firestore migration
      developer.log('PhotoSharingAppInitializer: Checking for Firestore migration', name: 'PhotoSharingAppInitializer');
      final prefs = await SharedPreferences.getInstance();
      const migrationKey = 'user_model_migration_v2';
      final migrationCompleted = prefs.getBool(migrationKey) ?? false;

      if (!migrationCompleted) {
        developer.log('PhotoSharingAppInitializer: Starting Firestore migration', name: 'PhotoSharingAppInitializer');
        final dataService = FirebaseDataService();
        await dataService.migrateUsers();
        await prefs.setBool(migrationKey, true);
        developer.log('PhotoSharingAppInitializer: Firestore migration completed', name: 'PhotoSharingAppInitializer');
      }
    } catch (e, stackTrace) {
      developer.log('PhotoSharingAppInitializer: Error initializing app: $e', name: 'PhotoSharingAppInitializer', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('PhotoSharingAppInitializer: Building UI', name: 'PhotoSharingAppInitializer');
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        developer.log('PhotoSharingAppInitializer: FutureBuilder state: ${snapshot.connectionState}', name: 'PhotoSharingAppInitializer');
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            developer.log('PhotoSharingAppInitializer: Initialization error: ${snapshot.error}', name: 'PhotoSharingAppInitializer');
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error initializing app: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _initFuture = _initializeApp();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          developer.log('PhotoSharingAppInitializer: Initializing providers', name: 'PhotoSharingAppInitializer');
          final authProvider = AuthProvider();
          final mainViewModel = MainViewModel();
          final themeProvider = ThemeProvider(authProvider);

          developer.log('PhotoSharingAppInitializer: Rendering PhotoSharingApp', name: 'PhotoSharingAppInitializer');
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider.value(value: mainViewModel),
              ChangeNotifierProvider.value(value: themeProvider),
            ],
            child: PhotoSharingApp(authProvider: authProvider),
          );
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}