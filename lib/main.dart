import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bs/firebase_options.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runZonedGuarded(() async {
    developer.log('main: Initializing Flutter bindings', name: 'main');
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log('FlutterError: ${details.exceptionAsString()}', name: 'main');
      developer.log(details.stack.toString(), name: 'main');
    };

    developer.log('main: Initializing Firebase', name: 'main');
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      developer.log('main: Firebase initialized successfully', name: 'main');
    } catch (e, stackTrace) {
      developer.log('main: Firebase initialization failed: $e', name: 'main', stackTrace: stackTrace);
      runApp(const ErrorApp(message: 'Failed to initialize Firebase'));
      return;
    }

    developer.log('main: Checking for Firestore migration', name: 'main');
    final prefs = await SharedPreferences.getInstance();
    const migrationKey = 'user_model_migration_v2';
    final migrationCompleted = prefs.getBool(migrationKey) ?? false;

    if (!migrationCompleted) {
      developer.log('main: Starting Firestore migration', name: 'main');
      final dataService = FirebaseDataService();
      try {
        await dataService.migrateUsers();
        await prefs.setBool(migrationKey, true);
        developer.log('main: Firestore migration completed', name: 'main');
      } catch (e, stackTrace) {
        developer.log('main: Migration error: $e', name: 'main', stackTrace: stackTrace);
      }
    }

    developer.log('main: Running app with SplashScreen', name: 'main');
    runApp(const SplashScreen());
  }, (error, stackTrace) {
    developer.log('Zoned Error: $error', name: 'main');
    developer.log(stackTrace.toString(), name: 'main');
  });
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Error: $message',
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
}