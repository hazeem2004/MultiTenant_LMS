import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/week.dart';
import '../domain/assignment.dart';

class CurriculumRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  CurriculumRepository(this._firestore);

  Future<List<Week>> getWeeksForCohort(String cohortId) async {
    final snapshot = await _firestore
        .collection('weeks')
        .where('cohortId', isEqualTo: cohortId)
        .get();
    
    final weeks = snapshot.docs
        .map((doc) => Week.fromMap(doc.data(), doc.id))
        .toList();

    // Sort in-memory to avoid requiring a composite index in Firestore
    weeks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    
    return weeks;
  }

  Future<List<Assignment>> getAssignmentsForWeek(String weekId) async {
    final snapshot = await _firestore
        .collection('assignments')
        .where('weekId', isEqualTo: weekId)
        .get();
    
    return snapshot.docs
        .map((doc) => Assignment.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Week> addWeek(String cohortId, String title) async {
    final existingWeeks = await getWeeksForCohort(cohortId);
    final nextOrder = existingWeeks.isEmpty ? 1 : existingWeeks.last.orderIndex + 1;
    
    final docRef = await _firestore.collection('weeks').add({
      'cohortId': cohortId,
      'title': title,
      'orderIndex': nextOrder,
    });
    
    return Week(
      id: docRef.id,
      cohortId: cohortId,
      title: title,
      orderIndex: nextOrder,
    );
  }

  Future<String> uploadAssignmentTemplate(String assignmentId, Uint8List fileBytes, String fileName) async {
    final ref = _storage.ref().child('assignments/$assignmentId/templates/$fileName');
    final uploadTask = await ref.putData(fileBytes);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<Assignment> addAssignment({
    required String weekId,
    required String title,
    required String descriptionText,
    required DateTime dueDate,
    List<String> templateUrls = const [],
  }) async {
    final docRef = await _firestore.collection('assignments').add({
      'weekId': weekId,
      'title': title,
      'descriptionText': descriptionText,
      'dueDate': dueDate.toIso8601String(),
      'templateUrls': templateUrls,
    });
    
    return Assignment(
      id: docRef.id,
      weekId: weekId,
      title: title,
      descriptionText: descriptionText,
      dueDate: dueDate,
      templateUrls: templateUrls,
    );
  }
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository(FirebaseFirestore.instance);
});
