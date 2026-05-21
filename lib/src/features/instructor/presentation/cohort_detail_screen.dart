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
import '../domain/assignment.dart';
import '../domain/cohort.dart';
import '../data/cohort_repository.dart';
import '../domain/curriculum_content.dart';
import '../../auth/domain/notification.dart';
import '../../auth/data/notification_repository.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../data/attendance_repository.dart';
import 'instructor_analytics_screen.dart';
import 'overall_attendance_screen.dart';

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
          length: 5,
          child: Scaffold(
            appBar: AppBar(
              title: Text(cohort.name),
              actions: [
                IconButton(
                  tooltip: 'Analytics',
                  icon: const Icon(Icons.analytics_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InstructorAnalyticsScreen(cohortId: cohort.id)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Syllabus'),
                  Tab(text: 'Students'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Review'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _SyllabusTabView(cohortId: cohort.id),
                _StudentsTabView(cohortId: cohort.id, classCode: cohort.classCode),
                _AttendanceTabView(cohortId: cohort.id),
                _ReviewTabView(cohortId: cohort.id),
                _SettingsTabView(cohort: cohort),
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 600;
                          final actionWrap = Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showAddAssignmentDialog(context, ref, cohortId, week.id),
                                icon: const Icon(Icons.assignment_add, size: 16),
                                label: const Text('Assignment', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: const Size(48, 36),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showAddQuizDialog(context, ref, cohortId, week.id),
                                icon: const Icon(Icons.quiz, size: 16),
                                label: const Text('Quiz', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: const Size(48, 36),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showAddLectureNoteDialog(context, ref, cohortId, week.id),
                                icon: const Icon(Icons.description, size: 16),
                                label: const Text('Note', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: const Size(48, 36),
                                ),
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(week.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                actionWrap,
                              ],
                            );
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(week.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              actionWrap,
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 16),
                      if (assignments.isEmpty && (curriculum.quizzesByWeek[week.id]?.isEmpty ?? true) && (curriculum.lectureNotesByWeek[week.id]?.isEmpty ?? true))
                        const Text('No content yet.', style: TextStyle(fontStyle: FontStyle.italic)),
                      
                      // Assignments
                      ...assignments.map((a) => ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.blue),
                        title: Text(a.title),
                        subtitle: Text('Due: ${a.dueDate.toLocal().toString().split(' ')[0]}'),
                        onTap: () => _showAssignmentDetails(context, a),
                        trailing: a.templateUrls.isNotEmpty ? const Icon(Icons.attach_file, size: 16) : null,
                      )),
                      
                      // Quizzes
                      ...(curriculum.quizzesByWeek[week.id] ?? []).map((q) => ListTile(
                        leading: const Icon(Icons.quiz, color: Colors.orange),
                        title: Text(q.title),
                        subtitle: Text('Due: ${q.dueDate.toLocal().toString().split(' ')[0]}'),
                        onTap: () {}, // TODO: Show Quiz Details
                      )),
                      
                      // Lecture Notes
                      ...(curriculum.lectureNotesByWeek[week.id] ?? []).map((n) => ListTile(
                        leading: const Icon(Icons.description, color: Colors.green),
                        title: Text(n.title),
                        subtitle: const Text('Lecture Notes'),
                        onTap: () {}, // TODO: Show Note Details
                        trailing: n.pdfUrls.isNotEmpty ? const Icon(Icons.picture_as_pdf, size: 16) : null,
                      )),
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
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));
    List<fp.PlatformFile> selectedFiles = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Add Assignment'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Assignment Title', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Markdown Instructions', border: OutlineInputBorder()),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Deadline'),
                    subtitle: Text(selectedDeadline.toString().split('.')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDeadline,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDeadline),
                        );
                        if (time != null) {
                          setModalState(() => selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Templates: ${selectedFiles.length} attached', style: const TextStyle(fontSize: 12)),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await fp.FilePicker.pickFiles(allowMultiple: true);
                          if (result != null) {
                            setModalState(() => selectedFiles = result.files);
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach Files'),
                      ),
                    ],
                  ),
                  if (selectedFiles.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: selectedFiles.map((f) => Chip(
                          label: Text(f.name, style: const TextStyle(fontSize: 10)),
                          onDeleted: () => setModalState(() => selectedFiles.remove(f)),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty) {
                  final filesData = selectedFiles.map((f) => {
                    'name': f.name,
                    'bytes': f.bytes ?? Uint8List(0),
                  }).toList();

                  await ref.read(curriculumControllerProvider).addAssignment(
                    cohortId: cohortId,
                    weekId: weekId,
                    title: titleCtrl.text,
                    descriptionText: descCtrl.text,
                    dueDate: selectedDeadline,
                    files: filesData,
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignment created successfully!')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }

  void _showAddQuizDialog(BuildContext context, WidgetRef ref, String cohortId, String weekId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Add Quiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
              const SizedBox(height: 16),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Deadline'),
                subtitle: Text(selectedDeadline.toString().split('.')[0]),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: selectedDeadline, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedDeadline));
                    if (time != null) setModalState(() => selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty) {
                  await ref.read(curriculumControllerProvider).addQuiz(
                    cohortId,
                    weekId,
                    Quiz(
                      id: '',
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      dueDate: selectedDeadline,
                      questions: [], // Empty for now
                    ),
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quiz created successfully!')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }

  void _showAddLectureNoteDialog(BuildContext context, WidgetRef ref, String cohortId, String weekId) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Lecture Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Note Title')),
            const SizedBox(height: 16),
            TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Markdown Content'), maxLines: 5),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                await ref.read(curriculumControllerProvider).addLectureNote(
                  cohortId,
                  weekId,
                  LectureNote(id: '', title: titleCtrl.text, contentMarkdown: contentCtrl.text, pdfUrls: []),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          )
        ],
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, Assignment a) {
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
                  Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
                ],
              ),
              const Divider(),
              Expanded(
                child: Markdown(data: a.descriptionText),
              ),
              if (a.templateUrls.isNotEmpty) ...[
                const Divider(),
                const Text('Templates:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: a.templateUrls.map((url) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.file_download, size: 16),
                        label: const Text('Download Template'),
                        onPressed: () => launchUrl(Uri.parse(url)),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      )
    );
  }
}

