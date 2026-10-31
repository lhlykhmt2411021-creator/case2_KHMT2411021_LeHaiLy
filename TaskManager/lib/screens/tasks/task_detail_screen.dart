import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.taskService,
    required this.authService,
  });

  final String taskId;
  final TaskService taskService;
  final AuthService authService;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _loading = true;
  String? _error;
  Task? _task;

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
      final Task task = await widget.taskService.fetchTask(widget.taskId);
      if (!mounted) {
        return;
      }
      setState(() {
        _task = task;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết công việc')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Đang tải công việc...');
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

    final Task task = _task!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            StatusBadge(status: task.status),
            PriorityBadge(priority: task.priority),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow(label: 'Mô tả', value: task.description.isEmpty ? 'Không có' : task.description),
        _InfoRow(label: 'Ngày bắt đầu', value: DateFormatter.format(task.startDate)),
        _InfoRow(label: 'Hạn hoàn thành', value: DateFormatter.format(task.dueDate)),
        _InfoRow(label: 'Người tạo', value: task.createdBy?.fullName ?? 'Không rõ'),
        _InfoRow(
          label: 'Người phụ trách',
          value: task.primaryAssignee?.fullName ?? 'Chưa chỉ định',
        ),
        _InfoRow(label: 'Vai trò của bạn', value: task.roleLabel),
        const Divider(height: 32),
        Text('Người được giao', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (task.assignees.isEmpty)
          const Text('Chưa có ai')
        else
          ...task.assignees.map(
            (TaskUserRef user) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(user.fullName),
              subtitle: Text(user.email),
            ),
          ),
        const Divider(height: 32),
        Text('Người được chia sẻ', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (task.shares.isEmpty)
          const Text('Chưa có ai')
        else
          ...task.shares.map(
            (TaskShareInfo share) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.share_outlined),
              title: Text(share.user?.fullName ?? 'Không rõ'),
              subtitle: Text('${share.user?.email ?? ''} • ${share.permissionLabel}'),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
