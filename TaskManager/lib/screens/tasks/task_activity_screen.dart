import 'package:flutter/material.dart';

import '../../models/task_activity.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../auth/login_screen.dart';

class TaskActivityScreen extends StatefulWidget {
  const TaskActivityScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.taskService,
    required this.authService,
  });

  final String taskId;
  final String taskTitle;
  final TaskService taskService;
  final AuthService authService;

  @override
  State<TaskActivityScreen> createState() => _TaskActivityScreenState();
}

class _TaskActivityScreenState extends State<TaskActivityScreen> {
  bool _loading = true;
  String? _error;
  List<TaskActivity> _activities = const <TaskActivity>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<TaskActivity> activities =
          await widget.taskService.fetchActivities(widget.taskId);
      if (!mounted) {
        return;
      }
      setState(() {
        _activities = activities;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.statusCode == 401) {
        await widget.authService.logout();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => LoginScreen(authService: widget.authService),
          ),
          (Route<dynamic> route) => false,
        );
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline;
      case 'updated':
        return Icons.edit_outlined;
      case 'status_changed':
        return Icons.sync;
      case 'deleted':
        return Icons.delete_outline;
      case 'assigned':
        return Icons.person_add_alt_1_outlined;
      case 'unassigned':
        return Icons.person_remove_outlined;
      case 'shared':
        return Icons.share_outlined;
      case 'share_updated':
        return Icons.manage_accounts_outlined;
      case 'share_revoked':
        return Icons.link_off;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Đang tải lịch sử...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              widget.taskTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Chưa có hoạt động nào')),
            )
          else
            ..._activities.map(
              (TaskActivity activity) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(_iconFor(activity.action), size: 20),
                ),
                title: Text(activity.actionLabel),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (activity.details.isNotEmpty) Text(activity.details),
                    const SizedBox(height: 2),
                    Text(
                      '${activity.user?.fullName ?? 'Không rõ'} • '
                      '${DateFormatter.formatDateTime(activity.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
