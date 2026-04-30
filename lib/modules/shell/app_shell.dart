import 'package:flutter/material.dart';

import '../../core/models/entities.dart';
import '../../core/state/app_controller.dart';
import '../dashboard/dashboard_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session!;
    final destinations = _destinationsForRole(session.role);
    final pages = _pagesForRole(session.role);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              NavigationRail(
                selectedIndex: _index,
                extended: MediaQuery.sizeOf(context).width >= 1180,
                onDestinationSelected: (value) {
                  setState(() {
                    _index = value;
                  });
                },
                destinations: destinations
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                    )
                    .toList(),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: pages[_index],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              destinations: destinations
                  .map(
                    (destination) => NavigationDestination(
                      icon: Icon(destination.icon),
                      label: destination.label,
                    ),
                  )
                  .toList(),
              onDestinationSelected: (value) {
                setState(() {
                  _index = value;
                });
              },
            ),
    );
  }

  List<_ShellDestination> _destinationsForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          _ShellDestination('Overview', Icons.dashboard_customize_outlined),
          _ShellDestination('Courses', Icons.menu_book_outlined),
          _ShellDestination('Departments', Icons.account_tree_outlined),
          _ShellDestination('Users', Icons.manage_accounts_outlined),
        ];
      case UserRole.teacher:
        return const [
          _ShellDestination('Overview', Icons.dashboard_outlined),
          _ShellDestination('Attendance', Icons.play_circle_outline),
          _ShellDestination('Records', Icons.fact_check_outlined),
        ];
      case UserRole.student:
        return const [
          _ShellDestination('Overview', Icons.space_dashboard_outlined),
          _ShellDestination('Face ID', Icons.face_retouching_natural_outlined),
          _ShellDestination('Attendance', Icons.event_available_outlined),
        ];
    }
  }

  List<Widget> _pagesForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          DashboardPage(controller: widget.controller, role: role),
          CoursesPage(controller: widget.controller),
          DepartmentsPage(controller: widget.controller),
          UsersPage(controller: widget.controller),
        ];
      case UserRole.teacher:
        return [
          DashboardPage(controller: widget.controller, role: role),
          TeacherAttendancePage(controller: widget.controller),
          TeacherRecordsPage(controller: widget.controller),
        ];
      case UserRole.student:
        return [
          DashboardPage(controller: widget.controller, role: role),
          StudentFacePage(controller: widget.controller),
          StudentAttendancePage(controller: widget.controller),
        ];
    }
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
