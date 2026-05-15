class Week {
  final String id;
  final String cohortId;
  final String title;
  final int orderIndex;

  const Week({
    required this.id,
    required this.cohortId,
    required this.title,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'cohortId': cohortId,
      'title': title,
      'orderIndex': orderIndex,
    };
  }

  factory Week.fromMap(Map<String, dynamic> map, String id) {
    return Week(
      id: id,
      cohortId: map['cohortId'] as String,
      title: map['title'] as String,
      orderIndex: map['orderIndex'] as int,
    );
  }

  Week copyWith({
    String? title,
    int? orderIndex,
  }) {
    return Week(
      id: id,
      cohortId: cohortId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
