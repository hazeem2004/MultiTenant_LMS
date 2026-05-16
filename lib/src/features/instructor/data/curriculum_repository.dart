import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/week.dart';
import '../domain/assignment.dart';
import '../domain/curriculum_content.dart';

class CurriculumRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  CurriculumRepository(this._firestore);

  // Helper for week collection path
  CollectionReference _weeksRef(String cohortId) => 
      _firestore.collection('cohorts').doc(cohortId).collection('weeks');

  Future<List<Week>> getWeeksForCohort(String cohortId) async {
    final snapshot = await _weeksRef(cohortId).get();
    
    final weeks = snapshot.docs
        .map((doc) => Week.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    weeks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return weeks;
  }

  Future<List<Assignment>> getAssignmentsForWeek(String cohortId, String weekId) async {
    final snapshot = await _weeksRef(cohortId).doc(weekId).collection('assignments').get();
    return snapshot.docs.map((doc) => Assignment.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<Quiz>> getQuizzesForWeek(String cohortId, String weekId) async {
    final snapshot = await _weeksRef(cohortId).doc(weekId).collection('quizzes').get();
    return snapshot.docs.map((doc) => Quiz.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<LectureNote>> getLectureNotesForWeek(String cohortId, String weekId) async {
    final snapshot = await _weeksRef(cohortId).doc(weekId).collection('lectureNotes').get();
    return snapshot.docs.map((doc) => LectureNote.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<Week> addWeek(String cohortId, String title) async {
    final existingWeeks = await getWeeksForCohort(cohortId);
    final nextOrder = existingWeeks.isEmpty ? 1 : existingWeeks.last.orderIndex + 1;
    
    final docRef = await _weeksRef(cohortId).add({
      'cohortId': cohortId,
      'title': title,
      'orderIndex': nextOrder,
    });
    
    return Week(id: docRef.id, cohortId: cohortId, title: title, orderIndex: nextOrder);
  }

  Future<void> addAssignment({
    required String cohortId,
    required String weekId,
    required String title,
    required String descriptionText,
    required DateTime dueDate,
    List<String> templateUrls = const [],
  }) async {
    await _weeksRef(cohortId).doc(weekId).collection('assignments').add({
      'title': title,
      'descriptionText': descriptionText,
      'dueDate': dueDate.toIso8601String(),
      'templateUrls': templateUrls,
    });
  }

  Future<void> addQuiz({
    required String cohortId,
    required String weekId,
    required Quiz quiz,
  }) async {
    await _weeksRef(cohortId).doc(weekId).collection('quizzes').add(quiz.toMap());
  }

  Future<void> addLectureNote({
    required String cohortId,
    required String weekId,
    required LectureNote note,
  }) async {
    await _weeksRef(cohortId).doc(weekId).collection('lectureNotes').add(note.toMap());
  }

  Future<String> uploadContentFile(String path, Uint8List fileBytes, String fileName) async {
    final ref = _storage.ref().child('$path/$fileName');
    final uploadTask = await ref.putData(fileBytes);
    return await uploadTask.ref.getDownloadURL();
  }
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository(FirebaseFirestore.instance);
});
