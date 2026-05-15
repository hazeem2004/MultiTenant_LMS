import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';

class AuthRepository {
  // A mock list of users, for development without Firebase
  final List<AppUser> _dummyUsers = [
    const AppUser(uid: 'inst-1', email: 'instructor@devcohort.com', role: 'instructor'),
    const AppUser(uid: 'stud-1', email: 'student@devcohort.com', role: 'student'),
  ];

  static String _currentRole = 'instructor';

  static void setRole(String role) => _currentRole = role;

  Future<AppUser?> signInWithGitHub() async {
    await Future.delayed(const Duration(seconds: 1));
    return _dummyUsers.firstWhere((u) => u.role == _currentRole);
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
