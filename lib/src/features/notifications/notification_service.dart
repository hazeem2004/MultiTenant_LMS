import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/application/auth_controller.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;

  NotificationService(this._ref);

  Future<void> init() async {
    try {
      // Request permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        dev.log('User granted permission');
      }

      // Get token and save to Firestore
      String? token = await _fcm.getToken().catchError((e) {
        dev.log('Error getting FCM token: $e');
        return null;
      });
      
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
    } catch (e) {
      dev.log('Notification initialization failed: $e');
    }

    // Handle foreground messages

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dev.log('Got a message whilst in the foreground!');
      dev.log('Message data: ${message.data}');

      if (message.notification != null) {
        dev.log('Message also contained a notification: ${message.notification}');
      }
    });

    // Handle background/terminated state messages when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      dev.log('A new onMessageOpenedApp event was published!');
    });
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _ref.read(authControllerProvider).value;
    if (user != null) {
      await _firestore.collection('user_tokens').doc(user.uid).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      dev.log('FCM Token saved for user: ${user.uid}');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
