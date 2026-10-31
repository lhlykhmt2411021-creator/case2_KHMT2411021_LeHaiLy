import 'package:flutter/material.dart';

import '../models/task.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    switch (priority) {
      case TaskPriority.low:
        background = Colors.green.shade50;
        foreground = Colors.green.shade800;
      case TaskPriority.medium:
        background = Colors.orange.shade50;
        foreground = Colors.orange.shade900;
      case TaskPriority.high:
        background = Colors.red.shade50;
        foreground = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.label,
        style: TextStyle(color: foreground, fontSize: 12),
      ),
    );
  }
}
