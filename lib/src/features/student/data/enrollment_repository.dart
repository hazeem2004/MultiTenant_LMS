import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enrollment.dart';

class EnrollmentRepository {
  final FirebaseFirestore _firestore;
  EnrollmentRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _enrollmentsRef => _firestore.collection('enrollments');

  Future<List<Enrollment>> getEnrollmentsForStudent(String studentId) async {
    final snapshot = await _enrollmentsRef.where('studentId', isEqualTo: studentId).get();
    return snapshot.docs.map((doc) => Enrollment.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<Enrollment>> getEnrollmentsForCohort(String cohortId) async {
    final snapshot = await _enrollmentsRef.where('cohortId', isEqualTo: cohortId).get();
    return snapshot.docs.map((doc) => Enrollment.fromMap(doc.id, doc.data())).toList();
  }

  Future<Enrollment> enrollStudent(String studentId, String cohortId) async {
    // Check if already enrolled
    final existing = await _enrollmentsRef
        .where('studentId', isEqualTo: studentId)
        .where('cohortId', isEqualTo: cohortId)
        .limit(1)
        .get();
    
    if (existing.docs.isNotEmpty) {
      return Enrollment.fromMap(existing.docs.first.id, existing.docs.first.data());
    }

    final docRef = await _enrollmentsRef.add({
      'cohortId': cohortId,
      'studentId': studentId,
      'status': 'pending',
      'enrolledAt': FieldValue.serverTimestamp(),
    });

    return Enrollment(
      id: docRef.id,
      cohortId: cohortId,
      studentId: studentId,
      status: 'pending',
    );
  }

  Future<void> updateEnrollmentStatus(String enrollmentId, String newStatus) async {
    await _enrollmentsRef.doc(enrollmentId).update({'status': newStatus});
  }
}

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository(FirebaseFirestore.instance);
});
