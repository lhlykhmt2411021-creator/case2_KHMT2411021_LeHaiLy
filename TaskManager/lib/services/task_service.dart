import '../models/task.dart';
import 'api_client.dart';
import 'auth_service.dart';

class TaskService {
  TaskService({
    required this.authService,
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final AuthService authService;
  final ApiClient _apiClient;

  Future<List<Task>> fetchTasks({required String scope}) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data =
        await _apiClient.get('/tasks?scope=$scope', token: token);
    return _parseTasks(data['tasks']);
  }

  Future<Task> fetchTask(String id) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data =
        await _apiClient.get('/tasks/$id', token: token);
    final Object? task = data['task'];
    if (task is! Map<String, dynamic>) {
      throw const ApiException('Không đọc được dữ liệu công việc');
    }
    return Task.fromJson(task);
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

  List<Task> _parseTasks(Object? value) {
    if (value is! List) {
      return const <Task>[];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .toList();
  }
}
