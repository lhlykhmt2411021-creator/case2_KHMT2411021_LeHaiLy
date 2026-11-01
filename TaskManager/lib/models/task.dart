enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, completed }

extension TaskPriorityLabel on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Thấp';
      case TaskPriority.medium:
        return 'Trung bình';
      case TaskPriority.high:
        return 'Cao';
    }
  }

  String get apiValue {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }
}

extension TaskStatusLabel on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'Chưa thực hiện';
      case TaskStatus.inProgress:
        return 'Đang thực hiện';
      case TaskStatus.completed:
        return 'Đã hoàn thành';
    }
  }

  String get apiValue {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }
}

class TaskUserRef {
  const TaskUserRef({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory TaskUserRef.fromJson(Map<String, dynamic> json) {
    return TaskUserRef(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class TaskShareInfo {
  const TaskShareInfo({
    required this.id,
    required this.permission,
    required this.user,
  });

  final String id;
  final String permission;
  final TaskUserRef? user;

  String get permissionLabel {
    return permission == 'editor' ? 'Chỉnh sửa' : 'Chỉ xem';
  }

  factory TaskShareInfo.fromJson(Map<String, dynamic> json) {
    final Object? user = json['user'];
    return TaskShareInfo(
      id: (json['id'] ?? '').toString(),
      permission: json['permission'] as String? ?? 'viewer',
      user: user is Map<String, dynamic> ? TaskUserRef.fromJson(user) : null,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.startDate,
    this.dueDate,
    this.createdAt,
    this.createdBy,
    this.primaryAssignee,
    this.assigneeCount = 0,
    this.assignees = const <TaskUserRef>[],
    this.shares = const <TaskShareInfo>[],
    this.role,
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final TaskUserRef? createdBy;
  final TaskUserRef? primaryAssignee;
  final int assigneeCount;
  final List<TaskUserRef> assignees;
  final List<TaskShareInfo> shares;
  final String? role;

  String get roleLabel {
    switch (role) {
      case 'creator':
        return 'Người tạo';
      case 'assignee':
        return 'Người được giao';
      case 'viewer':
        return 'Người được chia sẻ (chỉ xem)';
      case 'editor':
        return 'Người được chia sẻ (chỉnh sửa)';
      default:
        return 'Không xác định';
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      startDate: _parseDate(json['startDate']),
      dueDate: _parseDate(json['dueDate']),
      createdAt: _parseDate(json['createdAt']),
      createdBy: _parseUser(json['createdBy']),
      primaryAssignee: _parseUser(json['primaryAssignee']),
      assigneeCount: (json['assigneeCount'] as num?)?.toInt() ?? 0,
      assignees: _parseUserList(json['assignees']),
      shares: _parseShareList(json['shares']),
      role: json['role'] as String?,
    );
  }

  static TaskStatus _parseStatus(String? value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.todo;
    }
  }

  static TaskPriority _parsePriority(String? value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  static TaskUserRef? _parseUser(Object? value) {
    return value is Map<String, dynamic> ? TaskUserRef.fromJson(value) : null;
  }

  static List<TaskUserRef> _parseUserList(Object? value) {
    if (value is! List) {
      return const <TaskUserRef>[];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(TaskUserRef.fromJson)
        .toList();
  }

  static List<TaskShareInfo> _parseShareList(Object? value) {
    if (value is! List) {
      return const <TaskShareInfo>[];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(TaskShareInfo.fromJson)
        .toList();
  }
}
