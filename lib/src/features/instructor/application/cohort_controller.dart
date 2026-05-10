import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../data/cohort_repository.dart';
import '../domain/cohort.dart';

class CohortListController extends AsyncNotifier<List<Cohort>> {
  @override
  Future<List<Cohort>> build() async {
    return _fetchUserCohorts();
  }

  Future<List<Cohort>> _fetchUserCohorts() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return [];
    final repo = ref.read(cohortRepositoryProvider);
    return repo.fetchCohortsForInstructor(user.uid);
  }

  Future<void> addCohort(String name, String description) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cohortRepositoryProvider);
      await repo.createCohort(name, description, user.uid);
      return _fetchUserCohorts();
    });
  }

  Future<void> deleteCohort(String cohortId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cohortRepositoryProvider);
      await repo.deleteCohort(cohortId);
      return _fetchUserCohorts();
    });
  }
}

final cohortListProvider = AsyncNotifierProvider<CohortListController, List<Cohort>>(() {
  return CohortListController();
});
