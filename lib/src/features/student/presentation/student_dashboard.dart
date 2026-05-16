import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../../instructor/application/curriculum_controller.dart';
import '../../instructor/domain/cohort.dart';
import '../application/student_cohort_controller.dart';
import '../application/submissions_controller.dart';
import '../domain/submission.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'join_cohort_dialog.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cohortsAsync = ref.watch(studentCohortsProvider);
    final selectedCohort = ref.watch(selectedCohortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          if (cohortsAsync.value?.isNotEmpty ?? false)
            _CohortSwitcher(
              cohorts: cohortsAsync.value!,
              selectedCohort: selectedCohort,
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const JoinCohortDialog(),
        ),
        label: const Text('Join a Class'),
        icon: const Icon(Icons.add),
      ),
      body: cohortsAsync.when(
        data: (cohorts) {
          if (cohorts.isEmpty) {
            return _EmptyStateView();
          }
          
          if (selectedCohort == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _CohortCurriculumView(cohort: selectedCohort);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CohortSwitcher extends ConsumerWidget {
  final List<Cohort> cohorts;
  final Cohort? selectedCohort;

  const _CohortSwitcher({
    required this.cohorts,
    required this.selectedCohort,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Cohort>(
          value: selectedCohort,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: cohorts.map((c) => DropdownMenuItem(
            value: c,
            child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          )).toList(),
          onChanged: (cohort) {
            if (cohort != null) {
              ref.read(selectedCohortProvider.notifier).setCohort(cohort);
            }
          },
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'Welcome to DevCohort!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'You are not enrolled in any bootcamps yet. Click the button below to join a class with a code.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const JoinCohortDialog(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Join Your First Class'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CohortCurriculumView extends ConsumerWidget {
  final Cohort cohort;
  const _CohortCurriculumView({required this.cohort});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider(cohort.id));
    final user = ref.watch(authControllerProvider).value;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(curriculumProvider(cohort.id).future),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            cohort.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            cohort.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          curriculumAsync.when(
            data: (curriculum) {
              if (curriculum.weeks.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Curriculum is being prepared. Check back soon!', textAlign: TextAlign.center),
                  ),
                );
              }

              return Column(
                children: curriculum.weeks.map((week) {
                  final assignments = curriculum.assignmentsByWeek[week.id] ?? [];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          child: Text('${week.orderIndex}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                        ),
                        title: Text(week.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${assignments.length} assignments'),
                        children: assignments.isEmpty 
                          ? [const Padding(padding: EdgeInsets.all(16), child: Text('No assignments posted for this week.'))]
                          : assignments.map((a) {
                              final submissionAsync = ref.watch(studentSubmissionProvider((studentId: user?.uid ?? '', assignmentId: a.id)));
                              
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                leading: const Icon(Icons.assignment_outlined),
                                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Wrap(
                                  spacing: 12,
                                  children: [
                                    Text('Due: ${a.dueDate.toLocal().toString().split(' ')[0]}'),
                                    submissionAsync.when(
                                      data: (sub) => _StatusBadge(status: sub?.status ?? SubmissionStatus.noSubmission),
                                      loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                      error: (_, __) => const Icon(Icons.error, size: 12, color: Colors.red),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _showStudentAssignmentDetails(context, ref, a.id, a.title, a.descriptionText),
                              );
                            }).toList(),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error loading curriculum: $e'),
          ),
        ],
      ),
    );
  }

  void _showStudentAssignmentDetails(BuildContext context, WidgetRef ref, String assignmentId, String title, String markdownSource) {
    final user = ref.read(authControllerProvider).value;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _showSubmitModal(context, ref, assignmentId),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Submit'),
                ),
              )
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(builder: (context, ref, child) {
                  final submissionAsync = ref.watch(studentSubmissionProvider((studentId: user?.uid ?? '', assignmentId: assignmentId)));
                  return submissionAsync.when(
                    data: (sub) {
                      if (sub?.instructorFeedback == null) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.primaryContainer),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.feedback, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Text('Instructor Feedback', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MarkdownBody(data: sub!.instructorFeedback!),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: MarkdownBody(
                    data: markdownSource,
                    selectable: true,
                  ),
                ),
              ],
            ),
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
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit Assignment', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: githubUrlController,
              decoration: const InputDecoration(
                labelText: 'GitHub Repository URL',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: demoUrlController,
              decoration: const InputDecoration(
                labelText: 'Live Demo URL (Optional)',
                prefixIcon: Icon(Icons.rocket_launch),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () async {
                  if (githubUrlController.text.isNotEmpty) {
                    await ref.read(submissionsControllerProvider).submitAssignment(
                      studentId: user?.uid ?? '',
                      assignmentId: assignmentId,
                      githubUrl: githubUrlController.text,
                      liveDemoUrl: demoUrlController.text.isNotEmpty ? demoUrlController.text : null,
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Assignment submitted successfully!')),
                      );
                    }
                  }
                },
                child: const Text('Submit Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
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
    IconData icon;
    
    switch (status) {
      case SubmissionStatus.noSubmission:
        color = Colors.grey;
        text = 'Missing';
        icon = Icons.pending_actions;
        break;
      case SubmissionStatus.pendingGrade:
        color = Colors.blue;
        text = 'Reviewing';
        icon = Icons.access_time;
        break;
      case SubmissionStatus.passed:
        color = Colors.green;
        text = 'Passed';
        icon = Icons.check_circle;
        break;
      case SubmissionStatus.failed:
        color = Colors.red;
        text = 'Re-submit';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
