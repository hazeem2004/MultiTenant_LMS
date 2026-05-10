import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cohort.dart';

class CohortRepository {
  final List<Cohort> _cohorts = [];

  Future<List<Cohort>> fetchCohortsForInstructor(String instructorId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _cohorts.where((c) => c.instructorId == instructorId).toList();
  }

  Future<Cohort> createCohort(String name, String description, String instructorId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newCohort = Cohort(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      instructorId: instructorId,
      inviteToken: _generateToken(),
      createdAt: DateTime.now(),
    );
    
    _cohorts.add(newCohort);
    return newCohort;
  }

  Future<void> updateCohort(Cohort updatedCohort) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _cohorts.indexWhere((c) => c.id == updatedCohort.id);
    if (index != -1) {
      _cohorts[index] = updatedCohort;
    }
  }

  Future<void> deleteCohort(String cohortId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cohorts.removeWhere((c) => c.id == cohortId);
  }

  String _generateToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}

final cohortRepositoryProvider = Provider<CohortRepository>((ref) {
  return CohortRepository();
});
