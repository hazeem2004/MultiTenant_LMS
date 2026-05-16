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
                Text('Performance Overview', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 32),
                const Text('Average Grades per Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barGroups: allAssignments.asMap().entries.map((entry) {
                            final idx = entry.key;
                            // For demo purposes, using a random value. In real app, we'd calculate avg.
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: 70 + (idx % 3) * 10.0, 
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 16,
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
                const Text('Completion Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(value: 65, title: '65% Passed', color: Colors.green, radius: 80),
                            PieChartSectionData(value: 20, title: '20% Pending', color: Colors.blue, radius: 80),
                            PieChartSectionData(value: 15, title: '15% Failed', color: Colors.red, radius: 80),
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
