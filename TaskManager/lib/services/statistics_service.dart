import '../models/statistics.dart';
import 'api_client.dart';
import 'auth_service.dart';

class StatisticsService {
  StatisticsService({required this.authService, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final AuthService authService;
  final ApiClient _apiClient;

  Future<TaskStatistics> fetchTaskStatistics() async {
    final Map<String, dynamic> data = await _get(
      '/statistics/tasks',
      'statistics',
    );
    return TaskStatistics.fromJson(data);
  }

  Future<AssignmentStatistics> fetchAssignmentStatistics() async {
    final Map<String, dynamic> data = await _get(
      '/statistics/assignments',
      'statistics',
    );
    return AssignmentStatistics.fromJson(data);
  }

  Future<DeadlineStatistics> fetchDeadlineStatistics() async {
    final Map<String, dynamic> data = await _get(
      '/statistics/deadlines',
      'statistics',
    );
    return DeadlineStatistics.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(String path, String key) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.get(path, token: token);
    final Object? value = data[key];
    if (value is! Map<String, dynamic>) {
      throw const ApiException('Không đọc được dữ liệu thống kê');
    }
    return value;
  }

  Future<String> _requireToken() async {
    final String? token = await authService.readToken();
    if (token == null) {
      throw const ApiException(
        'Bạn cần đăng nhập để xem thống kê',
        statusCode: 401,
      );
    }
    return token;
  }
}
