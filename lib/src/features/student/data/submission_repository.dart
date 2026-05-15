import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/submission.dart';

class SubmissionRepository {
  // Mock data: In-memory store of submissions
  final List<Submission> _submissions = [];

  Future<List<Submission>> getSubmissionsForAssignment(String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _submissions.where((s) => s.assignmentId == assignmentId).toList();
  }

  Future<Submission?> getStudentSubmission(String studentId, String assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _submissions.firstWhere(
        (s) => s.studentId == studentId && s.assignmentId == assignmentId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> submitAssignment(Submission submission) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Remove existing if any (resubmit)
    _submissions.removeWhere(
      (s) => s.studentId == submission.studentId && s.assignmentId == submission.assignmentId,
    );
    _submissions.add(submission);
  }

  Future<void> gradeSubmission(String submissionId, SubmissionStatus status, String feedback) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _submissions.indexWhere((s) => s.id == submissionId);
    if (index != -1) {
      _submissions[index] = _submissions[index].copyWith(
        status: status,
        instructorFeedback: feedback,
      );
    }
  }
}

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository();
});
