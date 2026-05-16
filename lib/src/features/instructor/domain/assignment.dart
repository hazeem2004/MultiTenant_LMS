class Assignment {
  final String id;
  final String weekId;
  final String title;
  final String descriptionText;
  final DateTime dueDate;
  final List<String> templateUrls;

  const Assignment({
    required this.id,
    required this.weekId,
    required this.title,
    required this.descriptionText,
    required this.dueDate,
    this.templateUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'weekId': weekId,
      'title': title,
      'descriptionText': descriptionText,
      'dueDate': dueDate.toIso8601String(),
      'templateUrls': templateUrls,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map, String id) {
    return Assignment(
      id: id,
      weekId: map['weekId'] as String,
      title: map['title'] as String,
      descriptionText: map['descriptionText'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      templateUrls: List<String>.from(map['templateUrls'] ?? []),
    );
  }

  Assignment copyWith({
    String? title,
    String? descriptionText,
    DateTime? dueDate,
    List<String>? templateUrls,
  }) {
    return Assignment(
      id: id,
      weekId: weekId,
      title: title ?? this.title,
      descriptionText: descriptionText ?? this.descriptionText,
      dueDate: dueDate ?? this.dueDate,
      templateUrls: templateUrls ?? this.templateUrls,
    );
  }
}
