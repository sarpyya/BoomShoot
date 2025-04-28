import 'package:bs/services/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bs/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dataService = FirebaseDataService();
  print('Starting Firestore migration...');
  try {
    //await dataService.migrateDatabase();
    print('Firestore migration completed.');
  } catch (e) {
    print('Migration error: $e');
  }
}