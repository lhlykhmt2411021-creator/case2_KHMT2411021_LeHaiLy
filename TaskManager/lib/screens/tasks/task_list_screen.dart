import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/task_query.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/statistics_service.dart';
import '../../services/task_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_card.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../statistics/statistics_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    super.key,
    required this.authService,
    required this.user,
    this.taskService,
    this.notificationService,
    this.statisticsService,
  });

  final AuthService authService;
  final User user;
  final TaskService? taskService;
  final NotificationService? notificationService;
  final StatisticsService? statisticsService;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskService _taskService =
      widget.taskService ?? TaskService(authService: widget.authService);
  late final NotificationService _notificationService =
      widget.notificationService ??
      NotificationService(authService: widget.authService);
  final ValueNotifier<int> _refreshSignal = ValueNotifier<int>(0);
  final TextEditingController _searchController = TextEditingController();

  TaskListQuery _query = const TaskListQuery();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _refreshSignal.addListener(_loadUnreadCount);
  }

  @override
  void dispose() {
    _refreshSignal.removeListener(_loadUnreadCount);
    _refreshSignal.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final int count = await _notificationService.fetchUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } on ApiException {
      // Bỏ qua lỗi tải số thông báo chưa đọc, không chặn màn hình chính.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationScreen(
          notificationService: _notificationService,
          taskService: _taskService,
          authService: widget.authService,
        ),
      ),
    );
    if (mounted) {
      await _loadUnreadCount();
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(authService: widget.authService, user: widget.user),
      ),
    );
  }

  Future<void> _openStatistics() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StatisticsScreen(
          authService: widget.authService,
          user: widget.user,
          statisticsService: widget.statisticsService,
          taskService: _taskService,
        ),
      ),
    );
  }

  Future<void> _openCreateTask() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TaskFormScreen(taskService: _taskService),
      ),
    );

    if (created == true && mounted) {
      _refreshSignal.value += 1;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã tạo công việc')));
    }
  }

  void _applyQuery(TaskListQuery query) {
    setState(() => _query = query);
  }

  void _submitSearch(String value) {
    _applyQuery(
      TaskListQuery(
        status: _query.status,
        priority: _query.priority,
        keyword: value,
        sortBy: _query.sortBy,
        ascending: _query.ascending,
      ),
    );
  }

  void _setStatus(TaskStatus? status) {
    _applyQuery(
      TaskListQuery(
        status: status,
        priority: _query.priority,
        keyword: _query.keyword,
        sortBy: _query.sortBy,
        ascending: _query.ascending,
      ),
    );
  }

  void _setPriority(TaskPriority? priority) {
    _applyQuery(
      TaskListQuery(
        status: _query.status,
        priority: priority,
        keyword: _query.keyword,
        sortBy: _query.sortBy,
        ascending: _query.ascending,
      ),
    );
  }

  void _setSort(TaskSortField sortBy, bool ascending) {
    _applyQuery(
      TaskListQuery(
        status: _query.status,
        priority: _query.priority,
        keyword: _query.keyword,
        sortBy: sortBy,
        ascending: ascending,
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    _applyQuery(const TaskListQuery(sortBy: TaskSortField.createdAt));
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
              tooltip: 'Cá nhân và thống kê',
              onPressed: _openStatistics,
              icon: const Icon(Icons.insights_outlined),
            ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: _openNotifications,
              icon: Badge.count(
                count: _unreadCount,
                isLabelVisible: _unreadCount > 0,
                child: const Icon(Icons.notifications_none),
              ),
            ),
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
        body: Column(
          children: <Widget>[
            _buildSearchField(),
            _buildFilterBar(context),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _TaskListView(
                    scope: 'created',
                    query: _query,
                    taskService: _taskService,
                    authService: widget.authService,
                    refreshSignal: _refreshSignal,
                  ),
                  _TaskListView(
                    scope: 'assigned',
                    query: _query,
                    taskService: _taskService,
                    authService: widget.authService,
                    refreshSignal: _refreshSignal,
                  ),
                  _TaskListView(
                    scope: 'shared',
                    query: _query,
                    taskService: _taskService,
                    authService: widget.authService,
                    refreshSignal: _refreshSignal,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateTask,
          icon: const Icon(Icons.add),
          label: const Text('Thêm công việc'),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (BuildContext context, TextEditingValue value, _) {
          return TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              hintText: 'Tìm theo tiêu đề hoặc mô tả',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (value.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Xóa từ khóa',
                      onPressed: () {
                        _searchController.clear();
                        _submitSearch('');
                      },
                      icon: const Icon(Icons.close),
                    ),
                  IconButton(
                    tooltip: 'Tìm kiếm',
                    onPressed: () => _submitSearch(_searchController.text),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final List<TaskStatus?> statuses = <TaskStatus?>[
      null,
      TaskStatus.todo,
      TaskStatus.inProgress,
      TaskStatus.completed,
    ];
    const List<String> statusLabels = <String>[
      'Tất cả',
      'Chưa thực hiện',
      'Đang thực hiện',
      'Đã hoàn thành',
    ];

    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            for (int index = 0; index < statuses.length; index += 1)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(statusLabels[index]),
                  selected: _query.status == statuses[index],
                  onSelected: (_) => _setStatus(statuses[index]),
                ),
              ),
            PopupMenuButton<TaskPriority?>(
              tooltip: 'Lọc theo mức ưu tiên',
              onSelected: _setPriority,
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<TaskPriority?>>[
                    const PopupMenuItem<TaskPriority?>(
                      value: null,
                      child: Text('Mọi ưu tiên'),
                    ),
                    const PopupMenuItem<TaskPriority?>(
                      value: TaskPriority.high,
                      child: Text('Cao'),
                    ),
                    const PopupMenuItem<TaskPriority?>(
                      value: TaskPriority.medium,
                      child: Text('Trung bình'),
                    ),
                    const PopupMenuItem<TaskPriority?>(
                      value: TaskPriority.low,
                      child: Text('Thấp'),
                    ),
                  ],
              child: Chip(
                avatar: const Icon(Icons.flag_outlined, size: 18),
                label: Text('Ưu tiên: ${_query.priorityLabel}'),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Sắp xếp danh sách',
              onSelected: (String value) {
                switch (value) {
                  case 'oldest':
                    _setSort(TaskSortField.createdAt, true);
                    break;
                  case 'dueSoon':
                    _setSort(TaskSortField.dueDate, true);
                    break;
                  case 'priorityHigh':
                    _setSort(TaskSortField.priority, false);
                    break;
                  case 'priorityLow':
                    _setSort(TaskSortField.priority, true);
                    break;
                  case 'titleAsc':
                    _setSort(TaskSortField.title, true);
                    break;
                  case 'titleDesc':
                    _setSort(TaskSortField.title, false);
                    break;
                  default:
                    _setSort(TaskSortField.createdAt, false);
                }
              },
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'newest',
                      child: Text('Mới nhất'),
                    ),
                    PopupMenuItem<String>(
                      value: 'oldest',
                      child: Text('Cũ nhất'),
                    ),
                    PopupMenuItem<String>(
                      value: 'dueSoon',
                      child: Text('Hạn gần nhất'),
                    ),
                    PopupMenuItem<String>(
                      value: 'priorityHigh',
                      child: Text('Ưu tiên cao trước'),
                    ),
                    PopupMenuItem<String>(
                      value: 'priorityLow',
                      child: Text('Ưu tiên thấp trước'),
                    ),
                    PopupMenuItem<String>(
                      value: 'titleAsc',
                      child: Text('Tiêu đề A-Z'),
                    ),
                    PopupMenuItem<String>(
                      value: 'titleDesc',
                      child: Text('Tiêu đề Z-A'),
                    ),
                  ],
              child: Chip(
                avatar: const Icon(Icons.sort, size: 18),
                label: Text('Sắp xếp: ${_query.sortLabel}'),
              ),
            ),
            if (_query.hasFilter) ...<Widget>[
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Xóa lọc'),
                onPressed: _clearFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskListView extends StatefulWidget {
  const _TaskListView({
    required this.scope,
    required this.query,
    required this.taskService,
    required this.authService,
    required this.refreshSignal,
  });

  final String scope;
  final TaskListQuery query;
  final TaskService taskService;
  final AuthService authService;
  final Listenable refreshSignal;

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
    widget.refreshSignal.addListener(_onRefreshSignal);
    _load();
  }

  @override
  void didUpdateWidget(covariant _TaskListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _load(showLoading: false);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal.removeListener(_onRefreshSignal);
    super.dispose();
  }

  void _onRefreshSignal() {
    if (mounted) {
      _load(showLoading: false);
    }
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final List<Task> tasks = await widget.taskService.fetchTasks(
        scope: widget.scope,
        query: widget.query,
      );
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
                return TaskCard(task: task, onTap: () => _openDetail(task));
              },
            ),
    );
  }
}
