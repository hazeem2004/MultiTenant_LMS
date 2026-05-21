import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cohort.dart';

class CohortRepository {
  final FirebaseFirestore _firestore;
  CohortRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _cohortsRef => _firestore.collection('cohorts');

  Future<List<Cohort>> fetchCohortsForInstructor(String instructorId) async {
    final snapshot = await _cohortsRef.where('instructorId', isEqualTo: instructorId).get();
    return snapshot.docs.map((doc) => Cohort.fromMap(doc.id, doc.data())).toList();
  }

  Stream<List<Cohort>> watchCohortsForInstructor(String instructorId) {
    return _cohortsRef
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Cohort.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<Cohort>> watchCohortsByIds(List<String> cohortIds) {
    if (cohortIds.isEmpty) return Stream.value([]);
    
    // Note: Firestore has a limit of 10-30 IDs for 'whereIn' depending on version.
    // For simplicity, we assume cohortIds.length <= 10 for real-time streams here, 
    // or we'd need to combine multiple streams.
    return _cohortsRef
        .where(FieldPath.documentId, whereIn: cohortIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Cohort.fromMap(doc.id, doc.data())).toList());
  }

  Future<Cohort?> getCohortByClassCode(String code) async {
    final snapshot = await _cohortsRef.where('classCode', isEqualTo: code).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return Cohort.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    }
    return null;
  }

  Future<Cohort?> getCohortById(String cohortId) async {
    final doc = await _cohortsRef.doc(cohortId).get();
    if (doc.exists) {
      return Cohort.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<Cohort> createCohort(String name, String description, String instructorId) async {
    final classCode = _generateCode();
    final docRef = await _cohortsRef.add({
      'name': name,
      'description': description,
      'instructorId': instructorId,
      'classCode': classCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return Cohort(
      id: docRef.id,
      name: name,
      description: description,
      instructorId: instructorId,
      classCode: classCode,
      createdAt: DateTime.now(),
    );
  }

  Future<void> updateCohort(Cohort updatedCohort) async {
    await _cohortsRef.doc(updatedCohort.id).update({
      'name': updatedCohort.name,
      'description': updatedCohort.description,
    });
  }

  Future<void> updateInstructor(String cohortId, String newInstructorId) async {
    await _cohortsRef.doc(cohortId).update({
      'instructorId': newInstructorId,
    });
  }

  Future<String> regenerateClassCode(String cohortId) async {
    final newCode = _generateCode();
    await _cohortsRef.doc(cohortId).update({
      'classCode': newCode,
    });
    return newCode;
  }

  Future<void> updateCodeExpiry(String cohortId, DateTime? expiryDate) async {
    await _cohortsRef.doc(cohortId).update({
      'classCodeExpiry': expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
    });
  }

  Future<void> deleteCohort(String cohortId) async {
    await _cohortsRef.doc(cohortId).delete();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<List<Cohort>> fetchCohortsByIds(List<String> cohortIds) async {
    if (cohortIds.isEmpty) return [];
    
    final cohorts = <Cohort>[];
    
    for (var i = 0; i < cohortIds.length; i += 10) {
      final chunk = cohortIds.sublist(i, i + 10 > cohortIds.length ? cohortIds.length : i + 10);
      final snapshot = await _cohortsRef.where(FieldPath.documentId, whereIn: chunk).get();
      cohorts.addAll(snapshot.docs.map((doc) => Cohort.fromMap(doc.id, doc.data())));
    }
    
    return cohorts;
  }
}

final cohortRepositoryProvider = Provider<CohortRepository>((ref) {
  return CohortRepository(FirebaseFirestore.instance);
});
