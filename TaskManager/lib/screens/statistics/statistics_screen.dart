import 'package:flutter/material.dart';

import '../../models/statistics.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../auth/login_screen.dart';
import '../tasks/task_detail_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.authService,
    required this.user,
    this.statisticsService,
    this.taskService,
  });

  final AuthService authService;
  final User user;
  final StatisticsService? statisticsService;
  final TaskService? taskService;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final StatisticsService _statisticsService =
      widget.statisticsService ??
      StatisticsService(authService: widget.authService);

  bool _loading = true;
  String? _error;
  TaskStatistics? _tasks;
  AssignmentStatistics? _assignments;
  DeadlineStatistics? _deadlines;

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
      final TaskStatistics tasks = await _statisticsService
          .fetchTaskStatistics();
      final AssignmentStatistics assignments = await _statisticsService
          .fetchAssignmentStatistics();
      final DeadlineStatistics deadlines = await _statisticsService
          .fetchDeadlineStatistics();
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = tasks;
        _assignments = assignments;
        _deadlines = deadlines;
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

  Future<void> _openTask(Task task) async {
    final TaskService? taskService = widget.taskService;
    if (taskService == null) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(
          taskId: task.id,
          taskService: taskService,
          authService: widget.authService,
        ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân và thống kê')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Đang tải thống kê...');
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
              FilledButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final TaskStatistics tasks = _tasks ?? _emptyTasks;
    final AssignmentStatistics assignments =
        _assignments ??
        const AssignmentStatistics(
          totalAssignees: 0,
          assignments: <AssignmentStat>[],
        );
    final DeadlineStatistics deadlines = _deadlines ?? _emptyDeadlines;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildProfileCard(context),
          const SizedBox(height: 16),
          _buildOverviewGrid(context, tasks, deadlines),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Theo trạng thái'),
          _buildCountRow(context, <String, int>{
            'Chưa thực hiện': tasks.countStatus('todo'),
            'Đang thực hiện': tasks.countStatus('in_progress'),
            'Đã hoàn thành': tasks.countStatus('completed'),
          }),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Theo mức ưu tiên'),
          _buildCountRow(context, <String, int>{
            'Cao': tasks.countPriority('high'),
            'Trung bình': tasks.countPriority('medium'),
            'Thấp': tasks.countPriority('low'),
          }),
          const SizedBox(height: 16),
          _sectionTitle(context, 'Phân công theo người'),
          if (assignments.assignments.isEmpty)
            _emptyText(context, 'Chưa có người được giao')
          else
            ...assignments.assignments.map(
              (AssignmentStat item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(_initial(item.fullName))),
                  title: Text(item.fullName),
                  subtitle: Text(
                    '${item.total} việc • ${item.completed} hoàn thành • '
                    '${item.overdue} quá hạn',
                  ),
                  trailing: Text('${item.total}'),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _sectionTitle(
            context,
            'Công việc quá hạn (${deadlines.overdueCount})',
          ),
          if (deadlines.overdue.isEmpty)
            _emptyText(context, 'Không có công việc quá hạn')
          else
            ...deadlines.overdue.map(
              (Task task) => _buildDeadlineCard(context, task, isOverdue: true),
            ),
          const SizedBox(height: 16),
          _sectionTitle(
            context,
            'Sắp đến hạn trong ${deadlines.dueSoonDays} ngày '
            '(${deadlines.dueSoonCount})',
          ),
          if (deadlines.dueSoon.isEmpty)
            _emptyText(context, 'Không có công việc sắp đến hạn')
          else
            ...deadlines.dueSoon.map(
              (Task task) =>
                  _buildDeadlineCard(context, task, isOverdue: false),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              child: Text(
                _initial(widget.user.fullName),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.user.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.user.email),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context,
    TaskStatistics tasks,
    DeadlineStatistics deadlines,
  ) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'Tổng công việc',
                value: '${tasks.total}',
                icon: Icons.assignment_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Hoàn thành',
                value: '${tasks.completed}',
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatTile(
                label: 'Tỷ lệ hoàn thành',
                value: '${tasks.completionRate}%',
                icon: Icons.percent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Quá hạn',
                value: '${deadlines.overdueCount}',
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildCountRow(BuildContext context, Map<String, int> counts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: counts.entries.map((MapEntry<String, int> entry) {
            return Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(
    BuildContext context,
    Task task, {
    required bool isOverdue,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: widget.taskService == null ? null : () => _openTask(task),
        leading: Icon(
          isOverdue ? Icons.error_outline : Icons.schedule,
          color: isOverdue ? Theme.of(context).colorScheme.error : null,
        ),
        title: Text(task.title),
        subtitle: Text(
          'Hạn: ${DateFormatter.format(task.dueDate)} • ${task.priority.label}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _emptyText(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  String _initial(String name) {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  static const TaskStatistics _emptyTasks = TaskStatistics(
    total: 0,
    byStatus: <String, int>{},
    byPriority: <String, int>{},
    completed: 0,
    completionRate: 0,
  );

  static const DeadlineStatistics _emptyDeadlines = DeadlineStatistics(
    overdueCount: 0,
    dueSoonCount: 0,
    noDueDateCount: 0,
    completedCount: 0,
    dueSoonDays: 7,
    overdue: <Task>[],
    dueSoon: <Task>[],
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
