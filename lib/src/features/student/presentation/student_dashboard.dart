import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../instructor/application/cohort_controller.dart';
import '../../instructor/application/curriculum_controller.dart';
import '../application/submissions_controller.dart';
import '../domain/submission.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cohortsAsync = ref.watch(cohortListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          )
        ],
      ),
      body: cohortsAsync.when(
        data: (cohorts) {
          if (cohorts.isEmpty) {
            return const Center(child: Text('No active cohorts available. Wait for an invite link.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: cohorts.length,
            itemBuilder: (context, index) {
              final cohort = cohorts[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bootcamp: ${cohort.name}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                      ),
                      const Divider(height: 32),
                      _StudentSyllabusView(cohortId: cohort.id),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StudentSyllabusView extends ConsumerWidget {
  final String cohortId;
  const _StudentSyllabusView({required this.cohortId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider(cohortId));
    final user = ref.watch(authControllerProvider).value;

    return curriculumAsync.when(
      data: (curriculum) {
        if (curriculum.weeks.isEmpty) {
          return const Text('Instructor has not posted any curriculum yet.');
        }

        return Column(
          children: curriculum.weeks.map((week) {
            final assignments = curriculum.assignmentsByWeek[week.id] ?? [];
            return ExpansionTile(
              title: Text(week.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              children: assignments.isEmpty 
                ? [const Padding(padding: EdgeInsets.all(16), child: Text('No assignments posted for this week.'))]
                : assignments.map((a) {
                    final submissionAsync = ref.watch(studentSubmissionProvider((studentId: user?.uid ?? '', assignmentId: a.id)));
                    
                    return ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),
                      title: Text(a.title),
                      subtitle: Row(
                        children: [
                          Text('Due: ${a.dueDate.toLocal().toString().split(' ')[0]}'),
                          const SizedBox(width: 8),
                          submissionAsync.when(
                            data: (sub) => _StatusBadge(status: sub?.status ?? SubmissionStatus.noSubmission),
                            loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => const Icon(Icons.error, size: 12, color: Colors.red),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showStudentAssignmentDetails(context, ref, a.id, a.title, a.descriptionText),
                    );
                  }).toList(),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading curriculum: $e'),
    );
  }

  void _showStudentAssignmentDetails(BuildContext context, WidgetRef ref, String assignmentId, String title, String markdownSource) {
    final user = ref.read(authControllerProvider).value;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 800,
          height: 600,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    FilledButton.icon(
                      onPressed: () => _showSubmitModal(context, ref, assignmentId),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Submit Assignment'),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Feedback section if exists
                      Consumer(builder: (context, ref, child) {
                        final submissionAsync = ref.watch(studentSubmissionProvider((studentId: user?.uid ?? '', assignmentId: assignmentId)));
                        return submissionAsync.when(
                          data: (sub) {
                            if (sub?.instructorFeedback == null) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                border: Border.all(color: Colors.amber),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Instructor Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  MarkdownBody(data: sub!.instructorFeedback!),
                                ],
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      }),
                      Markdown(
                        data: markdownSource,
                        padding: const EdgeInsets.all(32),
                        selectable: true,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  void _showSubmitModal(BuildContext context, WidgetRef ref, String assignmentId) {
    final githubUrlController = TextEditingController();
    final demoUrlController = TextEditingController();
    final user = ref.read(authControllerProvider).value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit Assignment', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: githubUrlController,
              decoration: const InputDecoration(
                labelText: 'GitHub Repository URL',
                hintText: 'https://github.com/user/repo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: demoUrlController,
              decoration: const InputDecoration(
                labelText: 'Live Demo URL (Optional)',
                hintText: 'https://my-demo.vercel.app',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () async {
                  if (githubUrlController.text.isNotEmpty) {
                    await ref.read(submissionsControllerProvider).submitAssignment(
                      studentId: user?.uid ?? '',
                      assignmentId: assignmentId,
                      githubUrl: githubUrlController.text,
                      liveDemoUrl: demoUrlController.text.isNotEmpty ? demoUrlController.text : null,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignment submitted successfully!')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SubmissionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case SubmissionStatus.noSubmission:
        color = Colors.grey;
        text = 'Missing';
        break;
      case SubmissionStatus.pendingGrade:
        color = Colors.blue;
        text = 'Pending';
        break;
      case SubmissionStatus.passed:
        color = Colors.green;
        text = 'Passed';
        break;
      case SubmissionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
