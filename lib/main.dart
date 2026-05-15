import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/features/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications gracefully
  try {
    await container.read(notificationServiceProvider).init();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DevCohortApp(),
    ),
  );
}
