import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../instructor/application/cohort_controller.dart';
import '../../instructor/domain/cohort.dart';
import '../application/admin_controller.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            leading: Column(
              children: [
                const SizedBox(height: 24),
                Icon(Icons.auto_awesome, size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 32),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: IconButton(
                    onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Sign Out',
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.class_outlined),
                selectedIcon: Icon(Icons.class_),
                label: Text('Cohorts'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                _OverviewTab(),
                _UserManagementTab(),
                _CohortManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(systemStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Overview'), centerTitle: false),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Metrics', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              Row(
                children: [
                  _StatCard(title: 'Active Cohorts', value: stats['cohorts']!, icon: Icons.rocket_launch, color: Colors.blue),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Total Students', value: stats['students']!, icon: Icons.school, color: Colors.green),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Instructors', value: stats['instructors']!, icon: Icons.person_pin, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 40),
              Text('User Distribution', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: stats['students']!.toDouble(),
                            title: 'Students',
                            color: Colors.green,
                            radius: 100,
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: stats['instructors']!.toDouble(),
                            title: 'Teachers',
                            color: Colors.orange,
                            radius: 100,
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _UserManagementTab extends ConsumerWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management'), centerTitle: false),
      body: usersAsync.when(
        data: (users) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map((user) => DataRow(
                  cells: [
                    DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(user.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user.uid, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    )),
                    DataCell(DropdownButton<String>(
                      value: user.role.toUpperCase(),
                      items: ['ADMIN', 'INSTRUCTOR', 'STUDENT'].map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(adminControllerProvider.notifier).updateUserRole(user.uid, val);
                        }
                      },
                    )),
                    DataCell(Switch(
                      value: user.isApproved,
                      onChanged: (_) => ref.read(adminControllerProvider.notifier).toggleApproval(user.uid, user.isApproved),
                    )),
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref, user),
                    )),
                  ],
                )).toList(),
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user.email}? This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(adminControllerProvider.notifier).deleteUser(user.uid);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CohortManagementTab extends ConsumerWidget {
  const _CohortManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need a way to list all cohorts. 
    // Let's assume instructor dashboard logic can be repurposed or we add a global cohorts provider.
    final cohortsAsync = ref.watch(cohortListProvider); // Existing provider
    final instructorsAsync = ref.watch(usersByRoleProvider('INSTRUCTOR'));

    return Scaffold(
      appBar: AppBar(title: const Text('Cohort Management'), centerTitle: false),
      body: cohortsAsync.when(
        data: (cohorts) => ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: cohorts.length,
          itemBuilder: (context, index) {
            final cohort = cohorts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(cohort.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Instructor ID: ${cohort.instructorId}'),
                trailing: TextButton.icon(
                  onPressed: () => _showReassignDialog(context, ref, cohort, instructorsAsync),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Reassign'),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showReassignDialog(BuildContext context, WidgetRef ref, Cohort cohort, AsyncValue<List<AppUser>> instructorsAsync) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reassign Cohort'),
        content: instructorsAsync.when(
          data: (instructors) => Column(
            mainAxisSize: MainAxisSize.min,
            children: instructors.map((i) => ListTile(
              title: Text(i.email),
              onTap: () {
                ref.read(adminControllerProvider.notifier).updateCohortInstructor(cohort.id, i.uid);
                Navigator.pop(ctx);
              },
            )).toList(),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, __) => Text('Error: $e'),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 16),
              Text(value.toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}


