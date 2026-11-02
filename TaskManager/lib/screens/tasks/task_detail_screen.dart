import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';
import 'task_activity_screen.dart';
import 'task_assignees_screen.dart';
import 'task_email_logs_screen.dart';
import 'task_form_screen.dart';
import 'task_shares_screen.dart';

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
  late final UserService _userService =
      UserService(authService: widget.authService);

  bool _loading = true;
  bool _updating = false;
  String? _error;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _canEdit {
    final String? role = _task?.role;
    return role == 'creator' || role == 'editor';
  }

  bool get _canChangeStatus => _canEdit || _task?.role == 'assignee';

  bool get _canDelete => _task?.role == 'creator';

  bool get _canManage => _task?.role == 'creator';

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

  Future<void> _openEdit() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TaskFormScreen(
          taskService: widget.taskService,
          task: task,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
      _showMessage('Đã cập nhật công việc');
    }
  }

  Future<void> _openAssignees() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskAssigneesScreen(
          task: task,
          taskService: widget.taskService,
          userService: _userService,
        ),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  Future<void> _openShares() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskSharesScreen(
          task: task,
          taskService: widget.taskService,
          userService: _userService,
        ),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  Future<void> _openActivities() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskActivityScreen(
          taskId: task.id,
          taskTitle: task.title,
          taskService: widget.taskService,
          authService: widget.authService,
        ),
      ),
    );
  }

  Future<void> _openEmailLogs() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskEmailLogsScreen(
          taskId: task.id,
          taskTitle: task.title,
          taskService: widget.taskService,
          authService: widget.authService,
        ),
      ),
    );
  }

  Future<void> _changeStatus() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    final TaskStatus? selected = await showModalBottomSheet<TaskStatus>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Đổi trạng thái công việc'),
              ),
              ...TaskStatus.values.map(
                (TaskStatus status) => ListTile(
                  leading: Icon(
                    status == task.status
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(status.label),
                  onTap: () => Navigator.of(context).pop(status),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == task.status) {
      return;
    }

    setState(() => _updating = true);
    try {
      await widget.taskService.updateStatus(task.id, selected);
      if (!mounted) {
        return;
      }
      await _load();
      _showMessage('Đã đổi trạng thái');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Future<void> _delete() async {
    final Task? task = _task;
    if (task == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa công việc'),
          content: Text('Bạn có chắc muốn xóa công việc "${task.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _updating = true);
    try {
      await widget.taskService.deleteTask(task.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _updating = false);
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: <Widget>[
          if (_task != null)
            PopupMenuButton<String>(
              tooltip: 'Thao tác',
              onSelected: (String value) {
                switch (value) {
                  case 'edit':
                    _openEdit();
                    break;
                  case 'status':
                    _changeStatus();
                    break;
                  case 'assign':
                    _openAssignees();
                    break;
                  case 'share':
                    _openShares();
                    break;
                  case 'activity':
                    _openActivities();
                    break;
                  case 'email-logs':
                    _openEmailLogs();
                    break;
                  case 'delete':
                    _delete();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  if (_canEdit)
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Chỉnh sửa công việc'),
                    ),
                  if (_canChangeStatus)
                    const PopupMenuItem<String>(
                      value: 'status',
                      child: Text('Đổi trạng thái'),
                    ),
                  if (_canManage)
                    const PopupMenuItem<String>(
                      value: 'assign',
                      child: Text('Giao việc'),
                    ),
                  if (_canManage)
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('Chia sẻ công việc'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'activity',
                    child: Text('Lịch sử hoạt động'),
                  ),
                  if (_canManage)
                    const PopupMenuItem<String>(
                      value: 'email-logs',
                      child: Text('Lịch sử email'),
                    ),
                  if (_canDelete)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Xóa công việc'),
                    ),
                ];
              },
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          _buildBody(context),
          if (_updating)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
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
