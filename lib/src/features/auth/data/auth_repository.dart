import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';

class AuthRepository {
  // A mock list of users, for development without Firebase
  final List<AppUser> _dummyUsers = [
    const AppUser(uid: 'inst-1', email: 'instructor@devcohort.com', role: 'instructor'),
    const AppUser(uid: 'stud-1', email: 'student@devcohort.com', role: 'student'),
  ];

  Future<AppUser?> signInWithGitHub() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // For now, always return the instructor mock for testing the dashboard.
    // In actual implementation, this will use firebase_auth's signInWithProvider
    return _dummyUsers.first; // Return the dummy instructor
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
