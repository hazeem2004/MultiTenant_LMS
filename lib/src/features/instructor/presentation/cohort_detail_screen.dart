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
import '../data/cohort_repository.dart';

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
                    Text('Secure Invite Link (TTL)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Generate a secure link that expires in 24 hours.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.link),
                        label: const Text('Generate & Copy Link'),
                        onPressed: () async {
                          final token = await ref.read(cohortRepositoryProvider).generateTTLToken(cohortId);
                          final link = 'devcohort://join?token=$token';
                          await Clipboard.setData(ClipboardData(text: link));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied: $link'), behavior: SnackBarBehavior.floating)
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Permanent Token: $inviteToken', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                      
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 180,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: activeStudents.length,
                        itemBuilder: (context, index) {
                          final student = activeStudents[index];
                          final submissionAsync = ref.watch(studentSubmissionProvider((
                            studentId: student.studentId, 
                            assignmentId: _selectedAssignmentId!
                          )));

                          return submissionAsync.when(
                            data: (submission) => _ReviewCard(
                              studentId: student.studentId,
                              submission: submission,
                              onGrade: () => _showGradeDrawer(context, ref, _selectedAssignmentId!, submission),
                            ),
                            loading: () => const Card(child: Center(child: CircularProgressIndicator())),
                            error: (e, __) => Card(child: Center(child: Text('Error: $e'))),
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

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: Container(
              width: MediaQuery.of(context).size.width > 800 ? 500 : MediaQuery.of(context).size.width * 0.8,
              height: double.infinity,
              padding: const EdgeInsets.all(32),
              child: StatefulBuilder(
                builder: (ctx, setModalState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Review Submission', style: Theme.of(context).textTheme.headlineSmall),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(height: 32),
                    Text('Student ID: ${submission.studentId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Links:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    _LinkButton(label: 'GitHub Repository', url: submission.githubUrl, icon: Icons.code),
                    if (submission.liveDemoUrl != null) ...[
                      const SizedBox(height: 8),
                      _LinkButton(label: 'Live Demo', url: submission.liveDemoUrl!, icon: Icons.launch),
                    ],
                    const SizedBox(height: 32),
                    const Text('Grading:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatusOption(
                          status: SubmissionStatus.passed,
                          current: selectedStatus,
                          onSelected: (s) => setModalState(() => selectedStatus = s),
                        ),
                        const SizedBox(width: 12),
                        _StatusOption(
                          status: SubmissionStatus.failed,
                          current: selectedStatus,
                          onSelected: (s) => setModalState(() => selectedStatus = s),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Instructor Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: feedbackCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Great job! Here are some tips...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 15,
                      ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Grade saved successfully')),
                          );
                        },
                        child: const Text('Save Grade'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String studentId;
  final Submission? submission;
  final VoidCallback onGrade;

  const _ReviewCard({
    required this.studentId,
    required this.submission,
    required this.onGrade,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubmission = submission != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 16, child: Icon(Icons.person_outline, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Student $studentId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSubmission) _StatusBadge(status: submission!.status),
              ],
            ),
            const Divider(height: 24),
            if (hasSubmission) ...[
              const Text('GitHub:', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text(
                submission!.githubUrl.split('/').last,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onGrade,
                  icon: const Icon(Icons.rate_review, size: 16),
                  label: const Text('Review'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ] else ...[
              const Spacer(),
              const Center(
                child: Text(
                  'No submission yet',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  final IconData icon;
  const _LinkButton({required this.label, required this.url, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade100),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.shade50.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
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
