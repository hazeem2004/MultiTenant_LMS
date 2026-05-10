import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/instructor/presentation/instructor_dashboard.dart';
import '../features/student/presentation/student_dashboard.dart';

import '../features/instructor/presentation/cohort_detail_screen.dart';
import '../features/student/presentation/join_cohort_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.path == '/login';
      final isJoining = state.uri.path == '/join';

      if (!isLoggedIn) {
        // Allow unauthenticated users to hit the login page, or they might be trying to join
        if (isJoining) {
          // In a real app we'd redirect to login and then back to join,
          // For simplicity in mock, just force login if not logged in.
          return '/login'; 
        }
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn && isLoggedIn) {
        final user = authState.value!;
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
        path: '/join',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return JoinCohortScreen(token: token);
        },
      ),
    ],
  );
});
