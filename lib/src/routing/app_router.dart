import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/pending_approval_screen.dart';
import '../features/instructor/presentation/instructor_dashboard.dart';
import '../features/student/presentation/student_dashboard.dart';

import '../features/instructor/presentation/cohort_detail_screen.dart';
import '../features/admin/presentation/admin_dashboard.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null; // Wait for auth state to load

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';
      final isPending = state.uri.path == '/pending';
      final isJoining = state.uri.path == '/join';

      if (!isLoggedIn) {
        if (isJoining || isRegistering) return null; // Allow joining or registering
        return isLoggingIn ? null : '/login';
      }

      final user = authState.value!;

      // Handle Approval Logic - Admins bypass this check
      if (!user.isApproved && !user.isAdmin) {
        return isPending ? null : '/pending';
      }

      // If approved but trying to hit pending, redirect to dashboard
      if (isPending) {
        if (user.isAdmin) return '/admin';
        return user.isInstructor ? '/instructor' : '/student';
      }

      if ((isLoggingIn || isRegistering) && isLoggedIn) {
        if (user.isAdmin) return '/admin';
        return user.isInstructor ? '/instructor' : '/student';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/instructor',
        builder: (context, state) => const InstructorDashboard(),
        routes: [
          GoRoute(
            path: 'cohort/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CohortDetailScreen(cohortId: id);
            },
          ),
        ]
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});

