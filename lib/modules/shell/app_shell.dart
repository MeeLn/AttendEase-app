import 'package:flutter/material.dart';

import '../../core/models/entities.dart';
import '../../core/state/app_controller.dart';
import '../dashboard/dashboard_page.dart';
import '../profile/profile_page.dart';

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
    final user = widget.controller.currentUser;
    final destinations = _destinationsForRole(session.role);
    final pages = _pagesForRole(session.role);
    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    final profileIndex = destinations.length - 1;
    final isProfile = _index == profileIndex;

    if (_index >= pages.length) {
      _index = 0;
    }

    final currentPage = pages[_index];
    final pageTitle = isProfile ? 'Profile' : (_index == 0 ? 'AttendEase' : destinations[_index].label);

    return Scaffold(
      drawer: _buildSidebar(context, destinations, session, user, profileIndex),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 600 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: pageTitle,
                user: user,
                role: session.role,
                isWide: true, // Always show the menu button for consistency
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      ?currentChild,
                    ],
                  ),
                  child: currentPage,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              height: 90, // Slightly taller to fit icon + label comfortably
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: destinations.sublist(0, profileIndex).asMap().entries.map((entry) {
                  final index = entry.key;
                  final dest = entry.value;
                  final isSelected = _index == index;
                  final color = isSelected
                      ? const Color(0xFF1E5674)
                      : Colors.black54;

                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _index = index),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1E5674).withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(dest.icon, color: color, size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  dest.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    List<_ShellDestination> destinations,
    Session session,
    UserAccount? user,
    int profileIndex,
  ) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          // Top section: App info and User info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E5674).withValues(alpha: 0.05),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: avatar (rounded square)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFF1E5674).withValues(alpha: 0.1),
                    child: session.role == UserRole.admin
                        ? Image.asset(
                            'assets/admin-logo.png',
                            fit: BoxFit.cover,
                          )
                        : (user?.profilePicture != null
                            ? Image.network(
                                user!.profilePicture!,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: user != null
                                    ? Text(
                                        user.initials,
                                        style: const TextStyle(
                                          color: Color(0xFF1E5674),
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        color: Color(0xFF1E5674),
                                        size: 32,
                                      ),
                              )),
                  ),
                ),
                const SizedBox(width: 16),
                // Right: name, email, role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? session.role.name.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0F2C3F),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'admin@admin.com',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E5674).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          session.role.name.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF1E5674),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          // Middle section: Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: profileIndex,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final isSelected = _index == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      setState(() => _index = index);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E5674).withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            destination.icon,
                            color: isSelected
                                ? const Color(0xFF1E5674)
                                : Colors.black54,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            destination.label,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1E5674)
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          // Bottom section: Profile and Logout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      setState(() => _index = profileIndex);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _index == profileIndex
                            ? const Color(0xFF1E5674).withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: _index == profileIndex
                                ? const Color(0xFF1E5674)
                                : Colors.black54,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Profile',
                            style: TextStyle(
                              color: _index == profileIndex
                                  ? const Color(0xFF1E5674)
                                  : Colors.black87,
                              fontWeight: _index == profileIndex
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: InkWell(
                    onTap: widget.controller.logout,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.redAccent),
                          const SizedBox(width: 16),
                          const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          _ShellDestination('Profile', Icons.person_outline),
        ];
      case UserRole.teacher:
        return const [
          _ShellDestination('Overview', Icons.dashboard_outlined),
          _ShellDestination('Attendance', Icons.play_circle_outline),
          _ShellDestination('Records', Icons.fact_check_outlined),
          _ShellDestination('Profile', Icons.person_outline),
        ];
      case UserRole.student:
        return const [
          _ShellDestination('Overview', Icons.space_dashboard_outlined),
          _ShellDestination('Face ID', Icons.face_retouching_natural_outlined),
          _ShellDestination('Attendance', Icons.event_available_outlined),
          _ShellDestination('Profile', Icons.person_outline),
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
          ProfilePage(controller: widget.controller),
        ];
      case UserRole.teacher:
        return [
          DashboardPage(controller: widget.controller, role: role),
          TeacherAttendancePage(controller: widget.controller),
          TeacherRecordsPage(controller: widget.controller),
          ProfilePage(controller: widget.controller),
        ];
      case UserRole.student:
        return [
          DashboardPage(controller: widget.controller, role: role),
          StudentFacePage(controller: widget.controller),
          StudentAttendancePage(controller: widget.controller),
          ProfilePage(controller: widget.controller),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.user,
    required this.role,
    required this.isWide,
  });

  final String title;
  final UserAccount? user;
  final UserRole role;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          if (isWide)
            IconButton(
              icon: const Icon(Icons.menu),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          if (isWide) const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Image.asset('assets/ic_launcher.png', height: 32, width: 32),
        ],
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
