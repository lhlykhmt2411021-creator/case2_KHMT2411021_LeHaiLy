import 'task.dart';

class TaskActivity {
  const TaskActivity({
    required this.id,
    required this.action,
    required this.details,
    this.user,
    this.createdAt,
  });

  final String id;
  final String action;
  final String details;
  final TaskUserRef? user;
  final DateTime? createdAt;

  String get actionLabel {
    switch (action) {
      case 'created':
        return 'Đã tạo công việc';
      case 'updated':
        return 'Đã cập nhật công việc';
      case 'status_changed':
        return 'Đổi trạng thái';
      case 'deleted':
        return 'Đã xóa công việc';
      case 'assigned':
        return 'Giao việc';
      case 'unassigned':
        return 'Hủy giao việc';
      case 'shared':
        return 'Chia sẻ công việc';
      case 'share_updated':
        return 'Đổi quyền chia sẻ';
      case 'share_revoked':
        return 'Thu hồi quyền';
      default:
        return action;
    }
  }

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    final Object? user = json['user'];
    final Object? createdAt = json['createdAt'];
    return TaskActivity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      action: json['action'] as String? ?? '',
      details: json['details'] as String? ?? '',
      user: user is Map<String, dynamic> ? TaskUserRef.fromJson(user) : null,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt)?.toLocal() : null,
    );
  }
}
