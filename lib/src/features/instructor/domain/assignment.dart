class Assignment {
  final String id;
  final String weekId;
  final String title;
  final String descriptionText;
  final DateTime dueDate;

  const Assignment({
    required this.id,
    required this.weekId,
    required this.title,
    required this.descriptionText,
    required this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekId': weekId,
      'title': title,
      'descriptionText': descriptionText,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map, String id) {
    return Assignment(
      id: id,
      weekId: map['weekId'] as String,
      title: map['title'] as String,
      descriptionText: map['descriptionText'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
    );
  }

  Assignment copyWith({
    String? title,
    String? descriptionText,
    DateTime? dueDate,
  }) {
    return Assignment(
      id: id,
      weekId: weekId,
      title: title ?? this.title,
      descriptionText: descriptionText ?? this.descriptionText,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
