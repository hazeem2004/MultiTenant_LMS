import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../data/curriculum_repository.dart';
import '../domain/week.dart';
import '../domain/assignment.dart';
import '../domain/curriculum_content.dart';
import '../../auth/domain/notification.dart';
import '../../auth/data/notification_repository.dart';
import '../../student/application/enrollments_controller.dart';

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

final curriculumProvider = StreamProvider.family<CurriculumState, String>((ref, cohortId) {
  final repo = ref.read(curriculumRepositoryProvider);
  
  return repo.watchWeeksForCohort(cohortId).switchMap((weeks) {
    if (weeks.isEmpty) {
      return Stream.value(CurriculumState(
        weeks: [],
        assignmentsByWeek: {},
        quizzesByWeek: {},
        lectureNotesByWeek: {},
      ));
    }

    final weekStreams = weeks.map((week) {
      return Rx.combineLatest3(
        repo.watchAssignmentsForWeek(cohortId, week.id),
        repo.watchQuizzesForWeek(cohortId, week.id),
        repo.watchLectureNotesForWeek(cohortId, week.id),
        (assignments, quizzes, notes) => {
          'weekId': week.id,
          'assignments': assignments,
          'quizzes': quizzes,
          'notes': notes,
        },
      );
    }).toList();

    return Rx.combineLatestList(weekStreams).map((weekDataList) {
      final assignmentsMap = <String, List<Assignment>>{};
      final quizzesMap = <String, List<Quiz>>{};
      final notesMap = <String, List<LectureNote>>{};

      for (var data in weekDataList) {
        final weekId = data['weekId'] as String;
        assignmentsMap[weekId] = data['assignments'] as List<Assignment>;
        quizzesMap[weekId] = data['quizzes'] as List<Quiz>;
        notesMap[weekId] = data['notes'] as List<LectureNote>;
      }

      return CurriculumState(
        weeks: weeks,
        assignmentsByWeek: assignmentsMap,
        quizzesByWeek: quizzesMap,
        lectureNotesByWeek: notesMap,
      );
    });
  });
});

class CurriculumController {
  final Ref ref;
  CurriculumController(this.ref);

  Future<void> addWeek(String cohortId, String title) async {
    final repo = ref.read(curriculumRepositoryProvider);
    await repo.addWeek(cohortId, title);
    // No need to invalidate with Streams
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
      // Task 3: Concurrent file uploads
      templateUrls = await Future.wait(
        files.map((file) => repo.uploadContentFile(
          'assignments/$weekId/templates', 
          file['bytes'] as Uint8List, 
          file['name'] as String,
        )),
      );
    }

    // Task 2: Await only the core document creation
    await repo.addAssignment(
      cohortId: cohortId,
      weekId: weekId,
      title: title,
      descriptionText: descriptionText,
      dueDate: dueDate,
      templateUrls: templateUrls,
    );

    // Task 2: Trigger notifications in the background (fire-and-forget)
    _notifyStudents(
      cohortId: cohortId, 
      title: 'New Assignment: $title', 
      body: 'A new assignment has been posted in your cohort.',
    );
  }

  Future<void> addQuiz(String cohortId, String weekId, Quiz quiz) async {
    await ref.read(curriculumRepositoryProvider).addQuiz(cohortId: cohortId, weekId: weekId, quiz: quiz);
    _notifyStudents(
      cohortId: cohortId,
      title: 'New Quiz: ${quiz.title}',
      body: 'Test your knowledge! A new quiz is available.',
    );
  }

  Future<void> addLectureNote(String cohortId, String weekId, LectureNote note) async {
    await ref.read(curriculumRepositoryProvider).addLectureNote(cohortId: cohortId, weekId: weekId, note: note);
  }

  void _notifyStudents({required String cohortId, required String title, required String body}) {
    // Decouple heavy task from UI thread
    Future(() async {
      try {
        final enrollments = await ref.read(enrollmentsProvider(cohortId).future);
        final notifRepo = ref.read(notificationRepositoryProvider);
        
        for (var enrollment in enrollments) {
          if (enrollment.studentId.isNotEmpty) {
            await notifRepo.sendNotification(
              enrollment.studentId,
              AppNotification(
                id: '',
                title: title,
                body: body,
                timestamp: DateTime.now(),
                cohortId: cohortId,
                routeUrl: '/student/curriculum',
              ),
            );
          }
        }
      } catch (e) {
        print('Error sending background notifications: $e');
      }
    });
  }
}

final curriculumControllerProvider = Provider<CurriculumController>((ref) {
  return CurriculumController(ref);
});
