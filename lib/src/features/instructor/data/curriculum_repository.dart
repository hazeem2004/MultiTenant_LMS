import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/week.dart';
import '../domain/assignment.dart';

class CurriculumRepository {
  final FirebaseFirestore _firestore;
  CurriculumRepository(this._firestore);

  Future<List<Week>> getWeeksForCohort(String cohortId) async {
    final snapshot = await _firestore
        .collection('weeks')
        .where('cohortId', isEqualTo: cohortId)
        .orderBy('orderIndex')
        .get();
    
    return snapshot.docs
        .map((doc) => Week.fromMap(doc.data(), doc.id))
        .toList();
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

  Future<Assignment> addAssignment(String weekId, String title, String descriptionText, DateTime dueDate) async {
    final docRef = await _firestore.collection('assignments').add({
      'weekId': weekId,
      'title': title,
      'descriptionText': descriptionText,
      'dueDate': dueDate.toIso8601String(),
    });
    
    return Assignment(
      id: docRef.id,
      weekId: weekId,
      title: title,
      descriptionText: descriptionText,
      dueDate: dueDate,
    );
  }
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository(FirebaseFirestore.instance);
});
