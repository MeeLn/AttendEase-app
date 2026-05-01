import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/custom_dropdown.dart';

enum _AuthMode { login, registerStudent, registerTeacher }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  _AuthMode _mode = _AuthMode.login;
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;
  int? _selectedDepartmentId;
  XFile? _studentProfilePicture;
  XFile? _teacherProfilePicture;
  final _picker = ImagePicker();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _studentFirstName = TextEditingController();
  final _studentLastName = TextEditingController();
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
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _loginEmail.dispose();
    _loginPassword.dispose();
    _studentFirstName.dispose();
    _studentLastName.dispose();
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

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildPanel(context),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/ic_launcher.png',
          height: 64,
          width: 64,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to your attendance workspace.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _loginEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1E5674)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _loginPassword,
          obscureText: _obscureLoginPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1E5674)),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                ),
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF1E5674),
                ),
                onPressed: () => setState(() {
                  _obscureLoginPassword = !_obscureLoginPassword;
                }),
              ),
            ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRegisterHeader(
          context,
          title: 'Student registration',
          subtitle:
              'New student accounts remain inactive until approved by admin.',
        ),
        _buildProfilePicturePicker(
          _studentProfilePicture,
          () => _pickProfilePicture(true),
          () => setState(() => _studentProfilePicture = null),
        ),
        const SizedBox(height: 12),
        _buildTextField(_studentFirstName, 'First name', Icons.person_outlined),
        const SizedBox(height: 12),
        _buildTextField(_studentLastName, 'Last name', Icons.badge_outlined),
        const SizedBox(height: 12),
        CustomDropdown<int>(
          items: widget.controller.departments
              .map(
                (department) => CustomDropdownItem(
                  label: department.name,
                  value: department.id,
                ),
              )
              .toList(),
          hintText: 'Department',
          icon: Icons.school_outlined,
          selectedValue: _selectedDepartmentId,
          onChanged: (value) {
            setState(() {
              _selectedDepartmentId = value;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(_studentRoll, 'Roll number', Icons.numbers_outlined),
        const SizedBox(height: 12),
        _buildTextField(
          _studentEmail,
          'Email',
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          _studentPassword,
          'Password',
          Icons.lock_outline,
          obscureText: _obscureRegisterPassword,
          isPassword: true,
          onToggleObscure: () => setState(() {
            _obscureRegisterPassword = !_obscureRegisterPassword;
          }),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          _studentConfirmPassword,
          'Confirm password',
          Icons.lock_reset_outlined,
          obscureText: _obscureConfirmPassword,
          isPassword: true,
          onToggleObscure: () => setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          }),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRegisterHeader(
          context,
          title: 'Teacher registration',
          subtitle:
              'Use this if you need course attendance and reporting access.',
        ),
        _buildProfilePicturePicker(
          _teacherProfilePicture,
          () => _pickProfilePicture(false),
          () => setState(() => _teacherProfilePicture = null),
        ),
        const SizedBox(height: 12),
        _buildTextField(_teacherFirstName, 'First name', Icons.person_outlined),
        const SizedBox(height: 12),
        _buildTextField(_teacherLastName, 'Last name', Icons.badge_outlined),
        const SizedBox(height: 12),
        _buildTextField(
          _teacherEmail,
          'Email',
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          _teacherPassword,
          'Password',
          Icons.lock_outline,
          obscureText: _obscureRegisterPassword,
          isPassword: true,
          onToggleObscure: () => setState(() {
            _obscureRegisterPassword = !_obscureRegisterPassword;
          }),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          _teacherConfirmPassword,
          'Confirm password',
          Icons.lock_reset_outlined,
          obscureText: _obscureConfirmPassword,
          isPassword: true,
          onToggleObscure: () => setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          }),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/admin-logo.png',
          height: 64,
          width: 64,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: isDark ? Colors.white54 : Colors.black54),
          textAlign: TextAlign.center,
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
    String label,
    IconData prefixIcon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onToggleObscure,
  }) {
    const iconColor = Color(0xFF1E5674);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: iconColor),
        suffixIcon: isPassword
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                  ),
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: iconColor,
                  ),
                  onPressed: onToggleObscure,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildProfilePicturePicker(
    XFile? selectedFile,
    VoidCallback onPick,
    VoidCallback onRemove,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: selectedFile != null
                  ? Image.file(
                      File(selectedFile.path),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person_outline, color: primary, size: 24),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile picture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedFile != null
                        ? selectedFile.name
                        : 'Optional · tap to select',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selectedFile != null)
              IconButton(
                icon: Icon(Icons.close, color: primary, size: 20),
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                ),
                onPressed: onRemove,
              ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  selectedFile != null
                      ? Icons.photo_library_rounded
                      : Icons.add_photo_alternate_outlined,
                  color: primary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                ),
                onPressed: onPick,
              ),
            ),
          ],
        ),
      ),
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
    if (_selectedDepartmentId == null) {
      _showMessage('Please select a department.');
      return;
    }
    final department = widget.controller.departments
        .firstWhere((d) => d.id == _selectedDepartmentId)
        .name;
    final message = await widget.controller.registerStudent(
      firstName: _studentFirstName.text,
      lastName: _studentLastName.text,
      department: department,
      rollNumber: _studentRoll.text,
      email: _studentEmail.text,
      password: _studentPassword.text,
      confirmPassword: _studentConfirmPassword.text,
      profilePicture: _studentProfilePicture?.path,
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
      profilePicture: _teacherProfilePicture?.path,
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
    _selectedDepartmentId = null;
    _studentRoll.clear();
    _studentEmail.clear();
    _studentPassword.clear();
    _studentConfirmPassword.clear();
    _studentProfilePicture = null;
  }

  void _clearTeacherFields() {
    _teacherFirstName.clear();
    _teacherLastName.clear();
    _teacherEmail.clear();
    _teacherPassword.clear();
    _teacherConfirmPassword.clear();
    _teacherProfilePicture = null;
  }

  Future<void> _pickProfilePicture(bool isStudent) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          if (isStudent) {
            _studentProfilePicture = picked;
          } else {
            _teacherProfilePicture = picked;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Image picker not supported on this platform.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}


