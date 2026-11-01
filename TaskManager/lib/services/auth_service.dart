import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final User user;
}

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const String tokenKey = 'auth_token';

  final ApiClient _apiClient;

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = await _apiClient.post(
      '/auth/register',
      body: <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'password': password,
      },
    );
    return User.fromJson(_asMap(data['user']));
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = await _apiClient.post(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );

    final String token = data['token'] as String? ?? '';
    if (token.isEmpty) {
      throw const ApiException('Không nhận được token đăng nhập');
    }

    await saveToken(token);
    return AuthSession(token: token, user: User.fromJson(_asMap(data['user'])));
  }

  Future<User> fetchCurrentUser(String token) async {
    final Map<String, dynamic> data =
        await _apiClient.get('/auth/me', token: token);
    return User.fromJson(_asMap(data['user']));
  }

  Future<User> updateProfile({
    required String fullName,
    required String avatarUrl,
  }) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.put(
      '/auth/me',
      token: token,
      body: <String, dynamic>{'fullName': fullName, 'avatarUrl': avatarUrl},
    );
    return User.fromJson(_asMap(data['user']));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final String token = await _requireToken();
    await _apiClient.put(
      '/auth/change-password',
      token: token,
      body: <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<String> _requireToken() async {
    final String? token = await readToken();
    if (token == null) {
      throw const ApiException(
        'Bạn cần đăng nhập để thực hiện thao tác này',
        statusCode: 401,
      );
    }
    return token;
  }

  Future<String?> readToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Map<String, dynamic> _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }
}
