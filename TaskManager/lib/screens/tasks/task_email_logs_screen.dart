import 'package:flutter/material.dart';

import '../../models/email_log.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../auth/login_screen.dart';

class TaskEmailLogsScreen extends StatefulWidget {
  const TaskEmailLogsScreen({
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
  State<TaskEmailLogsScreen> createState() => _TaskEmailLogsScreenState();
}

class _TaskEmailLogsScreenState extends State<TaskEmailLogsScreen> {
  bool _loading = true;
  String? _retryingId;
  String? _error;
  List<EmailLog> _logs = const <EmailLog>[];

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
      final List<EmailLog> logs =
          await widget.taskService.fetchEmailLogs(widget.taskId);
      if (!mounted) {
        return;
      }
      setState(() {
        _logs = logs;
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

  Future<void> _retry(EmailLog log) async {
    setState(() => _retryingId = log.id);
    try {
      final EmailLog updated = await widget.taskService.retryEmailLog(log.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _logs = _logs
            .map((EmailLog item) => item.id == updated.id ? updated : item)
            .toList();
      });
      _showMessage('Đã gửi lại email (${updated.statusLabel})');
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _retryingId = null);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử email'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Đang tải lịch sử email...');
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
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            widget.taskTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Email được gửi cho người được giao và người được chia sẻ.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Chưa có email nào')),
            )
          else
            ..._logs.map(
              (EmailLog log) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              log.subject,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.statusLabel,
                            style: TextStyle(
                              color: _statusColor(context, log.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Người nhận: ${log.recipientEmail}'),
                      Text('Loại: ${log.eventLabel}'),
                      Text('Số lần gửi: ${log.attempts}/3'),
                      Text(
                        'Tạo lúc: ${DateFormatter.formatDateTime(log.createdAt)}',
                      ),
                      if (log.sentAt != null)
                        Text(
                          'Gửi lúc: ${DateFormatter.formatDateTime(log.sentAt)}',
                        ),
                      if (log.errorMessage.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          log.errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _retryingId != null || !log.canRetry
                              ? null
                              : () => _retry(log),
                          icon: _retryingId == log.id
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(log.canRetry ? 'Gửi lại' : 'Đã hết lượt'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
