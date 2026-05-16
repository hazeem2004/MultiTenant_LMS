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
      cohortId: map['cohortId']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unnamed Week',
      orderIndex: map['orderIndex'] is int ? map['orderIndex'] as int : 0,
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
