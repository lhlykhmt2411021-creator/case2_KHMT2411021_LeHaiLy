import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'auth/login_screen.dart';
import 'tasks/task_list_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);

    final String? token = await widget.authService.readToken();
    if (!mounted) {
      return;
    }

    if (token == null) {
      _goToLogin();
      return;
    }

    try {
      final user = await widget.authService.fetchCurrentUser(token);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TaskListScreen(
            authService: widget.authService,
            user: user,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.statusCode == 401) {
        await widget.authService.logout();
        if (!mounted) {
          return;
        }
        _goToLogin();
        return;
      }
      setState(() => _error = error.message);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _bootstrap,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
