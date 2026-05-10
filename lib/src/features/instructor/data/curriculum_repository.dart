import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/week.dart';
import '../domain/assignment.dart';

class CurriculumRepository {
  final List<Week> _weeks = [];
  final List<Assignment> _assignments = [];

  Future<List<Week>> getWeeksForCohort(String cohortId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cohortWeeks = _weeks.where((w) => w.cohortId == cohortId).toList();
    cohortWeeks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return cohortWeeks;
  }

  Future<List<Assignment>> getAssignmentsForWeek(String weekId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _assignments.where((a) => a.weekId == weekId).toList();
  }

  Future<Week> addWeek(String cohortId, String title) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existingWeeks = await getWeeksForCohort(cohortId);
    final nextOrder = existingWeeks.isEmpty ? 1 : existingWeeks.last.orderIndex + 1;
    
    final newWeek = Week(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cohortId: cohortId,
      title: title,
      orderIndex: nextOrder,
    );
    _weeks.add(newWeek);
    return newWeek;
  }

  Future<Assignment> addAssignment(String weekId, String title, String descriptionText, DateTime dueDate) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newAssignment = Assignment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weekId: weekId,
      title: title,
      descriptionText: descriptionText,
      dueDate: dueDate,
    );
    _assignments.add(newAssignment);
    return newAssignment;
  }
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository();
});
