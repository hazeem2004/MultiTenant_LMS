import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/cohort_controller.dart';
import '../../student/application/enrollments_controller.dart';
import '../application/curriculum_controller.dart';
import '../../student/application/submissions_controller.dart';
import '../../student/domain/submission.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

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
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(cohort.name),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Syllabus'),
                  Tab(text: 'Students'),
                  Tab(text: 'Review'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _SyllabusTabView(cohortId: cohort.id),
                _StudentsTabView(cohortId: cohort.id, inviteToken: cohort.inviteToken),
                _ReviewTabView(cohortId: cohort.id),
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
                            leading: const CircleAvatar(child: Icon(Icons.person)),
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

class _ReviewTabView extends ConsumerStatefulWidget {
  final String cohortId;
  const _ReviewTabView({required this.cohortId});

  @override
  _ReviewTabViewState createState() => _ReviewTabViewState();
}

class _ReviewTabViewState extends ConsumerState<_ReviewTabView> {
  String? _selectedAssignmentId;

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider(widget.cohortId));
    final enrollmentsAsync = ref.watch(enrollmentsProvider(widget.cohortId));

    return curriculumAsync.when(
      data: (curriculum) {
        final allAssignments = curriculum.assignmentsByWeek.values.expand((e) => e).toList();
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Select Assignment: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedAssignmentId,
                    hint: const Text('Choose an assignment'),
                    onChanged: (val) => setState(() => _selectedAssignmentId = val),
                    items: allAssignments.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.title),
                    )).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedAssignmentId == null)
                const Center(child: Text('Select an assignment above to view submissions.'))
              else
                Expanded(
                  child: enrollmentsAsync.when(
                    data: (enrollments) {
                      final activeStudents = enrollments.where((e) => e.status == 'active').toList();
                      if (activeStudents.isEmpty) return const Text('No active students to review.');
                      
                      return ListView.separated(
                        itemCount: activeStudents.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final student = activeStudents[index];
                          final submissionAsync = ref.watch(studentSubmissionProvider((
                            studentId: student.studentId, 
                            assignmentId: _selectedAssignmentId!
                          )));

                          return submissionAsync.when(
                            data: (submission) => _ReviewRow(
                              studentId: student.studentId,
                              submission: submission,
                              onGrade: () => _showGradeDrawer(context, ref, _selectedAssignmentId!, submission),
                            ),
                            loading: () => const ListTile(title: Text('Loading submission...')),
                            error: (e, __) => ListTile(title: Text('Error: $e')),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading students: $e'),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  void _showGradeDrawer(BuildContext context, WidgetRef ref, String assignmentId, Submission? submission) {
    if (submission == null) return;

    final feedbackCtrl = TextEditingController(text: submission.instructorFeedback ?? '');
    SubmissionStatus selectedStatus = submission.status == SubmissionStatus.noSubmission 
        ? SubmissionStatus.pendingGrade 
        : submission.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              Text('Grade Submission', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Student: ${submission.studentId}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Set Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _StatusOption(
                    status: SubmissionStatus.passed,
                    current: selectedStatus,
                    onSelected: (s) => setModalState(() => selectedStatus = s),
                  ),
                  const SizedBox(width: 8),
                  _StatusOption(
                    status: SubmissionStatus.failed,
                    current: selectedStatus,
                    onSelected: (s) => setModalState(() => selectedStatus = s),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackCtrl,
                decoration: const InputDecoration(
                  labelText: 'Feedback (Markdown supported)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(submissionsControllerProvider).gradeSubmission(
                      assignmentId: assignmentId,
                      submissionId: submission.id,
                      status: selectedStatus,
                      feedback: feedbackCtrl.text,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Grade'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String studentId;
  final Submission? submission;
  final VoidCallback onGrade;

  const _ReviewRow({
    required this.studentId,
    required this.submission,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubmission = submission != null;

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text('Student: $studentId'),
      subtitle: hasSubmission 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => launchUrl(Uri.parse(submission!.githubUrl)),
                  child: Text(submission!.githubUrl, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12)),
                ),
                if (submission!.liveDemoUrl != null)
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(submission!.liveDemoUrl!)),
                    child: Text(submission!.liveDemoUrl!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12)),
                  ),
              ],
            )
          : const Text('No submission yet', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSubmission) _StatusBadge(status: submission!.status),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            onPressed: hasSubmission ? onGrade : null,
            color: Theme.of(context).primaryColor,
          ),
        ],
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

class _StatusOption extends StatelessWidget {
  final SubmissionStatus status;
  final SubmissionStatus current;
  final Function(SubmissionStatus) onSelected;

  const _StatusOption({
    required this.status,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = status == current;
    final color = status == SubmissionStatus.passed ? Colors.green : Colors.red;

    return ChoiceChip(
      label: Text(status.name.toUpperCase()),
      selected: isSelected,
      onSelected: (val) => onSelected(status),
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
