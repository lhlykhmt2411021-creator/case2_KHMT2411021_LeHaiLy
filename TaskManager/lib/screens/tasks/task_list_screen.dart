import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_card.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    super.key,
    required this.authService,
    required this.user,
  });

  final AuthService authService;
  final User user;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskService _taskService =
      TaskService(authService: widget.authService);

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          authService: widget.authService,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Công việc'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Tài khoản',
              onPressed: _openProfile,
              icon: const Icon(Icons.person_outline),
            ),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Của tôi'),
              Tab(text: 'Được giao'),
              Tab(text: 'Được chia sẻ'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _TaskListView(
              scope: 'created',
              taskService: _taskService,
              authService: widget.authService,
            ),
            _TaskListView(
              scope: 'assigned',
              taskService: _taskService,
              authService: widget.authService,
            ),
            _TaskListView(
              scope: 'shared',
              taskService: _taskService,
              authService: widget.authService,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListView extends StatefulWidget {
  const _TaskListView({
    required this.scope,
    required this.taskService,
    required this.authService,
  });

  final String scope;
  final TaskService taskService;
  final AuthService authService;

  @override
  State<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<_TaskListView>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  String? _error;
  List<Task> _tasks = const <Task>[];

  @override
  bool get wantKeepAlive => true;

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
      final List<Task> tasks =
          await widget.taskService.fetchTasks(scope: widget.scope);
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = tasks;
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
        _goToLogin();
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authService: widget.authService),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _openDetail(Task task) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(
          taskId: task.id,
          taskService: widget.taskService,
          authService: widget.authService,
        ),
      ),
    );
    if (mounted) {
      await _load(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                onPressed: () => _load(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(showLoading: false),
      child: _tasks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 160),
                Center(child: Text('Chưa có công việc')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _tasks.length,
              itemBuilder: (BuildContext context, int index) {
                final Task task = _tasks[index];
                return TaskCard(
                  task: task,
                  onTap: () => _openDetail(task),
                );
              },
            ),
    );
  }
}
