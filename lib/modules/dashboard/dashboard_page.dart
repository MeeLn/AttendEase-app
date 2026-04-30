import 'package:flutter/material.dart';

import '../../core/models/entities.dart';
import '../../core/state/app_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.role,
  });

  final AppController controller;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final currentUser = controller.currentUser;
    final title = switch (role) {
      UserRole.admin => 'Admin command center',
      UserRole.teacher => 'Teacher dashboard',
      UserRole.student => 'Student dashboard',
    };
    final subtitle = switch (role) {
      UserRole.admin =>
        'Review registrations, curate departments, and keep courses ready for attendance.',
      UserRole.teacher =>
        'Launch attendance sessions and review course activity from one place.',
      UserRole.student =>
        'Register your face profile, check attendance, and stay on top of active courses.',
    };

    final stats = _statsForRole();

    return CustomScrollView(
      key: ValueKey('dashboard-${role.name}'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(
                  title: title,
                  subtitle: subtitle,
                  role: role,
                  currentUserName: currentUser?.fullName,
                  onLogout: controller.logout,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: stats
                      .map(
                        (stat) =>
                            SizedBox(width: 220, child: _StatCard(stat: stat)),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What changed in Flutter',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'This version keeps the original roles and attendance flow, but moves the app into a cleaner Flutter shell. Native face recognition is represented as a face-registration workflow so the rest of the product stays usable while camera ML integration is rebuilt.',
                          style: TextStyle(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_StatItem> _statsForRole() {
    switch (role) {
      case UserRole.admin:
        final pendingUsers = controller.users
            .where((user) => !user.isActive)
            .length;
        return [
          _StatItem(
            'Students',
            '${controller.students.length}',
            Icons.school_outlined,
            const Color(0xFF164863),
          ),
          _StatItem(
            'Teachers',
            '${controller.teachers.length}',
            Icons.co_present_outlined,
            const Color(0xFF427D9D),
          ),
          _StatItem(
            'Pending approvals',
            '$pendingUsers',
            Icons.pending_actions_outlined,
            const Color(0xFFD17A22),
          ),
          _StatItem(
            'Active courses',
            '${controller.activeCourses.length}',
            Icons.play_lesson_outlined,
            const Color(0xFF2A7F62),
          ),
        ];
      case UserRole.teacher:
        return [
          _StatItem(
            'Live courses',
            '${controller.activeCourses.length}',
            Icons.auto_stories_outlined,
            const Color(0xFF164863),
          ),
          _StatItem(
            'Students',
            '${controller.students.where((user) => user.isActive).length}',
            Icons.groups_outlined,
            const Color(0xFF427D9D),
          ),
          _StatItem(
            'Records',
            '${controller.attendance.length}',
            Icons.fact_check_outlined,
            const Color(0xFF2A7F62),
          ),
        ];
      case UserRole.student:
        final user = controller.currentUser!;
        return [
          _StatItem(
            'Face profile',
            user.hasFaceRegistered ? 'Ready' : 'Missing',
            Icons.face_outlined,
            const Color(0xFF164863),
          ),
          _StatItem(
            'Active courses',
            '${controller.activeCourses.length}',
            Icons.menu_book_outlined,
            const Color(0xFF427D9D),
          ),
          _StatItem(
            'Attendance marks',
            '${controller.attendanceCountForStudent(user.id)}',
            Icons.event_available_outlined,
            const Color(0xFF2A7F62),
          ),
        ];
    }
  }
}

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final _nameController = TextEditingController();
  final _creditsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Course management',
      subtitle:
          'Add courses and control whether they appear in attendance workflows.',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Course name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _creditsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Credits'),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _addCourse,
                      child: const Text('Add course'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.controller.courses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(course.name),
                  subtitle: Text('${course.credits} credits'),
                  trailing: Switch(
                    value: course.isActive,
                    onChanged: (_) async =>
                        widget.controller.toggleCourseStatus(course.id),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCourse() async {
    final message = await widget.controller.addCourse(
      name: _nameController.text,
      creditsText: _creditsController.text,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showMessage(message);
      return;
    }
    _nameController.clear();
    _creditsController.clear();
    _showMessage('Course added.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  final _departmentController = TextEditingController();

  @override
  void dispose() {
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Departments',
      subtitle: 'Keep student registration aligned to active academic units.',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _addDepartment,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.controller.departments.map(
            (department) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(department.name),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDepartment() async {
    final message = await widget.controller.addDepartment(
      _departmentController.text,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showMessage(message);
      return;
    }
    _departmentController.clear();
    _showMessage('Department added.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'User approvals',
      subtitle: 'Activate or deactivate student and teacher accounts.',
      child: Column(
        children: controller.users.map((user) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: Text(user.fullName),
                subtitle: Text(
                  '${user.role.name.toUpperCase()} • ${user.email}${user.department != null ? ' • ${user.department}' : ''}',
                ),
                trailing: Switch(
                  value: user.isActive,
                  onChanged: (_) async => controller.toggleUserStatus(user.id),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  int? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final courses = widget.controller.activeCourses;
    final students = widget.controller.students
        .where((student) => student.isActive)
        .toList();

    _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;

    return _PageScaffold(
      title: 'Start attendance',
      subtitle: 'Choose an active course and mark present students for today.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DropdownButtonFormField<int>(
                initialValue: _selectedCourseId,
                items: courses
                    .map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(
                          '${course.name} (${course.credits} credits)',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourseId = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Active course'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (courses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No active courses available. Ask admin to activate one.',
                ),
              ),
            )
          else
            ...students.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    title: Text(student.fullName),
                    subtitle: Text(
                      '${student.rollNumber ?? 'No roll'} • ${student.department ?? 'No department'}',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => _markStudent(student.id),
                      child: const Text('Mark present'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markStudent(int studentId) async {
    if (_selectedCourseId == null) {
      _showMessage('Select a course first.');
      return;
    }
    final message = await widget.controller.markAttendanceForStudent(
      studentId: studentId,
      courseId: _selectedCourseId!,
    );
    if (!mounted) {
      return;
    }
    _showMessage(message ?? 'Attendance marked.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class TeacherRecordsPage extends StatefulWidget {
  const TeacherRecordsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<TeacherRecordsPage> createState() => _TeacherRecordsPageState();
}

class _TeacherRecordsPageState extends State<TeacherRecordsPage> {
  int? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final courses = widget.controller.courses;
    _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;
    final records = _selectedCourseId == null
        ? <AttendanceRecord>[]
        : widget.controller.recordsForCourse(_selectedCourseId!);

    return _PageScaffold(
      title: 'Attendance records',
      subtitle: 'Review attendance by course.',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DropdownButtonFormField<int>(
                initialValue: _selectedCourseId,
                items: courses
                    .map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(course.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourseId = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Course'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecordsTable(controller: widget.controller, records: records),
        ],
      ),
    );
  }
}

class StudentFacePage extends StatelessWidget {
  const StudentFacePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser!;

    return _PageScaffold(
      title: 'Face profile',
      subtitle:
          'Register and refresh the face profile used for attendance verification.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.face_retouching_natural_outlined),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.hasFaceRegistered
                              ? 'Face profile ready for attendance confirmation.'
                              : 'No face profile on file yet.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'This flow now launches the native Android camera pipeline from Flutter, detects a face with ML Kit, and stores a MobileFaceNet-ready 112x112 face crop for later verification.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  final message = await controller
                      .registerFaceForCurrentStudent();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(message ?? 'Face registered.')),
                    );
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  user.hasFaceRegistered
                      ? 'Refresh face profile'
                      : 'Register face profile',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  int? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final courses = widget.controller.activeCourses;
    final user = widget.controller.currentUser!;
    _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;

    return _PageScaffold(
      title: 'My attendance',
      subtitle: 'Mark today’s attendance and review your history.',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCourseId,
                    items: courses
                        .map(
                          (course) => DropdownMenuItem(
                            value: course.id,
                            child: Text(course.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCourseId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Active course',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedCourseId == null
                          ? null
                          : _takeAttendance,
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Take attendance'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecordsTable(
            controller: widget.controller,
            records: widget.controller.recordsForStudent(user.id),
          ),
        ],
      ),
    );
  }

  Future<void> _takeAttendance() async {
    final message = await widget.controller.markAttendanceForCurrentStudent(
      _selectedCourseId!,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message ?? 'Attendance marked successfully.')),
      );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(height: 1.5, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.role,
    required this.currentUserName,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final UserRole role;
  final String? currentUserName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == UserRole.admin
        ? 'Administrator'
        : currentUserName ?? role.name;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF12344D), Color(0xFF2B6B8A), Color(0xFF79A8C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.tonalIcon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF12344D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(stat.icon, color: stat.color),
            ),
            const SizedBox(height: 20),
            Text(stat.value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(stat.label),
          ],
        ),
      ),
    );
  }
}

class _RecordsTable extends StatelessWidget {
  const _RecordsTable({required this.controller, required this.records});

  final AppController controller;
  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No attendance records found.'),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Course')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Method')),
          ],
          rows: records.map((record) {
            final student = controller.studentById(record.studentId);
            final course = controller.courseById(record.courseId);
            final date =
                '${record.recordedAt.year}-${record.recordedAt.month.toString().padLeft(2, '0')}-${record.recordedAt.day.toString().padLeft(2, '0')}';
            return DataRow(
              cells: [
                DataCell(Text(student.fullName)),
                DataCell(Text(course.name)),
                DataCell(Text(date)),
                DataCell(Text(record.method)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
