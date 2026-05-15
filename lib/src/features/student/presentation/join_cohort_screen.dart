import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/student_cohort_controller.dart';
import '../../instructor/data/cohort_repository.dart';

class JoinCohortScreen extends ConsumerWidget {
  final String token;
  const JoinCohortScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Cohort')),
      body: FutureBuilder(
        future: ref.read(cohortRepositoryProvider).getCohortByToken(token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Invalid or expired invite link.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/student'),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            );
          }
          
          final cohort = snapshot.data!;
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.school, size: 40, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Invitation to Join',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cohort.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cohort.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () async {
                            final error = await ref.read(studentCohortsProvider.notifier).joinCohort(token);
                            if (context.mounted) {
                              if (error == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Successfully joined the cohort!')),
                                );
                                context.go('/student');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error)),
                                );
                              }
                            }
                          },
                          child: const Text('Join Cohort'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/student'),
                        child: const Text('Maybe Later'),
                      ),
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
}
