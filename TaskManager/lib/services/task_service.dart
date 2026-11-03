import '../models/email_log.dart';
import '../models/task.dart';
import '../models/task_activity.dart';
import '../models/task_query.dart';
import 'api_client.dart';
import 'auth_service.dart';

class TaskService {
  TaskService({required this.authService, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final AuthService authService;
  final ApiClient _apiClient;

  Future<List<Task>> fetchTasks({
    required String scope,
    TaskListQuery query = const TaskListQuery(),
  }) async {
    final String token = await _requireToken();
    final List<String> params = <String>['scope=$scope'];
    if (query.status != null) {
      params.add('status=${query.status!.apiValue}');
    }
    if (query.priority != null) {
      params.add('priority=${query.priority!.apiValue}');
    }
    final String keyword = query.keyword.trim();
    if (keyword.isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(keyword)}');
    }
    params.add('sortBy=${query.sortBy.apiValue}');
    params.add('order=${query.ascending ? 'asc' : 'desc'}');

    final Map<String, dynamic> data = await _apiClient.get(
      '/tasks?${params.join('&')}',
      token: token,
    );
    return _parseTasks(data['tasks']);
  }

  Future<Task> fetchTask(String id) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.get(
      '/tasks/$id',
      token: token,
    );
    return _parseTask(data['task']);
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.post(
      '/tasks',
      token: token,
      body: <String, dynamic>{
        'title': title,
        'description': description,
        'priority': priority.apiValue,
        'startDate': _formatDate(startDate),
        'dueDate': _formatDate(dueDate),
      },
    );
    return _parseTask(data['task']);
  }

  Future<Task> updateTask(
    String id, {
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.put(
      '/tasks/$id',
      token: token,
      body: <String, dynamic>{
        'title': title,
        'description': description,
        'priority': priority.apiValue,
        'startDate': _formatDate(startDate),
        'dueDate': _formatDate(dueDate),
      },
    );
    return _parseTask(data['task']);
  }

  Future<Task> updateStatus(String id, TaskStatus status) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.patch(
      '/tasks/$id/status',
      token: token,
      body: <String, dynamic>{'status': status.apiValue},
    );
    return _parseTask(data['task']);
  }

  Future<void> deleteTask(String id) async {
    final String token = await _requireToken();
    await _apiClient.delete('/tasks/$id', token: token);
  }

  Future<Task> assignUsers(
    String id, {
    required List<String> userIds,
    String? primaryAssigneeId,
  }) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.post(
      '/tasks/$id/assignees',
      token: token,
      body: <String, dynamic>{
        'userIds': userIds,
        'primaryAssigneeId': ?primaryAssigneeId,
      },
    );
    return _parseTask(data['task']);
  }

  Future<Task> setPrimaryAssignee(String id, String userId) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.patch(
      '/tasks/$id/assignees/$userId',
      token: token,
    );
    return _parseTask(data['task']);
  }

  Future<Task> removeAssignee(String id, String userId) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.delete(
      '/tasks/$id/assignees/$userId',
      token: token,
    );
    return _parseTask(data['task']);
  }

  Future<Task> addShares(
    String id, {
    required List<String> userIds,
    required String permission,
  }) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.post(
      '/tasks/$id/shares',
      token: token,
      body: <String, dynamic>{'userIds': userIds, 'permission': permission},
    );
    return _parseTask(data['task']);
  }

  Future<Task> updateShare(
    String id,
    String shareId, {
    required String permission,
  }) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.patch(
      '/tasks/$id/shares/$shareId',
      token: token,
      body: <String, dynamic>{'permission': permission},
    );
    return _parseTask(data['task']);
  }

  Future<Task> removeShare(String id, String shareId) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.delete(
      '/tasks/$id/shares/$shareId',
      token: token,
    );
    return _parseTask(data['task']);
  }

  Future<List<TaskActivity>> fetchActivities(String id) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.get(
      '/tasks/$id/activities',
      token: token,
    );
    final Object? activities = data['activities'];
    if (activities is! List) {
      return const <TaskActivity>[];
    }
    return activities
        .whereType<Map<String, dynamic>>()
        .map(TaskActivity.fromJson)
        .toList();
  }

  Future<List<EmailLog>> fetchEmailLogs(String id) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.get(
      '/tasks/$id/email-logs',
      token: token,
    );
    final Object? logs = data['emailLogs'];
    if (logs is! List) {
      return const <EmailLog>[];
    }
    return logs
        .whereType<Map<String, dynamic>>()
        .map(EmailLog.fromJson)
        .toList();
  }

  Future<EmailLog> retryEmailLog(String logId) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.post(
      '/email-logs/$logId/retry',
      token: token,
    );
    final Object? log = data['emailLog'];
    if (log is! Map<String, dynamic>) {
      throw const ApiException('Không đọc được dữ liệu email');
    }
    return EmailLog.fromJson(log);
  }

  Future<String> _requireToken() async {
    final String? token = await authService.readToken();
    if (token == null) {
      throw const ApiException(
        'Bạn cần đăng nhập để xem công việc',
        statusCode: 401,
      );
    }
    return token;
  }

  Task _parseTask(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const ApiException('Không đọc được dữ liệu công việc');
    }
    return Task.fromJson(value);
  }

  List<Task> _parseTasks(Object? value) {
    if (value is! List) {
      return const <Task>[];
    }
    return value.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
  }

  String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }
}
