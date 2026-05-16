import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/application/auth_controller.dart';
import '../../instructor/data/attendance_repository.dart';
import '../../instructor/domain/curriculum_content.dart';
import '../../instructor/data/cohort_repository.dart';
import '../application/student_cohort_controller.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends ConsumerState<StudentAttendanceScreen> {
  String? _selectedCohortId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final joinedCohortsAsync = ref.watch(studentCohortsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: joinedCohortsAsync.when(
        data: (cohorts) {
          if (cohorts.isEmpty) return const Center(child: Text('You are not enrolled in any cohorts.'));
          
          if (_selectedCohortId == null && cohorts.isNotEmpty) {
            _selectedCohortId = cohorts.first.id;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedCohortId,
                  decoration: const InputDecoration(labelText: 'Select Course', border: OutlineInputBorder()),
                  items: cohorts.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCohortId = val),
                ),
              ),
              if (_selectedCohortId != null)
                Expanded(
                  child: Consumer(builder: (context, ref, _) {
                    final historyAsync = ref.watch(studentAttendanceProvider((cohortId: _selectedCohortId!, studentId: user?.uid ?? '')));
                    
                    return historyAsync.when(
                      data: (history) {
                        if (history.isEmpty) return const Center(child: Text('No attendance records found for this course.'));
                        
                        final presentCount = history.where((r) => r.status == 'present').length;
                        final absentCount = history.where((r) => r.status == 'absent').length;
                        final lateCount = history.where((r) => r.status == 'late').length;
                        final total = history.length;

                        return ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text('Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: presentCount.toDouble(),
                                      title: '${((presentCount/total)*100).toStringAsFixed(0)}%',
                                      color: Colors.green,
                                      radius: 60,
                                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: absentCount.toDouble(),
                                      title: '${((absentCount/total)*100).toStringAsFixed(0)}%',
                                      color: Colors.red,
                                      radius: 60,
                                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: lateCount.toDouble(),
                                      title: '${((lateCount/total)*100).toStringAsFixed(0)}%',
                                      color: Colors.orange,
                                      radius: 60,
                                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendItem(color: Colors.green, label: 'Present ($presentCount)'),
                                const SizedBox(width: 16),
                                _LegendItem(color: Colors.red, label: 'Absent ($absentCount)'),
                                const SizedBox(width: 16),
                                _LegendItem(color: Colors.orange, label: 'Late ($lateCount)'),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text('Absences & Lates', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...history.where((r) => r.status != 'present').map((r) => Card(
                              child: ListTile(
                                leading: Icon(r.status == 'absent' ? Icons.cancel : Icons.access_time, color: r.status == 'absent' ? Colors.red : Colors.orange),
                                title: Text(r.date),
                                subtitle: Text(r.status.toUpperCase()),
                              ),
                            )),
                            if (history.every((r) => r.status == 'present'))
                              const Center(child: Text('Perfect attendance! Great job.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green))),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, __) => Center(child: Text('Error: $e')),
                    );
                  }),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
