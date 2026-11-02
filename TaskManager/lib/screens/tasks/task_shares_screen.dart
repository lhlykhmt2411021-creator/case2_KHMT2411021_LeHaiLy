import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'user_picker_screen.dart';

class TaskSharesScreen extends StatefulWidget {
  const TaskSharesScreen({
    super.key,
    required this.task,
    required this.taskService,
    required this.userService,
  });

  final Task task;
  final TaskService taskService;
  final UserService userService;

  @override
  State<TaskSharesScreen> createState() => _TaskSharesScreenState();
}

class _TaskSharesScreenState extends State<TaskSharesScreen> {
  late Task _task = widget.task;
  bool _busy = false;

  Set<String> get _excludedIds {
    final Set<String> ids = _task.shares
        .map((TaskShareInfo share) => share.user?.id)
        .whereType<String>()
        .toSet();
    ids.addAll(_task.assignees.map((TaskUserRef user) => user.id));
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

  Future<String?> _choosePermission({String? current}) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Chọn quyền chia sẻ'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('viewer'),
              child: Row(
                children: <Widget>[
                  Icon(
                    current == 'viewer'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 12),
                  const Text('Chỉ xem'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('editor'),
              child: Row(
                children: <Widget>[
                  Icon(
                    current == 'editor'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 12),
                  const Text('Chỉnh sửa'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addShares() async {
    final List<User>? picked = await Navigator.of(context).push<List<User>>(
      MaterialPageRoute<List<User>>(
        builder: (_) => UserPickerScreen(
          userService: widget.userService,
          title: 'Chia sẻ công việc cho',
          excludedIds: _excludedIds,
        ),
      ),
    );

    if (picked == null || picked.isEmpty || !mounted) {
      return;
    }

    final String? permission = await _choosePermission();
    if (permission == null) {
      return;
    }

    await _run(
      () => widget.taskService.addShares(
        _task.id,
        userIds: picked.map((User user) => user.id).toList(),
        permission: permission,
      ),
      'Đã chia sẻ công việc',
    );
  }

  Future<void> _changePermission(TaskShareInfo share) async {
    final String? permission = await _choosePermission(current: share.permission);
    if (permission == null || permission == share.permission) {
      return;
    }

    await _run(
      () => widget.taskService.updateShare(
        _task.id,
        share.id,
        permission: permission,
      ),
      'Đã đổi quyền chia sẻ',
    );
  }

  Future<void> _revoke(TaskShareInfo share) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thu hồi quyền'),
          content: Text(
            'Thu hồi quyền của ${share.user?.fullName ?? 'người dùng này'}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Thu hồi'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _run(
      () => widget.taskService.removeShare(_task.id, share.id),
      'Đã thu hồi quyền',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ công việc')),
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
                const Divider(height: 32),
                if (_task.shares.isEmpty)
                  const Text('Chưa chia sẻ cho ai')
                else
                  ..._task.shares.map(_buildShareTile),
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
        onPressed: _busy ? null : _addShares,
        icon: const Icon(Icons.share),
        label: const Text('Thêm người'),
      ),
    );
  }

  Widget _buildShareTile(TaskShareInfo share) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.share_outlined),
      title: Text(share.user?.fullName ?? 'Không rõ'),
      subtitle: Text('${share.user?.email ?? ''} • ${share.permissionLabel}'),
      trailing: PopupMenuButton<String>(
        tooltip: 'Thao tác với ${share.user?.fullName ?? ''}',
        onSelected: (String value) {
          switch (value) {
            case 'permission':
              _changePermission(share);
              break;
            case 'revoke':
              _revoke(share);
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'permission',
              child: Text(
                share.permission == 'editor'
                    ? 'Chuyển thành chỉ xem'
                    : 'Chuyển thành chỉnh sửa',
              ),
            ),
            const PopupMenuItem<String>(
              value: 'revoke',
              child: Text('Thu hồi quyền'),
            ),
          ];
        },
      ),
    );
  }
}
