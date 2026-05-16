import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/app_user.dart';
import '../../instructor/data/cohort_repository.dart';

class AdminController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateUserRole(String uid, String newRole) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
      });
    });
  }

  Future<void> toggleApproval(String uid, bool currentStatus) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isApproved': !currentStatus,
      });
    });
  }

  Future<void> deleteUser(String uid) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    });
  }

  Future<void> updateCohortInstructor(String cohortId, String newInstructorId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cohortRepositoryProvider).updateInstructor(cohortId, newInstructorId);
    });
  }
}

final adminControllerProvider = AsyncNotifierProvider<AdminController, void>(() {
  return AdminController();
});

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList());
});

final usersByRoleProvider = StreamProvider.family<List<AppUser>, String>((ref, role) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: role)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList());
});

final systemStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final firestore = FirebaseFirestore.instance;
  
  return firestore.collection('users').snapshots().asyncMap((snapshot) async {
    final cohortsCount = await firestore.collection('cohorts').count().get();
    
    int students = 0;
    int instructors = 0;
    
    for (var doc in snapshot.docs) {
      final role = doc.data()['role'] as String?;
      if (role == 'STUDENT') students++;
      if (role == 'INSTRUCTOR') instructors++;
    }

    return {
      'cohorts': cohortsCount.count ?? 0,
      'students': students,
      'instructors': instructors,
    };
  });
});
