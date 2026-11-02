import '../models/app_notification.dart';
import 'api_client.dart';
import 'auth_service.dart';

class NotificationService {
  NotificationService({
    required this.authService,
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final AuthService authService;
  final ApiClient _apiClient;

  Future<NotificationList> fetchNotifications({
    bool? isRead,
    int? limit,
  }) async {
    final String token = await _requireToken();
    final List<String> query = <String>[
      if (isRead != null) 'isRead=$isRead',
      if (limit != null) 'limit=$limit',
    ];
    final String path = query.isEmpty
        ? '/notifications'
        : '/notifications?${query.join('&')}';
    final Map<String, dynamic> data =
        await _apiClient.get(path, token: token);
    return NotificationList.fromJson(data);
  }

  Future<int> fetchUnreadCount() async {
    final String token = await _requireToken();
    final Map<String, dynamic> data =
        await _apiClient.get('/notifications/unread-count', token: token);
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<AppNotification> markRead(String id) async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.patch(
      '/notifications/$id/read',
      token: token,
    );
    final Object? notification = data['notification'];
    if (notification is! Map<String, dynamic>) {
      throw const ApiException('Không đọc được dữ liệu thông báo');
    }
    return AppNotification.fromJson(notification);
  }

  Future<int> markAllRead() async {
    final String token = await _requireToken();
    final Map<String, dynamic> data = await _apiClient.patch(
      '/notifications/read-all',
      token: token,
    );
    return (data['updated'] as num?)?.toInt() ?? 0;
  }

  Future<String> _requireToken() async {
    final String? token = await authService.readToken();
    if (token == null) {
      throw const ApiException(
        'Bạn cần đăng nhập để xem thông báo',
        statusCode: 401,
      );
    }
    return token;
  }
}
