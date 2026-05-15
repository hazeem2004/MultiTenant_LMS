import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/submission_repository.dart';
import '../domain/submission.dart';

// Provider to fetch a single submission for a student/assignment
final studentSubmissionProvider = FutureProvider.family<Submission?, ({String studentId, String assignmentId})>((ref, arg) {
  return ref.watch(submissionRepositoryProvider).getStudentSubmission(arg.studentId, arg.assignmentId);
});

// Provider to fetch all submissions for an assignment (Instructor View)
final assignmentSubmissionsProvider = FutureProvider.family<List<Submission>, String>((ref, assignmentId) {
  return ref.watch(submissionRepositoryProvider).getSubmissionsForAssignment(assignmentId);
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      assignmentId: assignmentId,
      studentId: studentId,
      githubUrl: githubUrl,
      liveDemoUrl: liveDemoUrl,
      submittedAt: DateTime.now(),
    );
    await ref.read(submissionRepositoryProvider).submitAssignment(submission);
    
    // Invalidate providers to refresh UI
    ref.invalidate(studentSubmissionProvider);
    ref.invalidate(assignmentSubmissionsProvider(assignmentId));
  }

  Future<void> gradeSubmission({
    required String assignmentId,
    required String submissionId,
    required SubmissionStatus status,
    required String feedback,
  }) async {
    await ref.read(submissionRepositoryProvider).gradeSubmission(submissionId, status, feedback);
    
    // Invalidate providers to refresh UI
    ref.invalidate(studentSubmissionProvider);
    ref.invalidate(assignmentSubmissionsProvider(assignmentId));
  }
}

final submissionsControllerProvider = Provider<SubmissionsController>((ref) {
  return SubmissionsController(ref);
});
