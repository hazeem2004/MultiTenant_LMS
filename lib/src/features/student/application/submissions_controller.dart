import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/submission_repository.dart';
import '../domain/submission.dart';

// Provider to fetch a single submission for a student/assignment (Real-time)
final studentSubmissionProvider = StreamProvider.family<Submission?, ({String studentId, String assignmentId})>((ref, arg) {
  return ref.watch(submissionRepositoryProvider).watchStudentSubmission(arg.studentId, arg.assignmentId);
});

// Provider to fetch all submissions for an assignment (Instructor View - Real-time)
final assignmentSubmissionsProvider = StreamProvider.family<List<Submission>, String>((ref, assignmentId) {
  return ref.watch(submissionRepositoryProvider).watchSubmissionsForAssignment(assignmentId);
});

class SubmissionsController {
  final Ref ref;
  SubmissionsController(this.ref);

  Future<void> submitAssignment({
    required String studentId,
    required String assignmentId,
    required String githubUrl,
    String? liveDemoUrl,
  }) async {
    final submission = Submission(
      id: '', // Firestore will generate an ID if we use add(), or we can use a custom logic
      assignmentId: assignmentId,
      studentId: studentId,
      githubUrl: githubUrl,
      liveDemoUrl: liveDemoUrl,
      submittedAt: DateTime.now(),
    );
    await ref.read(submissionRepositoryProvider).submitAssignment(submission);
  }

  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required SubmissionStatus status,
    required String feedback,
  }) async {
    await ref.read(submissionRepositoryProvider).gradeSubmission(submissionId, status, feedback);
  }
}

final submissionsControllerProvider = Provider<SubmissionsController>((ref) {
  return SubmissionsController(ref);
});
