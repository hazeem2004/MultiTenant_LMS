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

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'githubUrl': githubUrl,
      'liveDemoUrl': liveDemoUrl,
      'status': status.name,
      'instructorFeedback': instructorFeedback,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory Submission.fromMap(Map<String, dynamic> map, String id) {
    return Submission(
      id: id,
      assignmentId: map['assignmentId'] as String,
      studentId: map['studentId'] as String,
      githubUrl: map['githubUrl'] as String,
      liveDemoUrl: map['liveDemoUrl'] as String?,
      status: SubmissionStatus.values.byName(map['status'] as String),
      instructorFeedback: map['instructorFeedback'] as String?,
      submittedAt: DateTime.parse(map['submittedAt'] as String),
    );
  }

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
