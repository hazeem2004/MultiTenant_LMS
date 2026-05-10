import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enrollment.dart';

class EnrollmentRepository {
  final List<Enrollment> _enrollments = [];

  Future<List<Enrollment>> getEnrollmentsForCohort(String cohortId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _enrollments.where((e) => e.cohortId == cohortId).toList();
  }

  Future<Enrollment> enrollStudent(String studentId, String cohortId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newEnrollment = Enrollment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cohortId: cohortId,
      studentId: studentId,
      status: 'pending',
    );
    _enrollments.add(newEnrollment);
    return newEnrollment;
  }

  Future<void> updateEnrollmentStatus(String enrollmentId, String newStatus) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (index != -1) {
      _enrollments[index] = _enrollments[index].copyWith(status: newStatus);
    }
  }
}

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository();
});
