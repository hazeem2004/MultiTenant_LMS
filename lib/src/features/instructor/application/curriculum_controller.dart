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

  Future<void> addAssignment({
    required String cohortId,
    required String weekId,
    required String title,
    required String descriptionText,
    required DateTime dueDate,
    List<Map<String, dynamic>>? files, // List of {name, bytes}
  }) async {
    final repo = ref.read(curriculumRepositoryProvider);
    
    List<String> templateUrls = [];
    if (files != null && files.isNotEmpty) {
      // Temporary ID for storage path if needed, but repo uses assignmentId.
      // Actually repo needs assignmentId which is created IN the repo.
      // So we might need to create the assignment first with empty URLs, then upload, then update.
      // Or just use a random ID.
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      for (var file in files) {
        final url = await repo.uploadAssignmentTemplate(tempId, file['bytes'], file['name']);
        templateUrls.add(url);
      }
    }

    await repo.addAssignment(
      weekId: weekId,
      title: title,
      descriptionText: descriptionText,
      dueDate: dueDate,
      templateUrls: templateUrls,
    );
    ref.invalidate(curriculumProvider(cohortId));
  }
}

final curriculumControllerProvider = Provider<CurriculumController>((ref) {
  return CurriculumController(ref);
});
