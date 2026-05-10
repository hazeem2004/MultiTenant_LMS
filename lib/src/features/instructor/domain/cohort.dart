class Cohort {
  final String id;
  final String name;
  final String description;
  final String instructorId;
  final String inviteToken;
  final DateTime createdAt;

  const Cohort({
    required this.id,
    required this.name,
    required this.description,
    required this.instructorId,
    required this.inviteToken,
    required this.createdAt,
  });

  Cohort copyWith({
    String? name,
    String? description,
  }) {
    return Cohort(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      instructorId: instructorId,
      inviteToken: inviteToken,
      createdAt: createdAt,
    );
  }
}
