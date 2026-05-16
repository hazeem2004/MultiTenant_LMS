import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/curriculum_repository.dart';
import '../domain/week.dart';
import '../domain/assignment.dart';
import '../domain/curriculum_content.dart';

class CurriculumState {
  final List<Week> weeks;
  final Map<String, List<Assignment>> assignmentsByWeek; 
  final Map<String, List<Quiz>> quizzesByWeek;
  final Map<String, List<LectureNote>> lectureNotesByWeek;

  CurriculumState({
    required this.weeks, 
    required this.assignmentsByWeek,
    required this.quizzesByWeek,
    required this.lectureNotesByWeek,
  });
}

final curriculumProvider = FutureProvider.family<CurriculumState, String>((ref, cohortId) async {
  final repo = ref.read(curriculumRepositoryProvider);
  final weeks = await repo.getWeeksForCohort(cohortId);
  
  final Map<String, List<Assignment>> assignmentsMap = {};
  final Map<String, List<Quiz>> quizzesMap = {};
  final Map<String, List<LectureNote>> lectureNotesMap = {};

  for (var week in weeks) {
    assignmentsMap[week.id] = await repo.getAssignmentsForWeek(cohortId, week.id);
    quizzesMap[week.id] = await repo.getQuizzesForWeek(cohortId, week.id);
    lectureNotesMap[week.id] = await repo.getLectureNotesForWeek(cohortId, week.id);
  }
  
  return CurriculumState(
    weeks: weeks, 
    assignmentsByWeek: assignmentsMap,
    quizzesByWeek: quizzesMap,
    lectureNotesByWeek: lectureNotesMap,
  );
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
    List<Map<String, dynamic>>? files,
  }) async {
    final repo = ref.read(curriculumRepositoryProvider);
    
    List<String> templateUrls = [];
    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        final url = await repo.uploadContentFile('assignments/$weekId/templates', file['bytes'], file['name']);
        templateUrls.add(url);
      }
    }

    await repo.addAssignment(
      cohortId: cohortId,
      weekId: weekId,
      title: title,
      descriptionText: descriptionText,
      dueDate: dueDate,
      templateUrls: templateUrls,
    );
    ref.invalidate(curriculumProvider(cohortId));
  }

  Future<void> addQuiz(String cohortId, String weekId, Quiz quiz) async {
    await ref.read(curriculumRepositoryProvider).addQuiz(cohortId: cohortId, weekId: weekId, quiz: quiz);
    ref.invalidate(curriculumProvider(cohortId));
  }

  Future<void> addLectureNote(String cohortId, String weekId, LectureNote note) async {
    await ref.read(curriculumRepositoryProvider).addLectureNote(cohortId: cohortId, weekId: weekId, note: note);
    ref.invalidate(curriculumProvider(cohortId));
  }
}

final curriculumControllerProvider = Provider<CurriculumController>((ref) {
  return CurriculumController(ref);
});
