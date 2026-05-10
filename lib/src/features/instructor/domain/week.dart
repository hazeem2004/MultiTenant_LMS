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
