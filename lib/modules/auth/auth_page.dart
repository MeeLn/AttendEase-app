import 'package:flutter/material.dart';

import '../../core/state/app_controller.dart';

enum _AuthMode { login, registerStudent, registerTeacher }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  _AuthMode _mode = _AuthMode.login;

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _studentFirstName = TextEditingController();
  final _studentLastName = TextEditingController();
  final _studentDepartment = TextEditingController();
  final _studentRoll = TextEditingController();
  final _studentEmail = TextEditingController();
  final _studentPassword = TextEditingController();
  final _studentConfirmPassword = TextEditingController();
  final _teacherFirstName = TextEditingController();
  final _teacherLastName = TextEditingController();
  final _teacherEmail = TextEditingController();
  final _teacherPassword = TextEditingController();
  final _teacherConfirmPassword = TextEditingController();

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _studentFirstName.dispose();
    _studentLastName.dispose();
    _studentDepartment.dispose();
    _studentRoll.dispose();
    _studentEmail.dispose();
    _studentPassword.dispose();
    _studentConfirmPassword.dispose();
    _teacherFirstName.dispose();
    _teacherLastName.dispose();
    _teacherEmail.dispose();
    _teacherPassword.dispose();
    _teacherConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2C3F), Color(0xFF1E5674), Color(0xFF9EC8D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.18,
                  child: Image.asset('assets/login-bg.png', fit: BoxFit.cover),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(child: _buildHero(context)),
                              const SizedBox(width: 28),
                              SizedBox(width: 460, child: _buildPanel(context)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildHero(context),
                              const SizedBox(height: 24),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: _buildPanel(context),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'Campus attendance, rebuilt in Flutter',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'AttendEase',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 56,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Role-based attendance management for admins, teachers, and students with a cleaner mobile-first experience.',
            style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _HeroPill(title: 'Admin approval flow'),
              _HeroPill(title: 'Course activation controls'),
              _HeroPill(title: 'Student face-registration step'),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Demo accounts',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Admin: admin@admin.com / admin123\nTeacher: teacher@attendease.app / teacher123\nStudent: student@attendease.app / student123',
            style: TextStyle(color: Colors.white70, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_mode) {
            _AuthMode.login => _buildLoginForm(context),
            _AuthMode.registerStudent => _buildStudentForm(context),
            _AuthMode.registerTeacher => _buildTeacherForm(context),
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to your attendance workspace.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _loginEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _loginPassword,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text('Login'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _mode = _AuthMode.registerStudent;
            }),
            child: const Text('Not registered yet? Create an account'),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentForm(BuildContext context) {
    return Column(
      key: const ValueKey('student'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRegisterHeader(
          context,
          title: 'Student registration',
          subtitle:
              'New student accounts remain inactive until approved by admin.',
        ),
        _buildTextField(_studentFirstName, 'First name'),
        const SizedBox(height: 12),
        _buildTextField(_studentLastName, 'Last name'),
        const SizedBox(height: 12),
        _buildTextField(_studentDepartment, 'Department'),
        const SizedBox(height: 12),
        _buildTextField(_studentRoll, 'Roll number'),
        const SizedBox(height: 12),
        _buildTextField(_studentEmail, 'Email', TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildTextField(_studentPassword, 'Password', null, true),
        const SizedBox(height: 12),
        _buildTextField(
          _studentConfirmPassword,
          'Confirm password',
          null,
          true,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitStudentRegistration,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Register as student'),
          ),
        ),
        const SizedBox(height: 12),
        _registerFooter(),
      ],
    );
  }

  Widget _buildTeacherForm(BuildContext context) {
    return Column(
      key: const ValueKey('teacher'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRegisterHeader(
          context,
          title: 'Teacher registration',
          subtitle:
              'Use this if you need course attendance and reporting access.',
        ),
        _buildTextField(_teacherFirstName, 'First name'),
        const SizedBox(height: 12),
        _buildTextField(_teacherLastName, 'Last name'),
        const SizedBox(height: 12),
        _buildTextField(_teacherEmail, 'Email', TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildTextField(_teacherPassword, 'Password', null, true),
        const SizedBox(height: 12),
        _buildTextField(
          _teacherConfirmPassword,
          'Confirm password',
          null,
          true,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitTeacherRegistration,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Register as teacher'),
          ),
        ),
        const SizedBox(height: 12),
        _registerFooter(),
      ],
    );
  }

  Widget _buildRegisterHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        SegmentedButton<_AuthMode>(
          segments: const [
            ButtonSegment(
              value: _AuthMode.registerStudent,
              label: Text('Student'),
              icon: Icon(Icons.school_outlined),
            ),
            ButtonSegment(
              value: _AuthMode.registerTeacher,
              label: Text('Teacher'),
              icon: Icon(Icons.co_present_outlined),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) {
            setState(() {
              _mode = selection.first;
            });
          },
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _registerFooter() {
    return Center(
      child: TextButton(
        onPressed: () => setState(() {
          _mode = _AuthMode.login;
        }),
        child: const Text('Back to login'),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    TextInputType? keyboardType,
    bool obscureText = false,
  ]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _submitLogin() async {
    final message = await widget.controller.login(
      email: _loginEmail.text,
      password: _loginPassword.text,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showMessage(message);
    }
  }

  Future<void> _submitStudentRegistration() async {
    final message = await widget.controller.registerStudent(
      firstName: _studentFirstName.text,
      lastName: _studentLastName.text,
      department: _studentDepartment.text,
      rollNumber: _studentRoll.text,
      email: _studentEmail.text,
      password: _studentPassword.text,
      confirmPassword: _studentConfirmPassword.text,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showMessage(message);
      return;
    }
    _clearStudentFields();
    _showMessage('Student registered. Wait for admin approval before login.');
    setState(() {
      _mode = _AuthMode.login;
    });
  }

  Future<void> _submitTeacherRegistration() async {
    final message = await widget.controller.registerTeacher(
      firstName: _teacherFirstName.text,
      lastName: _teacherLastName.text,
      email: _teacherEmail.text,
      password: _teacherPassword.text,
      confirmPassword: _teacherConfirmPassword.text,
    );
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showMessage(message);
      return;
    }
    _clearTeacherFields();
    _showMessage('Teacher registered. Wait for admin approval before login.');
    setState(() {
      _mode = _AuthMode.login;
    });
  }

  void _clearStudentFields() {
    _studentFirstName.clear();
    _studentLastName.clear();
    _studentDepartment.clear();
    _studentRoll.clear();
    _studentEmail.clear();
    _studentPassword.clear();
    _studentConfirmPassword.clear();
  }

  void _clearTeacherFields() {
    _teacherFirstName.clear();
    _teacherLastName.clear();
    _teacherEmail.clear();
    _teacherPassword.clear();
    _teacherConfirmPassword.clear();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
