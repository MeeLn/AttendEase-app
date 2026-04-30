import 'package:flutter/material.dart';

import 'core/state/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/auth_page.dart';
import 'modules/shell/app_shell.dart';

class AttendEaseApp extends StatefulWidget {
  const AttendEaseApp({super.key});

  @override
  State<AttendEaseApp> createState() => _AttendEaseAppState();
}

class _AttendEaseAppState extends State<AttendEaseApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'AttendEase',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: !_controller.isReady
                ? const _LoadingScreen()
                : _controller.initializationError != null
                ? _ErrorScreen(message: _controller.initializationError!)
                : _controller.session == null
                ? AuthPage(key: const ValueKey('auth'), controller: _controller)
                : AppShell(
                    key: ValueKey(_controller.session!.role.name),
                    controller: _controller,
                  ),
          ),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to initialize AttendEase.\n\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
