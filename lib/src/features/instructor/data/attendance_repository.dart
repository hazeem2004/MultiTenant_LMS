import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/curriculum_content.dart';

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

  Stream<Map<String, String>> watchAttendance(String cohortId, String date) {
    return _firestore
        .collection('cohorts')
        .doc(cohortId)
        .collection('attendance')
        .doc(date)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        return Map<String, String>.from(data['statuses'] ?? {});
      }
      return {};
    });
  }
  Future<List<AttendanceRecord>> getStudentAttendanceHistory(String cohortId, String studentId) async {
    final snapshot = await _firestore
        .collection('cohorts')
        .doc(cohortId)
        .collection('attendance')
        .get();
    
    List<AttendanceRecord> records = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final statuses = Map<String, String>.from(data['statuses'] ?? {});
      if (statuses.containsKey(studentId)) {
        records.add(AttendanceRecord(date: doc.id, status: statuses[studentId]!));
      }
    }
    records.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    return records;
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(FirebaseFirestore.instance);
});

final studentAttendanceProvider = FutureProvider.family<List<AttendanceRecord>, ({String cohortId, String studentId})>((ref, arg) {
  return ref.watch(attendanceRepositoryProvider).getStudentAttendanceHistory(arg.cohortId, arg.studentId);
});
