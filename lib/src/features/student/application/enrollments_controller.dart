import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/enrollment_repository.dart';
import '../domain/enrollment.dart';

final enrollmentsProvider = FutureProvider.family<List<Enrollment>, String>((ref, cohortId) async {
  final repo = ref.read(enrollmentRepositoryProvider);
  return repo.getEnrollmentsForCohort(cohortId);
});

class EnrollmentsController {
  final Ref ref;
  EnrollmentsController(this.ref);

  Future<void> approveStudent(String cohortId, String enrollmentId) async {
    final repo = ref.read(enrollmentRepositoryProvider);
    await repo.updateEnrollmentStatus(enrollmentId, 'active');
    ref.invalidate(enrollmentsProvider(cohortId));
  }
}

final enrollmentsControllerProvider = Provider<EnrollmentsController>((ref) {
  return EnrollmentsController(ref);
});
