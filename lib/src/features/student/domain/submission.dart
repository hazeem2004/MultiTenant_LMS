enum SubmissionStatus {
  noSubmission,
  pendingGrade,
  passed,
  failed,
}

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String githubUrl;
  final String? liveDemoUrl;
  final SubmissionStatus status;
  final String? instructorFeedback;
  final DateTime submittedAt;

  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.githubUrl,
    this.liveDemoUrl,
    this.status = SubmissionStatus.pendingGrade,
    this.instructorFeedback,
    required this.submittedAt,
  });

  Submission copyWith({
    SubmissionStatus? status,
    String? instructorFeedback,
  }) {
    return Submission(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      githubUrl: githubUrl,
      liveDemoUrl: liveDemoUrl,
      status: status ?? this.status,
      instructorFeedback: instructorFeedback ?? this.instructorFeedback,
      submittedAt: submittedAt,
    );
  }
}
