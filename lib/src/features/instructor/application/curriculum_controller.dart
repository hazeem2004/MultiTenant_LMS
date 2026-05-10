import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/curriculum_repository.dart';
import '../domain/week.dart';
import '../domain/assignment.dart';

class CurriculumState {
  final List<Week> weeks;
  final Map<String, List<Assignment>> assignmentsByWeek; 

  CurriculumState({required this.weeks, required this.assignmentsByWeek});
}

final curriculumProvider = FutureProvider.family<CurriculumState, String>((ref, cohortId) async {
  final repo = ref.read(curriculumRepositoryProvider);
  final weeks = await repo.getWeeksForCohort(cohortId);
  
  final Map<String, List<Assignment>> mapping = {};
  for (var week in weeks) {
    mapping[week.id] = await repo.getAssignmentsForWeek(week.id);
  }
  
  return CurriculumState(weeks: weeks, assignmentsByWeek: mapping);
});

class CurriculumController {
  final Ref ref;
  CurriculumController(this.ref);

  Future<void> addWeek(String cohortId, String title) async {
    final repo = ref.read(curriculumRepositoryProvider);
    await repo.addWeek(cohortId, title);
    ref.invalidate(curriculumProvider(cohortId));
  }

  Future<void> addAssignment(String cohortId, String weekId, String title, String descriptionText, DateTime dueDate) async {
    final repo = ref.read(curriculumRepositoryProvider);
    await repo.addAssignment(weekId, title, descriptionText, dueDate);
    ref.invalidate(curriculumProvider(cohortId));
  }
}

final curriculumControllerProvider = Provider<CurriculumController>((ref) {
  return CurriculumController(ref);
});
