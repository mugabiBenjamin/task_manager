import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_manager/services/firestore_service.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    final firestoreService = FirestoreService();
    await firestoreService.cleanupInvalidInvitations();
  } catch (e) {
    if (kDebugMode) {
      print('Error during invalid invitations cleanup at startup: $e');
    }
  }

  runApp(const App());
}
