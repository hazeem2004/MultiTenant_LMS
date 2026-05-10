import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_controller.dart';
import '../data/enrollment_repository.dart';
import '../../instructor/data/cohort_repository.dart';

class JoinCohortScreen extends ConsumerWidget {
  final String token;
  const JoinCohortScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Cohort')),
      body: FutureBuilder(
        future: _findCohortByToken(ref, token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Invalid or expired invite link.'));
          }
          
          final cohortId = snapshot.data!;
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, size: 64),
                      const SizedBox(height: 16),
                      Text('You have been invited to join a cohort.',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () async {
                          final user = ref.read(authControllerProvider).value;
                          if (user != null) {
                            await ref.read(enrollmentRepositoryProvider).enrollStudent(user.uid, cohortId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrollment submitted! Waiting for instructor approval.')));
                              context.go('/student');
                            }
                          }
                        },
                        child: const Text('Accept Invitation'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper just for the mock data demonstration
  Future<String?> _findCohortByToken(WidgetRef ref, String token) async {
    // In a real app with Firebase, we would query `cohorts` collection where `inviteToken == token`.
    // Since we're using a mocked repository locally, and we only exposed 'fetchCohortsForInstructor',
    // I will mock this tightly. If the token is 'TEST', return a dummy ID, else we would need a list of all cohorts.
    // For this Mock phase, we'll pretend the token is valid for 'cohort-1'.
    await Future.delayed(const Duration(milliseconds: 500));
    return 'cohort-1'; // Fake return just to permit the flow.
  }
}
