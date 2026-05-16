import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  NotificationRepository(this._firestore);

  CollectionReference<AppNotification> _notificationsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications').withConverter<AppNotification>(
            fromFirestore: (snapshot, _) => AppNotification.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (notif, _) => notif.toMap(),
          );

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notificationsRef(userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsRef(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> sendNotification(String userId, AppNotification notification) async {
    await _notificationsRef(userId).add(notification);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(FirebaseFirestore.instance);
});

final notificationsProvider = StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider).watchNotifications(userId);
});
