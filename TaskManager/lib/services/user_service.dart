import '../models/user.dart';
import 'api_client.dart';
import 'auth_service.dart';

class UserService {
  UserService({
    required this.authService,
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final AuthService authService;
  final ApiClient _apiClient;

  Future<List<User>> searchUsers(String query) async {
    final String keyword = query.trim();
    if (keyword.isEmpty) {
      throw const ApiException('Vui lòng nhập từ khóa tìm kiếm', statusCode: 400);
    }

    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.get(
      '/users/search?q=${Uri.encodeQueryComponent(keyword)}',
      token: token,
    );

    final Object? users = data['users'];
    if (users is! List) {
      return const <User>[];
    }
    return users
        .whereType<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList();
  }

  Future<String> _requireToken() async {
    final String? token = await authService.readToken();
    if (token == null) {
      throw const ApiException(
        'Bạn cần đăng nhập để tìm người dùng',
        statusCode: 401,
      );
    }
    return token;
  }
}
