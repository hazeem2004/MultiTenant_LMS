import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/cohort_controller.dart';
import '../../student/application/enrollments_controller.dart';
import '../application/curriculum_controller.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CohortDetailScreen extends ConsumerWidget {
  final String cohortId;
  const CohortDetailScreen({super.key, required this.cohortId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cohortsAsync = ref.watch(cohortListProvider);

    return cohortsAsync.when(
      data: (cohorts) {
        final cohort = cohorts.where((c) => c.id == cohortId).firstOrNull;
        if (cohort == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Cohort not found')));

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(cohort.name),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Syllabus'),
                  Tab(text: 'Students'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _SyllabusTabView(cohortId: cohort.id),
                _StudentsTabView(cohortId: cohort.id, inviteToken: cohort.inviteToken),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _SyllabusTabView extends ConsumerWidget {
  final String cohortId;
  const _SyllabusTabView({required this.cohortId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider(cohortId));

    return curriculumAsync.when(
      data: (curriculum) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Curriculum', style: Theme.of(context).textTheme.headlineSmall),
                FilledButton.icon(
                  onPressed: () => _showAddWeekDialog(context, ref, cohortId),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Week'),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (curriculum.weeks.isEmpty)
              const Center(child: Text('No weeks added yet. Start building your curriculum!')),
            ...curriculum.weeks.map((week) {
              final assignments = curriculum.assignmentsByWeek[week.id] ?? [];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(week.title, style: Theme.of(context).textTheme.titleLarge),
                          TextButton.icon(
                            onPressed: () => _showAddAssignmentDialog(context, ref, cohortId, week.id),
                            icon: const Icon(Icons.add_task),
                            label: const Text('Add Assignment'),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (assignments.isEmpty)
                        const Text('No assignments yet.', style: TextStyle(fontStyle: FontStyle.italic)),
                      ...assignments.map((a) => ListTile(
                        leading: const Icon(Icons.assignment),
                        title: Text(a.title),
                        subtitle: Text('Due: ${a.dueDate.toLocal().toString().split(' ')[0]}'),
                        onTap: () => _showAssignmentDetails(context, a.title, a.descriptionText),
                      ))
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddWeekDialog(BuildContext context, WidgetRef ref, String cohortId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Week'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Week Title (e.g., Week 1)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ref.read(curriculumControllerProvider).addWeek(cohortId, ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      )
    );
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref, String cohortId, String weekId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController(); 
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Assignment'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Assignment Title')),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Markdown Instructions'),
                maxLines: 10,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                ref.read(curriculumControllerProvider).addAssignment(
                  cohortId,
                  weekId, 
                  titleCtrl.text, 
                  descCtrl.text, 
                  DateTime.now().add(const Duration(days: 7)) 
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          )
        ],
      )
    );
  }

  void _showAssignmentDetails(BuildContext context, String title, String markdownSource) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 600,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
                ],
              ),
              const Divider(),
              Expanded(
                child: Markdown(data: markdownSource),
              ),
            ],
          ),
        ),
      )
    );
  }
}

class _StudentsTabView extends ConsumerWidget {
  final String cohortId;
  final String inviteToken;
  const _StudentsTabView({required this.cohortId, required this.inviteToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(enrollmentsProvider(cohortId));
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invite Link
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invite Link', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: SelectableText('http://localhost:8085/join?token=$inviteToken', style: const TextStyle(fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: 'http://localhost:8085/join?token=$inviteToken'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Enrollments
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Students', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: enrollmentsAsync.when(
                    data: (enrollments) {
                      if (enrollments.isEmpty) return const Text('No students enrolled yet.');
                      return ListView.separated(
                        itemCount: enrollments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final enrollment = enrollments[index];
                          final isPending = enrollment.status == 'pending';
                          return ListTile(
                            leading: CircleAvatar(child: const Icon(Icons.person)),
                            title: Text('Student ID: ${enrollment.studentId}'),
                            subtitle: Text('Status: ${enrollment.status.toUpperCase()}'),
                            trailing: isPending
                                ? FilledButton(
                                    onPressed: () {
                                      ref.read(enrollmentsControllerProvider)
                                         .approveStudent(cohortId, enrollment.id);
                                    },
                                    child: const Text('Approve'),
                                  )
                                : const Icon(Icons.check_circle, color: Colors.green),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading enrollments: $e'),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
