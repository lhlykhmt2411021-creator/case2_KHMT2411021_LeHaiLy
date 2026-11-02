import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'user_picker_screen.dart';

class TaskAssigneesScreen extends StatefulWidget {
  const TaskAssigneesScreen({
    super.key,
    required this.task,
    required this.taskService,
    required this.userService,
  });

  final Task task;
  final TaskService taskService;
  final UserService userService;

  @override
  State<TaskAssigneesScreen> createState() => _TaskAssigneesScreenState();
}

class _TaskAssigneesScreenState extends State<TaskAssigneesScreen> {
  late Task _task = widget.task;
  bool _busy = false;

  String? get _primaryId => _task.primaryAssignee?.id;

  Set<String> get _excludedIds {
    final Set<String> ids = _task.assignees.map((TaskUserRef user) => user.id).toSet();
    final String? creatorId = _task.createdBy?.id;
    if (creatorId != null) {
      ids.add(creatorId);
    }
    return ids;
  }

  Future<void> _run(Future<Task> Function() action, String successMessage) async {
    setState(() => _busy = true);
    try {
      final Task task = await action();
      if (!mounted) {
        return;
      }
      setState(() => _task = task);
      _showMessage(successMessage);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addAssignees() async {
    final List<User>? picked = await Navigator.of(context).push<List<User>>(
      MaterialPageRoute<List<User>>(
        builder: (_) => UserPickerScreen(
          userService: widget.userService,
          title: 'Giao việc cho',
          excludedIds: _excludedIds,
        ),
      ),
    );

    if (picked == null || picked.isEmpty) {
      return;
    }

    final List<String> userIds = picked.map((User user) => user.id).toList();
    await _run(
      () => widget.taskService.assignUsers(_task.id, userIds: userIds),
      'Đã giao việc',
    );
  }

  Future<void> _setPrimary(TaskUserRef user) async {
    await _run(
      () => widget.taskService.setPrimaryAssignee(_task.id, user.id),
      'Đã đặt ${user.fullName} làm người phụ trách chính',
    );
  }

  Future<void> _remove(TaskUserRef user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hủy giao việc'),
          content: Text('Hủy giao công việc cho ${user.fullName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hủy giao'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _run(
      () => widget.taskService.removeAssignee(_task.id, user.id),
      'Đã hủy giao việc',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao việc')),
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  'Công việc: ${_task.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Người phụ trách chính: ${_task.primaryAssignee?.fullName ?? 'Chưa chỉ định'}',
                ),
                const Divider(height: 32),
                if (_task.assignees.isEmpty)
                  const Text('Chưa giao việc cho ai')
                else
                  ..._task.assignees.map(_buildAssigneeTile),
              ],
            ),
          ),
          if (_busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addAssignees,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm người'),
      ),
    );
  }

  Widget _buildAssigneeTile(TaskUserRef user) {
    final bool isPrimary = user.id == _primaryId;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(user.fullName),
      subtitle: Text(
        isPrimary ? '${user.email} • Phụ trách chính' : user.email,
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Thao tác với ${user.fullName}',
        onSelected: (String value) {
          switch (value) {
            case 'primary':
              _setPrimary(user);
              break;
            case 'remove':
              _remove(user);
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            if (!isPrimary)
              const PopupMenuItem<String>(
                value: 'primary',
                child: Text('Đặt làm phụ trách chính'),
              ),
            const PopupMenuItem<String>(
              value: 'remove',
              child: Text('Hủy giao việc'),
            ),
          ];
        },
      ),
    );
  }
}
