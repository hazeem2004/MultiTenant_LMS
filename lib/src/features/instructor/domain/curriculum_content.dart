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
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      questions: List<Map<String, dynamic>>.from(map['questions'] ?? []),
    );
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
      title: map['title'] ?? '',
      contentMarkdown: map['contentMarkdown'] ?? '',
      pdfUrls: List<String>.from(map['pdfUrls'] ?? []),
    );
  }
}
