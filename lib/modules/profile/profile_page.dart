import 'package:flutter/material.dart';

import '../../core/models/entities.dart';
import '../../core/state/app_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _department;
  late final TextEditingController _rollNumber;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _department = TextEditingController(text: user?.department ?? '');
    _rollNumber = TextEditingController(text: user?.rollNumber ?? '');
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _department.dispose();
    _rollNumber.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.session!;
    final user = widget.controller.currentUser;
    final isAdmin = session.role == UserRole.admin;
    final isStudent = session.role == UserRole.student;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F2C3F),
        elevation: 0,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 1,
      ),
      backgroundColor: const Color(0xFFF4F6F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Name Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFF1E5674).withValues(alpha: 0.1),
                        child: isAdmin
                            ? Image.asset('assets/admin-logo.png',
                                fit: BoxFit.cover)
                            : (user?.profilePicture != null
                                ? Image.network(user!.profilePicture!,
                                    fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      user?.initials ?? '?',
                                      style: const TextStyle(
                                        color: Color(0xFF1E5674),
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin
                                ? 'Administrator'
                                : (user?.fullName ?? '—'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2C3F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? session.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E5674)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              session.role.name.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF1E5674),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isAdmin) ...[
              // Admin: read-only info
              _SectionHeader(
                icon: Icons.info_outline,
                title: 'Account Info',
                subtitle: 'Admin account details are managed by the system.',
              ),
              const SizedBox(height: 12),
              _ReadOnlyField(label: 'Email', value: session.email),
              const SizedBox(height: 12),
              _ReadOnlyField(label: 'Role', value: 'Administrator'),
            ] else ...[
              // Non-admin: editable fields
              _SectionHeader(
                icon: Icons.person_outline,
                title: 'Personal Info',
                subtitle: 'Update your profile details below.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _firstName,
                              label: 'First name',
                              icon: Icons.person_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              controller: _lastName,
                              label: 'Last name',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (isStudent) ...[
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _department,
                          label: 'Department',
                          icon: Icons.account_tree_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _rollNumber,
                          label: 'Roll number',
                          icon: Icons.numbers_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _SectionHeader(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle:
                    'Leave blank to keep your current password.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildPasswordField(
                        controller: _newPassword,
                        label: 'New password',
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _confirmPassword,
                        label: 'Confirm new password',
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1E5674),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E5674)),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFF1E5674)),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF1E5674),
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final user = widget.controller.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final error = await widget.controller.updateUserProfile(
      userId: user.id,
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      department: user.role == UserRole.student ? _department.text : null,
      rollNumber: user.role == UserRole.student ? _rollNumber.text : null,
      newPassword:
          _newPassword.text.isNotEmpty ? _newPassword.text : null,
      confirmPassword:
          _confirmPassword.text.isNotEmpty ? _confirmPassword.text : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    } else {
      _newPassword.clear();
      _confirmPassword.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E5674).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1E5674), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2C3F),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF0F2C3F),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
