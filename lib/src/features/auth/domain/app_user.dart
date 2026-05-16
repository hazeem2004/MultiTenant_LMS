class AppUser {
  final String uid;
  final String email;
  final String role; // 'INSTRUCTOR', 'STUDENT', or 'ADMIN'
  final bool isApproved;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.isApproved = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'STUDENT',
      isApproved: map['isApproved'] as bool? ?? false,
    );
  }

  bool get isInstructor => role == 'INSTRUCTOR' || role == 'instructor';
  bool get isAdmin => role == 'ADMIN';
  bool get isStudent => role == 'STUDENT' || role == 'student';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
