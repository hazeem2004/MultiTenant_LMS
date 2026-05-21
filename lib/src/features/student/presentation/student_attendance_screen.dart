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
                            Text('Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    if (presentCount > 0)
                                      PieChartSectionData(
                                        value: presentCount.toDouble(),
                                        title: '${((presentCount/total)*100).toStringAsFixed(0)}%',
                                        color: const Color(0xFF10B981),
                                        radius: 65,
                                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    if (absentCount > 0)
                                      PieChartSectionData(
                                        value: absentCount.toDouble(),
                                        title: '${((absentCount/total)*100).toStringAsFixed(0)}%',
                                        color: const Color(0xFFEF4444),
                                        radius: 65,
                                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    if (lateCount > 0)
                                      PieChartSectionData(
                                        value: lateCount.toDouble(),
                                        title: '${((lateCount/total)*100).toStringAsFixed(0)}%',
                                        color: const Color(0xFFF59E0B),
                                        radius: 65,
                                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendItem(color: const Color(0xFF10B981), label: 'Present ($presentCount)'),
                                const SizedBox(width: 20),
                                _LegendItem(color: const Color(0xFFEF4444), label: 'Absent ($absentCount)'),
                                const SizedBox(width: 20),
                                _LegendItem(color: const Color(0xFFF59E0B), label: 'Late ($lateCount)'),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Text('Absences & Lates', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            if (history.every((r) => r.status == 'present'))
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars, color: Color(0xFF15803D)),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Perfect attendance! Keep up the amazing work.',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...history.where((r) => r.status != 'present').map((r) {
                                final isAbsent = r.status == 'absent';
                                final color = isAbsent ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
                                final bgColor = isAbsent ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shadowColor: Colors.black.withOpacity(0.04),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isAbsent ? Icons.cancel_outlined : Icons.access_time, 
                                        color: color, 
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      r.date, 
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      r.status.toUpperCase(),
                                      style: TextStyle(
                                        color: color, 
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }),
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
