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
