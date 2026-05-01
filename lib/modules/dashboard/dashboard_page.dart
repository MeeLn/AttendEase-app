import 'package:flutter/material.dart';

import '../../core/models/entities.dart';
import '../../core/state/app_controller.dart';
import '../../core/widgets/custom_dropdown.dart';

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
    final stats = _statsForRole();

    return CustomScrollView(
      key: ValueKey('dashboard-${role.name}'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Overview',
                  subtitle: 'A quick glance at your workspace stats.',
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 200,
                  ),
                  itemCount: stats.length,
                  itemBuilder: (context, index) => _StatCard(stat: stats[index]),
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
  bool _formExpanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.menu_book_outlined,
            title: 'Courses',
            subtitle: 'Manage and activate courses for attendance.',
            onToggle: () => setState(() => _formExpanded = !_formExpanded),
            formExpanded: _formExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _formExpanded
                ? Card(
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
                  )
                : const SizedBox.shrink(),
          ),
          if (_formExpanded) const SizedBox(height: 16),
          if (widget.controller.courses.isNotEmpty)
            _SectionHeader(label: 'All Courses')
          else
            _EmptyState(icon: Icons.menu_book_outlined, message: 'No courses added yet.'),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: course.isActive,
                        onChanged: (_) async =>
                            widget.controller.toggleCourseStatus(course.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => widget.controller.deleteCourse(course.id),
                      ),
                    ],
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
  bool _formExpanded = false;

  @override
  void dispose() {
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.account_tree_outlined,
            title: 'Departments',
            subtitle: 'Organise academic departments for student grouping.',
            onToggle: () => setState(() => _formExpanded = !_formExpanded),
            formExpanded: _formExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _formExpanded
                ? Card(
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
                  )
                : const SizedBox.shrink(),
          ),
          if (_formExpanded) const SizedBox(height: 16),
          if (widget.controller.departments.isNotEmpty)
            _SectionHeader(label: 'All Departments')
          else
            _EmptyState(icon: Icons.account_tree_outlined, message: 'No departments added yet.'),
          ...widget.controller.departments.map(
            (department) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  title: Text(department.name),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () =>
                        widget.controller.deleteDepartment(department.id),
                  ),
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

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String _searchQuery = '';
  bool? _showInactive;
  UserRole? _roleFilter;
  bool _formExpanded = false;

  @override
  Widget build(BuildContext context) {
    var users = widget.controller.users;

    if (_roleFilter != null) {
      users = users.where((user) => user.role == _roleFilter).toList();
    }

    if (_showInactive == false) {
      users = users.where((user) => user.isActive).toList();
    } else if (_showInactive == true) {
      users = users.where((user) => !user.isActive).toList();
    }

    if (_searchQuery.isNotEmpty) {
      users = users.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.firstName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.department?.toLowerCase().contains(query) ?? false) ||
            (user.rollNumber?.toLowerCase().contains(query) ?? false) ||
            user.role.name.toLowerCase().contains(query);
      }).toList();
    }

    users = List.from(users)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.people_alt_outlined,
            title: 'Users',
            subtitle: 'Review, approve, and manage all registered users.',
            onToggle: () => setState(() => _formExpanded = !_formExpanded),
            formExpanded: _formExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _formExpanded
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search by Name, Email, Department, Roll or Role',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _FilterRow(
                            icon: Icons.filter_alt_outlined,
                            label: 'Status',
                            child: SegmentedButton<bool?>(
                              segments: const [
                                ButtonSegment(value: false, label: Text('A'), icon: Icon(Icons.check_circle_outline)),
                                ButtonSegment(value: true, label: Text('P'), icon: Icon(Icons.pending_outlined)),
                                ButtonSegment(value: null, label: Text('B'), icon: Icon(Icons.filter_list)),
                              ],
                              selected: {_showInactive},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _showInactive = selection.first;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _FilterRow(
                            icon: Icons.badge_outlined,
                            label: 'Role',
                            child: SegmentedButton<UserRole?>(
                              segments: const [
                                ButtonSegment(value: UserRole.student, label: Text('S'), icon: Icon(Icons.school_outlined)),
                                ButtonSegment(value: UserRole.teacher, label: Text('T'), icon: Icon(Icons.co_present_outlined)),
                                ButtonSegment(value: null, label: Text('B'), icon: Icon(Icons.filter_list)),
                              ],
                              selected: {_roleFilter},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _roleFilter = selection.first;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                widget.controller.users.isNotEmpty
                                    ? 'Total: ${widget.controller.users.length} user(s)'
                                    : 'No users',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_formExpanded) const SizedBox(height: 16),
          if (users.isEmpty && _searchQuery.isEmpty && _roleFilter == null && _showInactive == null)
            const _EmptyState(
              icon: Icons.people_alt_outlined,
              message: 'No users registered yet.',
            )
          else if (users.isEmpty)
            Card(
              child: SizedBox(
                width: double.infinity,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No users match your filters.'),
                ),
              ),
            )
          else
            ...users.map((user) {
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: user.isActive,
                          onChanged: (_) async => widget.controller.toggleUserStatus(user.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => widget.controller.deleteUser(user.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
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
  bool _formExpanded = false;

  @override
  Widget build(BuildContext context) {
    final courses = widget.controller.courses;
    final students = widget.controller.students
        .where((student) => student.isActive)
        .toList();

    _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;

    final selectedCourse = _selectedCourseId != null
        ? widget.controller.courses
            .firstWhere((c) => c.id == _selectedCourseId)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.how_to_reg_outlined,
            title: 'Take Attendance',
            subtitle: 'Select a course and mark students as present.',
            onToggle: () => setState(() => _formExpanded = !_formExpanded),
            formExpanded: _formExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _formExpanded
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CustomDropdown<int>(
                            items: courses
                                .map(
                                  (course) => CustomDropdownItem(
                                    label: '${course.name} (${course.credits} credits)',
                                    value: course.id,
                                  ),
                                )
                                .toList(),
                            hintText: 'Select course',
                            icon: Icons.menu_book_outlined,
                            selectedValue: _selectedCourseId,
                            onChanged: (value) {
                              setState(() {
                                _selectedCourseId = value;
                              });
                            },
                          ),
                          if (selectedCourse != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('Course Attendance Status:'),
                                const Spacer(),
                                Switch(
                                  value: selectedCourse.isActive,
                                  onChanged: (_) async =>
                                      widget.controller.toggleCourseStatus(selectedCourse.id),
                                ),
                                Text(selectedCourse.isActive ? 'Active' : 'Inactive'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_formExpanded) const SizedBox(height: 16),
          if (selectedCourse == null || !selectedCourse.isActive)
            Card(
              child: SizedBox(
                width: double.infinity,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'This course is not active. Activate it above to start taking attendance.',
                  ),
                ),
              ),
            )
          else if (students.isEmpty)
            _EmptyState(icon: Icons.groups_outlined, message: 'No active students to show.')
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
  String _searchQuery = '';
  bool _formExpanded = false;

  @override
  Widget build(BuildContext context) {
    final courses = widget.controller.courses;
    _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;
    var records = _selectedCourseId == null
        ? <AttendanceRecord>[]
        : widget.controller.recordsForCourse(_selectedCourseId!);

    if (_searchQuery.isNotEmpty) {
      records = records.where((record) {
        final student = widget.controller.studentById(record.studentId);
        return student.fullName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (student.rollNumber?.contains(_searchQuery) ?? false);
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.fact_check_outlined,
            title: 'Attendance Records',
            subtitle: 'Filter and search all course attendance logs.',
            onToggle: () => setState(() => _formExpanded = !_formExpanded),
            formExpanded: _formExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _formExpanded
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CustomDropdown<int>(
                            items: courses
                                .map(
                                  (course) => CustomDropdownItem(
                                    label: course.name,
                                    value: course.id,
                                  ),
                                )
                                .toList(),
                            hintText: 'Course',
                            icon: Icons.menu_book_outlined,
                            selectedValue: _selectedCourseId,
                            onChanged: (value) {
                              setState(() {
                                _selectedCourseId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search by Student Name or Roll Number',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_formExpanded) const SizedBox(height: 16),
          _RecordsTable(controller: widget.controller, records: records),
        ],
      ),
    );
  }
}

class StudentFacePage extends StatefulWidget {
  const StudentFacePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<StudentFacePage> createState() => _StudentFacePageState();
}

class _StudentFacePageState extends State<StudentFacePage> {
  bool _formExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.face_outlined,
            title: 'Face Profile',
            subtitle: 'Register your biometric profile for attendance verification.',
            onToggle: () => setState(() => _formExpanded = !_formExpanded),
            formExpanded: _formExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _formExpanded
                ? Card(
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
                              if (user.hasFaceRegistered) {
                                final proceed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Face Already Registered'),
                                    content: const Text(
                                      'Your face is already registered. Do you want to re-register your face?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                                if (proceed != true) {
                                  return;
                                }
                              }

                              final message =
                                  await widget.controller.registerFaceForCurrentStudent();
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
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
  bool _formExpanded = false;

  @override
  Widget build(BuildContext context) {
    final courses = widget.controller.activeCourses;
    final user = widget.controller.currentUser!;
    _selectedCourseId ??= courses.isNotEmpty ? courses.first.id : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.event_available_outlined,
            title: 'My Attendance',
            subtitle: 'View your attendance records and mark yourself present.',
            onToggle: () => setState(() => _formExpanded = !_formExpanded),
            formExpanded: _formExpanded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _formExpanded
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CustomDropdown<int>(
                            items: courses
                                .map(
                                  (course) => CustomDropdownItem(
                                    label: course.name,
                                    value: course.id,
                                  ),
                                )
                                .toList(),
                            hintText: 'Active course',
                            icon: Icons.menu_book_outlined,
                            selectedValue: _selectedCourseId,
                            onChanged: (value) {
                              setState(() {
                                _selectedCourseId = value;
                              });
                            },
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
                  )
                : const SizedBox.shrink(),
          ),
          if (_formExpanded) const SizedBox(height: 16),
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



class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onToggle,
    this.formExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onToggle;
  final bool formExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final iconBg = primary.withValues(alpha: 0.1);
    final iconColor = primary;
    final titleColor = isDark ? const Color(0xFFE8F0F2) : const Color(0xFF0F2C3F);
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          if (onToggle != null)
            IconButton(
              icon: Icon(
                formExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onToggle,
            ),
        ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.list_alt_outlined,
            size: 16,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
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
      return Card(
        child: SizedBox(
          width: double.infinity,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No attendance records found.'),
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32,
          columns: const [
            DataColumn(label: Text('Student'), headingRowAlignment: MainAxisAlignment.start, tooltip: 'Student Name'),
            DataColumn(label: Text('Course'), headingRowAlignment: MainAxisAlignment.start, tooltip: 'Course Name'),
            DataColumn(label: Text('Date'), headingRowAlignment: MainAxisAlignment.start, tooltip: 'Record Date'),
            DataColumn(label: Text('Method'), headingRowAlignment: MainAxisAlignment.start, tooltip: 'Attendance Method'),
          ],
          rows: records.map((record) {
            final student = controller.studentById(record.studentId);
            final course = controller.courseById(record.courseId);
            final date =
                '${record.recordedAt.year}-${record.recordedAt.month.toString().padLeft(2, '0')}-${record.recordedAt.day.toString().padLeft(2, '0')}';
            return DataRow(
              cells: [
                DataCell(SizedBox(width: 180, child: Text(student.fullName))),
                DataCell(SizedBox(width: 150, child: Text(course.name))),
                DataCell(SizedBox(width: 120, child: Text(date))),
                DataCell(SizedBox(width: 150, child: Text(record.method))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
