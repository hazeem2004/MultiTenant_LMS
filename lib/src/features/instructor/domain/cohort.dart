class Cohort {
  final String id;
  final String name;
  final String description;
  final String instructorId;
  final String classCode;
  final DateTime createdAt;

  const Cohort({
    required this.id,
    required this.name,
    required this.description,
    required this.instructorId,
    required this.classCode,
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
      classCode: classCode,
      createdAt: createdAt,
    );
  }

  factory Cohort.fromMap(String id, Map<String, dynamic> map) {
    return Cohort(
      id: id,
      name: map['name']?.toString() ?? 'Unnamed Cohort',
      description: map['description']?.toString() ?? '',
      instructorId: map['instructorId']?.toString() ?? '',
      classCode: map['classCode']?.toString() ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return (value as dynamic).toDate();
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cohort && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

