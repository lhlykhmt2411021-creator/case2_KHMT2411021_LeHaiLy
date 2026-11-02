import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../auth/login_screen.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    required this.notificationService,
    required this.taskService,
    required this.authService,
  });

  final NotificationService notificationService;
  final TaskService taskService;
  final AuthService authService;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _loading = true;
  bool _markingAll = false;
  String? _error;
  List<AppNotification> _notifications = const <AppNotification>[];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final NotificationList result =
          await widget.notificationService.fetchNotifications();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = result.notifications;
        _unreadCount = result.unreadCount;
        _error = null;
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

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await widget.notificationService.markAllRead();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = _notifications
            .map((AppNotification item) => item.copyWith(isRead: true))
            .toList();
        _unreadCount = 0;
      });
      _showMessage('Đã đánh dấu tất cả là đã đọc');
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _markingAll = false);
      }
    }
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      try {
        await widget.notificationService.markRead(item.id);
        if (!mounted) {
          return;
        }
        setState(() {
          _notifications = _notifications
              .map(
                (AppNotification current) => current.id == item.id
                    ? current.copyWith(isRead: true)
                    : current,
              )
              .toList();
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        });
      } on ApiException catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage(error.message);
      }
    }

    final String? taskId = item.taskId;
    if (taskId == null || taskId.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(
          taskId: taskId,
          taskService: widget.taskService,
          authService: widget.authService,
        ),
      ),
    );
    if (mounted) {
      await _load(showLoading: false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'assigned':
        return Icons.assignment_ind_outlined;
      case 'unassigned':
        return Icons.person_remove_outlined;
      case 'shared':
        return Icons.share_outlined;
      case 'share_updated':
        return Icons.manage_accounts_outlined;
      case 'share_revoked':
        return Icons.link_off;
      case 'status_changed':
        return Icons.sync;
      case 'due_date_changed':
        return Icons.event_outlined;
      case 'task_deleted':
        return Icons.delete_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: <Widget>[
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          _buildBody(context),
          if (_markingAll)
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
      return const LoadingView(message: 'Đang tải thông báo...');
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
      onRefresh: () => _load(showLoading: false),
      child: _notifications.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 160),
                Center(child: Text('Không có thông báo')),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final AppNotification item = _notifications[index];
                return ListTile(
                  onTap: () => _openNotification(item),
                  leading: CircleAvatar(
                    backgroundColor: item.isRead
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      _iconFor(item.type),
                      color: item.isRead
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatDateTime(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: item.isRead
                      ? null
                      : Icon(
                          Icons.circle,
                          size: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                );
              },
            ),
    );
  }
}
