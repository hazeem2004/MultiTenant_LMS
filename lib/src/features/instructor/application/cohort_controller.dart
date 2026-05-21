import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../data/cohort_repository.dart';
import '../domain/cohort.dart';

class CohortListController extends StreamNotifier<List<Cohort>> {
  @override
  Stream<List<Cohort>> build() {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return Stream.value([]);
    
    final repo = ref.read(cohortRepositoryProvider);
    return repo.watchCohortsForInstructor(user.uid);
  }

  Future<void> addCohort(String name, String description) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    
    final repo = ref.read(cohortRepositoryProvider);
    await repo.createCohort(name, description, user.uid);
  }

  Future<void> deleteCohort(String cohortId) async {
    final repo = ref.read(cohortRepositoryProvider);
    await repo.deleteCohort(cohortId);
  }
}

final cohortListProvider = StreamNotifierProvider<CohortListController, List<Cohort>>(() {
  return CohortListController();
});
