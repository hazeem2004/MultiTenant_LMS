class AppUser {
  final String uid;
  final String email;
  final String role; // 'instructor' or 'student'

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  bool get isInstructor => role == 'instructor';
}
