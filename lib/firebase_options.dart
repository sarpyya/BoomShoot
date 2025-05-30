// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC6AH-j1LLLsfxS4Ql9Si0ISjpafKYFTWY',
    appId: '1:577575467607:web:9ea0873fc022fb97',
    messagingSenderId: '577575467607',
    projectId: 'test-31f21',
    authDomain: 'test-31f21.firebaseapp.com',
    databaseURL: 'https://test-31f21.firebaseio.com',
    storageBucket: 'test-31f21.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSxj_IrLAwMebpiASP6O6BvcAyst6th4o',
    appId: '1:577575467607:android:ad34c975f1e5afc6d64112',
    messagingSenderId: '577575467607',
    projectId: 'test-31f21',
    databaseURL: 'https://test-31f21.firebaseio.com',
    storageBucket: 'test-31f21.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC57AkfDeDECMaGywdbH_tLJzduQmYGqow',
    appId: '1:577575467607:ios:04da84279669feb7d64112',
    messagingSenderId: '577575467607',
    projectId: 'test-31f21',
    databaseURL: 'https://test-31f21.firebaseio.com',
    storageBucket: 'test-31f21.firebasestorage.app',
    iosBundleId: 'com.example.bs',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC57AkfDeDECMaGywdbH_tLJzduQmYGqow',
    appId: '1:577575467607:ios:04da84279669feb7d64112',
    messagingSenderId: '577575467607',
    projectId: 'test-31f21',
    databaseURL: 'https://test-31f21.firebaseio.com',
    storageBucket: 'test-31f21.firebasestorage.app',
    iosBundleId: 'com.example.bs',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDBGIuqrTDzvVBlP54KuQZnJHfUve50wJg',
    appId: '1:577575467607:web:2b465bb131b08aa4d64112',
    messagingSenderId: '577575467607',
    projectId: 'test-31f21',
    authDomain: 'test-31f21.firebaseapp.com',
    databaseURL: 'https://test-31f21.firebaseio.com',
    storageBucket: 'test-31f21.firebasestorage.app',
  );
}
