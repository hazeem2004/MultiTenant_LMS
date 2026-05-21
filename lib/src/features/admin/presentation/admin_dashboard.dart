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
    final isMobile = MediaQuery.of(context).size.width < 650;
    
    final mainContent = IndexedStack(
      index: _selectedIndex,
      children: const [
        _OverviewTab(),
        _UserManagementTab(),
        _CohortManagementTab(),
      ],
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedIndex == 0 
                ? 'Overview' 
                : _selectedIndex == 1 
                    ? 'Users' 
                    : 'Cohorts',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(child: mainContent),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_),
              label: 'Cohorts',
            ),
          ],
        ),
      );
    }

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
            child: mainContent,
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
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      appBar: isMobile 
          ? null 
          : AppBar(title: const Text('Platform Overview'), centerTitle: false),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Metrics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatCard(title: 'Active Cohorts', value: stats['cohorts']!, icon: Icons.rocket_launch, color: Colors.blue),
                        const SizedBox(height: 16),
                        _StatCard(title: 'Total Students', value: stats['students']!, icon: Icons.school, color: Colors.green),
                        const SizedBox(height: 16),
                        _StatCard(title: 'Instructors', value: stats['instructors']!, icon: Icons.person_pin, color: Colors.orange),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _StatCard(title: 'Active Cohorts', value: stats['cohorts']!, icon: Icons.rocket_launch, color: Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Total Students', value: stats['students']!, icon: Icons.school, color: Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(child: _StatCard(title: 'Instructors', value: stats['instructors']!, icon: Icons.person_pin, color: Colors.orange)),
                    ],
                  );
                }
              ),
              const SizedBox(height: 40),
              Text('User Distribution', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
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
                          PieChartSectionData(
                            value: stats['students']!.toDouble(),
                            title: 'Students',
                            color: const Color(0xFF6D28D9),
                            radius: 80,
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                          PieChartSectionData(
                            value: stats['instructors']!.toDouble(),
                            title: 'Teachers',
                            color: const Color(0xFF4F46E5),
                            radius: 80,
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
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
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      appBar: isMobile 
          ? null 
          : AppBar(title: const Text('User Management'), centerTitle: false),
      body: usersAsync.when(
        data: (users) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 96,
                ),
                child: DataTable(
                  horizontalMargin: 24,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: users.map((user) => DataRow(
                    cells: [
                      DataCell(Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(user.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(user.uid, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
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
                        activeColor: Theme.of(context).colorScheme.primary,
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
    final cohortsAsync = ref.watch(cohortListProvider);
    final instructorsAsync = ref.watch(usersByRoleProvider('INSTRUCTOR'));
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      appBar: isMobile 
          ? null 
          : AppBar(title: const Text('Cohort Management'), centerTitle: false),
      body: cohortsAsync.when(
        data: (cohorts) {
          if (cohorts.isEmpty) {
            return const Center(child: Text('No cohorts created yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: cohorts.length,
            itemBuilder: (context, index) {
              final cohort = cohorts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(cohort.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Instructor ID: ${cohort.instructorId}'),
                    trailing: TextButton.icon(
                      onPressed: () => _showReassignDialog(context, ref, cohort, instructorsAsync),
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      label: const Text('Reassign'),
                    ),
                  ),
                ),
              );
            },
          );
        },
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
          data: (instructors) {
            if (instructors.isEmpty) {
              return const Text('No instructors available to reassign.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: instructors.map((i) => ListTile(
                title: Text(i.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(adminControllerProvider.notifier).updateCohortInstructor(cohort.id, i.uid);
                  Navigator.pop(ctx);
                },
              )).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
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
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value.toString(), 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title, 
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


