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

// Provider to fetch all submissions for a specific student (Real-time)
final studentAllSubmissionsProvider = StreamProvider.family<List<Submission>, String>((ref, studentId) {
  return ref.watch(submissionRepositoryProvider).watchStudentSubmissions(studentId);
});

class SubmissionsController {
  final Ref ref;
  SubmissionsController(this.ref);

  Future<void> submitAssignment({
    required String studentId,
    required String assignmentId,
    required String githubUrl,
    String? liveDemoUrl,
    List<Map<String, dynamic>>? files, // {name: String, bytes: Uint8List}
  }) async {
    final repo = ref.read(submissionRepositoryProvider);
    
    // 1. Check for existing submission to handle re-submission
    final existing = await repo.getStudentSubmission(studentId, assignmentId);
    
    // 2. Upload files if provided
    List<String> fileUrls = existing?.fileUrls ?? [];
    if (files != null && files.isNotEmpty) {
      // Overwrite previous files if re-submitting
      if (existing != null) {
        await repo.deleteSubmissionFiles(studentId, assignmentId);
        fileUrls = [];
      }
      
      for (var file in files) {
        final url = await repo.uploadSubmissionFile(
          studentId, 
          assignmentId, 
          file['name'] as String, 
          file['bytes'] as Uint8List
        );
        fileUrls.add(url);
      }
    }

    final submission = Submission(
      id: existing?.id ?? '', 
      assignmentId: assignmentId,
      studentId: studentId,
      githubUrl: githubUrl,
      liveDemoUrl: liveDemoUrl,
      submittedAt: DateTime.now(),
      status: SubmissionStatus.pendingGrade,
      fileUrls: fileUrls,
    );
    
    await repo.submitAssignment(submission);
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
