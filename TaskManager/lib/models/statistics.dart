import 'task.dart';

class TaskStatistics {
  const TaskStatistics({
    required this.total,
    required this.byStatus,
    required this.byPriority,
    required this.completed,
    required this.completionRate,
  });

  final int total;
  final Map<String, int> byStatus;
  final Map<String, int> byPriority;
  final int completed;
  final int completionRate;

  int countStatus(String status) => byStatus[status] ?? 0;

  int countPriority(String priority) => byPriority[priority] ?? 0;

  factory TaskStatistics.fromJson(Map<String, dynamic> json) {
    return TaskStatistics(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byStatus: _parseCountMap(json['byStatus']),
      byPriority: _parseCountMap(json['byPriority']),
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, int> _parseCountMap(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const <String, int>{};
    }
    return value.map(
      (String key, dynamic item) =>
          MapEntry<String, int>(key, (item as num?)?.toInt() ?? 0),
    );
  }
}

class AssignmentStat {
  const AssignmentStat({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.todo,
    required this.overdue,
  });

  final String userId;
  final String fullName;
  final String email;
  final int total;
  final int completed;
  final int inProgress;
  final int todo;
  final int overdue;

  factory AssignmentStat.fromJson(Map<String, dynamic> json) {
    return AssignmentStat(
      userId: (json['userId'] ?? '').toString(),
      fullName: json['fullName'] as String? ?? 'Không rõ',
      email: json['email'] as String? ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      todo: (json['todo'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
    );
  }
}

class AssignmentStatistics {
  const AssignmentStatistics({
    required this.totalAssignees,
    required this.assignments,
  });

  final int totalAssignees;
  final List<AssignmentStat> assignments;

  factory AssignmentStatistics.fromJson(Map<String, dynamic> json) {
    final Object? items = json['assignments'];
    return AssignmentStatistics(
      totalAssignees: (json['totalAssignees'] as num?)?.toInt() ?? 0,
      assignments: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(AssignmentStat.fromJson)
                .toList()
          : const <AssignmentStat>[],
    );
  }
}

class DeadlineStatistics {
  const DeadlineStatistics({
    required this.overdueCount,
    required this.dueSoonCount,
    required this.noDueDateCount,
    required this.completedCount,
    required this.dueSoonDays,
    required this.overdue,
    required this.dueSoon,
  });

  final int overdueCount;
  final int dueSoonCount;
  final int noDueDateCount;
  final int completedCount;
  final int dueSoonDays;
  final List<Task> overdue;
  final List<Task> dueSoon;

  factory DeadlineStatistics.fromJson(Map<String, dynamic> json) {
    return DeadlineStatistics(
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
      dueSoonCount: (json['dueSoonCount'] as num?)?.toInt() ?? 0,
      noDueDateCount: (json['noDueDateCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      dueSoonDays: (json['dueSoonDays'] as num?)?.toInt() ?? 7,
      overdue: _parseTasks(json['overdue']),
      dueSoon: _parseTasks(json['dueSoon']),
    );
  }

  static List<Task> _parseTasks(Object? value) {
    if (value is! List) {
      return const <Task>[];
    }
    return value.whereType<Map<String, dynamic>>().map(Task.fromJson).toList();
  }
}
