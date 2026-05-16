import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final List<Map<String, dynamic>> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'questions': questions,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map, String id) {
    return Quiz(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      dueDate: _parseDate(map['dueDate']),
      questions: List<Map<String, dynamic>>.from(map['questions'] ?? []),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class LectureNote {
  final String id;
  final String title;
  final String contentMarkdown;
  final List<String> pdfUrls;

  LectureNote({
    required this.id,
    required this.title,
    required this.contentMarkdown,
    required this.pdfUrls,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'contentMarkdown': contentMarkdown,
      'pdfUrls': pdfUrls,
    };
  }

  factory LectureNote.fromMap(Map<String, dynamic> map, String id) {
    return LectureNote(
      id: id,
      title: map['title']?.toString() ?? '',
      contentMarkdown: map['contentMarkdown']?.toString() ?? '',
      pdfUrls: List<String>.from(map['pdfUrls'] ?? []),
    );
  }
}

class AttendanceRecord {
  final String date;
  final String status; // 'present', 'absent', 'late'

  AttendanceRecord({required this.date, required this.status});
}
