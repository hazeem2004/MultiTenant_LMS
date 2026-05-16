import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../../instructor/data/cohort_repository.dart';
import '../../instructor/domain/cohort.dart';
import '../data/enrollment_repository.dart';

class StudentCohortsController extends AsyncNotifier<List<Cohort>> {
  @override
  Future<List<Cohort>> build() async {
    return _fetchEnrolledCohorts();
  }

  Future<List<Cohort>> _fetchEnrolledCohorts() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return [];

    final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
    final cohortRepo = ref.read(cohortRepositoryProvider);

    final enrollments = await enrollmentRepo.getEnrollmentsForStudent(user.uid);
    
    final cohortIds = enrollments.map((e) => e.cohortId).toList();
    if (cohortIds.isEmpty) return [];

    final cohorts = await cohortRepo.fetchCohortsByIds(cohortIds);
    
    // Auto-select first cohort if none selected
    if (cohorts.isNotEmpty && ref.read(selectedCohortProvider) == null) {
      ref.read(selectedCohortProvider.notifier).setCohort(cohorts.first);
    }

    return cohorts;
  }

  Future<String?> joinCohort(String code) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return 'You must be logged in to join a class.';

    final cohortRepo = ref.read(cohortRepositoryProvider);
    final enrollmentRepo = ref.read(enrollmentRepositoryProvider);

    final cohort = await cohortRepo.getCohortByClassCode(code);
    if (cohort == null) return 'Invalid class code. Please check and try again.';

    await enrollmentRepo.enrollStudent(user.uid, cohort.id);
    
    // Refresh the list
    ref.invalidateSelf();
    await future;
    
    // Switch to the newly joined cohort
    ref.read(selectedCohortProvider.notifier).setCohort(cohort);
    
    return null; // Success
  }
}

final studentCohortsProvider = AsyncNotifierProvider<StudentCohortsController, List<Cohort>>(() {
  return StudentCohortsController();
});

final selectedCohortProvider = NotifierProvider<SelectedCohortNotifier, Cohort?>(() {
  return SelectedCohortNotifier();
});

class SelectedCohortNotifier extends Notifier<Cohort?> {
  @override
  Cohort? build() => null;

  void setCohort(Cohort? cohort) {
    state = cohort;
  }
}
