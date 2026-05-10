import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../instructor/application/cohort_controller.dart';
import '../../instructor/application/curriculum_controller.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For mock testing, we just grab all cohorts the mock instructor created
    // since we do not have a dedicated getCohortsForStudent relation yet.
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
                : assignments.map((a) => ListTile(
                    leading: const Icon(Icons.description, color: Colors.blue),
                    title: Text(a.title),
                    subtitle: Text('Due: ${a.dueDate.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showStudentAssignmentDetails(context, a.title, a.descriptionText),
                  )).toList(),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading curriculum: $e'),
    );
  }

  void _showStudentAssignmentDetails(BuildContext context, String title, String markdownSource) {
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
                    FilledButton(
                      onPressed: () {
                        // Assignment Upload (Sprint 4 logic)
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission portal unlocked in Sprint 4')));
                      },
                      child: const Text('Submit Assignment'),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Markdown(
                  data: markdownSource,
                  padding: const EdgeInsets.all(32),
                  selectable: true,
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
