import 'task.dart';

enum TaskSortField { createdAt, dueDate, priority, title }

extension TaskSortFieldInfo on TaskSortField {
  String get apiValue {
    switch (this) {
      case TaskSortField.createdAt:
        return 'createdAt';
      case TaskSortField.dueDate:
        return 'dueDate';
      case TaskSortField.priority:
        return 'priority';
      case TaskSortField.title:
        return 'title';
    }
  }
}

class TaskListQuery {
  const TaskListQuery({
    this.status,
    this.priority,
    this.keyword = '',
    this.sortBy = TaskSortField.createdAt,
    this.ascending = false,
  });

  final TaskStatus? status;
  final TaskPriority? priority;
  final String keyword;
  final TaskSortField sortBy;
  final bool ascending;

  bool get hasFilter =>
      status != null || priority != null || keyword.trim().isNotEmpty;

  String get sortLabel {
    switch (sortBy) {
      case TaskSortField.createdAt:
        return ascending ? 'Cũ nhất' : 'Mới nhất';
      case TaskSortField.dueDate:
        return ascending ? 'Hạn xa nhất' : 'Hạn gần nhất';
      case TaskSortField.priority:
        return ascending ? 'Ưu tiên thấp trước' : 'Ưu tiên cao trước';
      case TaskSortField.title:
        return ascending ? 'Tiêu đề A-Z' : 'Tiêu đề Z-A';
    }
  }

  String get priorityLabel {
    if (priority == null) {
      return 'Mọi ưu tiên';
    }
    return priority!.label;
  }

  @override
  bool operator ==(Object other) {
    return other is TaskListQuery &&
        other.status == status &&
        other.priority == priority &&
        other.keyword == keyword &&
        other.sortBy == sortBy &&
        other.ascending == ascending;
  }

  @override
  int get hashCode => Object.hash(status, priority, keyword, sortBy, ascending);
}
