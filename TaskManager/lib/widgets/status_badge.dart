import 'package:flutter/material.dart';

import '../models/task.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    switch (status) {
      case TaskStatus.todo:
        background = Colors.grey.shade200;
        foreground = Colors.grey.shade800;
      case TaskStatus.inProgress:
        background = Colors.blue.shade50;
        foreground = Colors.blue.shade800;
      case TaskStatus.completed:
        background = Colors.green.shade50;
        foreground = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: foreground, fontSize: 12),
      ),
    );
  }
}
