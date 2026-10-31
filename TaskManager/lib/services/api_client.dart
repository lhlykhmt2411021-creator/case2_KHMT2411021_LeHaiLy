import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  Future<Map<String, dynamic>> get(String path, {String? token}) {
    return _send(() => _client.get(_uri(path), headers: _headers(token)));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return _send(
      () => _client.post(
        _uri(path),
        headers: _headers(token),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Map<String, String> _headers(String? token) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    try {
      final http.Response response = await request().timeout(_timeout);
      final Map<String, dynamic> data = _decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      final String message = data['message'] as String? ??
          'Đã có lỗi xảy ra (${response.statusCode})';
      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Kết nối quá thời gian, vui lòng thử lại');
    } on SocketException {
      throw const ApiException('Không kết nối được máy chủ');
    } on http.ClientException {
      throw const ApiException('Không kết nối được máy chủ');
    } on FormatException {
      throw const ApiException('Dữ liệu trả về không hợp lệ');
    }
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final Object? decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  void dispose() {
    _client.close();
  }
}
