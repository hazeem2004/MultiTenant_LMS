import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String weekId;
  final String title;
  final String descriptionText;
  final DateTime dueDate;
  final List<String> templateUrls;

  const Assignment({
    required this.id,
    required this.weekId,
    required this.title,
    required this.descriptionText,
    required this.dueDate,
    this.templateUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'weekId': weekId,
      'title': title,
      'descriptionText': descriptionText,
      'dueDate': dueDate.toIso8601String(),
      'templateUrls': templateUrls,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map, String id) {
    return Assignment(
      id: id,
      weekId: map['weekId']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Assignment',
      descriptionText: map['descriptionText']?.toString() ?? '',
      dueDate: _parseDate(map['dueDate']),
      templateUrls: List<String>.from(map['templateUrls'] ?? []),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Assignment copyWith({
    String? title,
    String? descriptionText,
    DateTime? dueDate,
    List<String>? templateUrls,
  }) {
    return Assignment(
      id: id,
      weekId: weekId,
      title: title ?? this.title,
      descriptionText: descriptionText ?? this.descriptionText,
      dueDate: dueDate ?? this.dueDate,
      templateUrls: templateUrls ?? this.templateUrls,
    );
  }
}