class _StudentsTabView extends ConsumerWidget {
  final String cohortId;
  final String classCode;
  const _StudentsTabView({required this.cohortId, required this.classCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(enrollmentsProvider(cohortId));
    final isMobile = MediaQuery.of(context).size.width < 650;
    
    final classCodePanel = Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_2, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Class Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              classCode,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this code with your students so they can join this cohort from their dashboard.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: classCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Code'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );

    final enrollmentsList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enrolled Students', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        enrollmentsAsync.when(
          data: (enrollments) {
            if (enrollments.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('No students enrolled yet.')));
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enrollments.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final enrollment = enrollments[index];
                final isPending = enrollment.status == 'pending';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text('Student ID: ${enrollment.studentId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${enrollment.status.toUpperCase()}', style: TextStyle(color: isPending ? Colors.amber.shade700 : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  trailing: isPending
                      ? FilledButton(
                          onPressed: () {
                            ref.read(enrollmentsControllerProvider)
                               .approveStudent(cohortId, enrollment.id);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(60, 36),
                          ),
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
      ],
    );

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            classCodePanel,
            const SizedBox(height: 32),
            enrollmentsList,
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(child: classCodePanel),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(child: enrollmentsList),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Review Submission', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Student ID:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                            Text(submission.studentId, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            const Text('Links:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _LinkButton(label: 'GitHub Repository', url: submission.githubUrl, icon: Icons.code),
                            if (submission.liveDemoUrl != null) ...[
                              const SizedBox(height: 8),
                              _LinkButton(label: 'Live Demo', url: submission.liveDemoUrl!, icon: Icons.launch),
                            ],
                            if (submission.fileUrls.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text('Attachments:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...submission.fileUrls.map((url) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _LinkButton(
                                  label: 'Download File', 
                                  url: url, 
                                  icon: Icons.file_download,
                                ),
                              )),
                            ],
                            const SizedBox(height: 24),
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
                            TextField(
                              controller: feedbackCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Great job! Here are some tips...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 8,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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

final attendanceProvider = FutureProvider.family<Map<String, String>, ({String cohortId, String date})>((ref, arg) {
  return ref.read(attendanceRepositoryProvider).getAttendance(arg.cohortId, arg.date);
});

class _AttendanceTabView extends ConsumerStatefulWidget {
  final String cohortId;
  const _AttendanceTabView({required this.cohortId});

  @override
  _AttendanceTabViewState createState() => _AttendanceTabViewState();
}

class _AttendanceTabViewState extends ConsumerState<_AttendanceTabView> {
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _currentStatus = {};

  String _formatDate(DateTime date) => "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync = ref.watch(enrollmentsProvider(widget.cohortId));
    final dateKey = _formatDate(_selectedDate);
    final savedAttendanceAsync = ref.watch(attendanceProvider((cohortId: widget.cohortId, date: dateKey)));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                
                final datePickerRow = Row(
                  children: [
                    Text('Date: $dateKey', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                  ],
                );

                final actionButtons = [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OverallAttendanceScreen(cohortId: widget.cohortId)),
                    ),
                    icon: const Icon(Icons.grid_view),
                    label: const Text('Overall Matrix'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(140, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await ref.read(attendanceRepositoryProvider).saveAttendance(
                        cohortId: widget.cohortId,
                        date: dateKey,
                        statusMap: _currentStatus,
                      );
                      ref.invalidate(attendanceProvider);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved')));
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Record'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      datePickerRow,
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: actionButtons.whereType<Widget>().toList(),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    datePickerRow,
                    const Spacer(),
                    ...actionButtons,
                  ],
                );
              }
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: enrollmentsAsync.when(
              data: (enrollments) {
                final activeStudents = enrollments.where((e) => e.status == 'active').toList();
                if (activeStudents.isEmpty) return const Center(child: Text('No active students to track.'));

                return savedAttendanceAsync.when(
                  data: (saved) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: activeStudents.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final student = activeStudents[index];
                        final studentId = student.studentId;
                        final currentVal = _currentStatus[studentId] ?? saved[studentId] ?? 'present';

                        return ListTile(
                          title: Text('Student ID: $studentId'),
                          trailing: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'present', label: Text('P'), tooltip: 'Present'),
                              ButtonSegment(value: 'absent', label: Text('A'), tooltip: 'Absent'),
                              ButtonSegment(value: 'late', label: Text('L'), tooltip: 'Late'),
                            ],
                            selected: {currentVal},
                            onSelectionChanged: (val) {
                              setState(() => _currentStatus[studentId] = val.first);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Center(child: Text('Error loading record: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabView extends ConsumerWidget {
  final Cohort cohort;
  const _SettingsTabView({required this.cohort});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cohort Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Join Code Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('Current Code: ${cohort.classCode}', style: const TextStyle(fontSize: 18, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _confirmRegenerate(context, ref),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Regenerate Code'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _setExpiry(context, ref),
                        icon: const Icon(Icons.timer_outlined),
                        label: const Text('Set Expiry'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              title: const Text('Danger Zone', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: const Text('Deleting this cohort will remove all curriculum and student associations.'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Delete Cohort', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRegenerate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate Code?'),
        content: const Text('Existing students will stay enrolled, but the old code will immediately stop working for new students.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(cohortRepositoryProvider).regenerateClassCode(cohort.id);
              ref.invalidate(cohortListProvider);
              Navigator.pop(ctx);
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _setExpiry(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(cohortRepositoryProvider).updateCodeExpiry(cohort.id, picked);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code will expire on ${picked.toLocal()}')));
    }
  }
}
