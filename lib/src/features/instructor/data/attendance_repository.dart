import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;
  AttendanceRepository(this._firestore);

  Future<void> saveAttendance({
    required String cohortId,
    required String date, // YYYY-MM-DD
    required Map<String, String> statusMap, // {studentId: 'present'|'absent'|'late'}
  }) async {
    await _firestore
        .collection('cohorts')
        .doc(cohortId)
        .collection('attendance')
        .doc(date)
        .set({
      'statuses': statusMap,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, String>> getAttendance(String cohortId, String date) async {
    final doc = await _firestore
        .collection('cohorts')
        .doc(cohortId)
        .collection('attendance')
        .doc(date)
        .get();
    
    if (doc.exists) {
      final data = doc.data()!;
      return Map<String, String>.from(data['statuses'] ?? {});
    }
    return {};
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(FirebaseFirestore.instance);
});
