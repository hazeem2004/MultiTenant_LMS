import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../student/application/enrollments_controller.dart';
import '../data/attendance_repository.dart';

class OverallAttendanceScreen extends ConsumerStatefulWidget {
  final String cohortId;
  const OverallAttendanceScreen({super.key, required this.cohortId});

  @override
  ConsumerState<OverallAttendanceScreen> createState() => _OverallAttendanceScreenState();
}

class _OverallAttendanceScreenState extends ConsumerState<OverallAttendanceScreen> {
  final List<String> _dates = [];

  @override
  void initState() {
    super.initState();
    // Generate last 7 days as default columns
    for (int i = 0; i < 7; i++) {
      final d = DateTime.now().subtract(Duration(days: i));
      _dates.add("${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync = ref.watch(enrollmentsProvider(widget.cohortId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Add Date',
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                final ds = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                if (!_dates.contains(ds)) setState(() => _dates.insert(0, ds));
              }
            },
          ),
        ],
      ),
      body: enrollmentsAsync.when(
        data: (enrollments) {
          final students = enrollments.where((e) => e.status == 'active').toList();
          
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  ..._dates.map((d) => DataColumn(label: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)))),
                ],
                rows: students.map((student) {
                  return DataRow(
                    cells: [
                      DataCell(Text(student.studentId)),
                      ..._dates.map((date) {
                        return DataCell(
                          Consumer(builder: (context, ref, _) {
                            final attendanceStream = ref.watch(attendanceStreamProvider((cohortId: widget.cohortId, date: date)));
                            return attendanceStream.when(
                              data: (statuses) {
                                final status = statuses[student.studentId] ?? 'missing';
                                return InkWell(
                                  onTap: () => _showStatusPicker(context, ref, widget.cohortId, date, student.studentId, statuses),
                                  child: _StatusIndicator(status: status),
                                );
                              },
                              loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              error: (_, __) => const Icon(Icons.error, size: 16, color: Colors.red),
                            );
                          }),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref, String cohortId, String date, String studentId, Map<String, String> currentMap) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['present', 'absent', 'late', 'missing'].map((status) => ListTile(
          title: Text(status.toUpperCase()),
          onTap: () {
            final newMap = Map<String, String>.from(currentMap);
            newMap[studentId] = status;
            ref.read(attendanceRepositoryProvider).saveAttendance(cohortId: cohortId, date: date, statusMap: newMap);
            Navigator.pop(ctx);
          },
        )).toList(),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;
  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case 'present': color = Colors.green; icon = Icons.check_circle; break;
      case 'absent': color = Colors.red; icon = Icons.cancel; break;
      case 'late': color = Colors.orange; icon = Icons.access_time; break;
      default: color = Colors.grey; icon = Icons.help_outline;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

final attendanceStreamProvider = StreamProvider.family<Map<String, String>, ({String cohortId, String date})>((ref, arg) {
  return ref.watch(attendanceRepositoryProvider).watchAttendance(arg.cohortId, arg.date);
});
