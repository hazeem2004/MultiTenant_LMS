import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? cohortId;
  final String? routeUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.cohortId,
    this.routeUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'cohortId': cohortId,
      'routeUrl': routeUrl,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      cohortId: map['cohortId']?.toString(),
      routeUrl: map['routeUrl']?.toString(),
    );
  }
}
