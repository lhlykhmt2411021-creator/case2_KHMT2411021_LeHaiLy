import 'task.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.taskId,
    this.actor,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? taskId;
  final TaskUserRef? actor;
  final DateTime? createdAt;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      taskId: taskId,
      actor: actor,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final Object? actor = json['actor'];
    final Object? createdAt = json['createdAt'];
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      taskId: json['taskId'] as String?,
      actor: actor is Map<String, dynamic> ? TaskUserRef.fromJson(actor) : null,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt)?.toLocal() : null,
    );
  }
}

class NotificationList {
  const NotificationList({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AppNotification> notifications;
  final int unreadCount;

  factory NotificationList.fromJson(Map<String, dynamic> json) {
    final Object? items = json['notifications'];
    return NotificationList(
      notifications: items is List
          ? items
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .toList()
          : const <AppNotification>[],
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
