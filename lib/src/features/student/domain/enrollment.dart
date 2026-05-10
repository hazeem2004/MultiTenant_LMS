class Enrollment {
  final String id;
  final String cohortId;
  final String studentId;
  final String status; // 'pending' or 'active'

  const Enrollment({
    required this.id,
    required this.cohortId,
    required this.studentId,
    required this.status,
  });

  Enrollment copyWith({
    String? status,
  }) {
    return Enrollment(
      id: id,
      cohortId: cohortId,
      studentId: studentId,
      status: status ?? this.status,
    );
  }
}
