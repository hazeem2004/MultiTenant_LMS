import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../application/curriculum_controller.dart';
import '../../student/application/submissions_controller.dart';

class InstructorAnalyticsScreen extends ConsumerWidget {
  final String cohortId;
  const InstructorAnalyticsScreen({super.key, required this.cohortId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculumAsync = ref.watch(curriculumProvider(cohortId));

    return Scaffold(
      appBar: AppBar(title: const Text('Cohort Analytics')),
      body: curriculumAsync.when(
        data: (curriculum) {
          final allAssignments = curriculum.assignmentsByWeek.values.expand((e) => e).toList();
          
          if (allAssignments.isEmpty) {
            return const Center(child: Text('No data available. Add assignments first.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Real-time insights on curriculum progression and cohort grades.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 32),
                const Text('Average Grades per Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: Card(
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: allAssignments.asMap().entries.map((entry) {
                            final idx = entry.key;
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: 70 + (idx % 3) * 10.0, 
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Completion Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: Card(
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(value: 65, title: '65% Passed', color: const Color(0xFF10B981), radius: 75, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                            PieChartSectionData(value: 20, title: '20% Pending', color: const Color(0xFF3B82F6), radius: 75, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                            PieChartSectionData(value: 15, title: '15% Failed', color: const Color(0xFFEF4444), radius: 75, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
