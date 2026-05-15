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

  Future<Cohort?> getCohortByToken(String token) async {
    final snapshot = await _cohortsRef.where('inviteToken', isEqualTo: token).limit(1).get();
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
    final inviteToken = _generateToken();
    final docRef = await _cohortsRef.add({
      'name': name,
      'description': description,
      'instructorId': instructorId,
      'inviteToken': inviteToken,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return Cohort(
      id: docRef.id,
      name: name,
      description: description,
      instructorId: instructorId,
      inviteToken: inviteToken,
      createdAt: DateTime.now(),
    );
  }

  Future<void> updateCohort(Cohort updatedCohort) async {
    await _cohortsRef.doc(updatedCohort.id).update({
      'name': updatedCohort.name,
      'description': updatedCohort.description,
    });
  }

  Future<void> deleteCohort(String cohortId) async {
    await _cohortsRef.doc(cohortId).delete();
  }

  String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // TTL Token Logic
  Future<String> generateTTLToken(String cohortId) async {
    final token = _generateToken();
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    
    await _firestore.collection('invites').add({
      'cohortId': cohortId,
      'token': token,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    });
    
    return token;
  }

  Future<List<Cohort>> fetchCohortsByIds(List<String> cohortIds) async {
    if (cohortIds.isEmpty) return [];
    
    // Firestore 'in' query has a limit of 10 items per batch.
    // Assuming a student is enrolled in < 10 cohorts, but let's handle chunks if needed.
    final cohorts = <Cohort>[];
    
    // Split into chunks of 10
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
