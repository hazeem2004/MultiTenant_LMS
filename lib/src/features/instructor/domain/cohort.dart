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

  factory Cohort.fromMap(String id, Map<String, dynamic> map) {
    return Cohort(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      instructorId: map['instructorId'] as String,
      inviteToken: map['inviteToken'] as String,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
