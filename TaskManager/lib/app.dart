import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final AuthService service = authService ?? AuthService();

    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: LoginScreen(authService: service),
    );
  }
}
