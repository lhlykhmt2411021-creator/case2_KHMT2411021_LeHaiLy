import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/statistics.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/task_query.dart';
import 'package:task_manager/models/user.dart';
import 'package:task_manager/screens/tasks/task_list_screen.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/services/notification_service.dart';
import 'package:task_manager/services/statistics_service.dart';
import 'package:task_manager/services/task_service.dart';

const User testUser = User(
  id: 'user-1',
  fullName: 'Tran Thi Binh',
  email: 'binh.case2@example.com',
);

class FakeTaskService extends TaskService {
  FakeTaskService() : super(authService: AuthService());

  final Map<String, TaskListQuery> queries = <String, TaskListQuery>{};

  @override
  Future<List<Task>> fetchTasks({
    required String scope,
    TaskListQuery query = const TaskListQuery(),
  }) async {
    queries[scope] = query;
    return const <Task>[];
  }
}

class FakeNotificationService extends NotificationService {
  FakeNotificationService() : super(authService: AuthService());

  @override
  Future<int> fetchUnreadCount() async => 0;
}

class FakeStatisticsService extends StatisticsService {
  FakeStatisticsService() : super(authService: AuthService());

  @override
  Future<TaskStatistics> fetchTaskStatistics() async {
    return const TaskStatistics(
      total: 0,
      byStatus: <String, int>{},
      byPriority: <String, int>{},
      completed: 0,
      completionRate: 0,
    );
  }

  @override
  Future<AssignmentStatistics> fetchAssignmentStatistics() async {
    return const AssignmentStatistics(
      totalAssignees: 0,
      assignments: <AssignmentStat>[],
    );
  }

  @override
  Future<DeadlineStatistics> fetchDeadlineStatistics() async {
    return const DeadlineStatistics(
      overdueCount: 0,
      dueSoonCount: 0,
      noDueDateCount: 0,
      completedCount: 0,
      dueSoonDays: 7,
      overdue: <Task>[],
      dueSoon: <Task>[],
    );
  }
}

Future<void> openScreen(
  WidgetTester tester,
  FakeTaskService taskService,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TaskListScreen(
        authService: AuthService(),
        user: testUser,
        taskService: taskService,
        notificationService: FakeNotificationService(),
        statisticsService: FakeStatisticsService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapFilter(WidgetTester tester, String label) async {
  final Finder finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('TaskListScreen tìm kiếm, lọc, sắp xếp', () {
    testWidgets('tìm kiếm theo từ khóa gửi đúng tham số', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService();
      await openScreen(tester, taskService);

      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.tap(find.byTooltip('Tìm kiếm'));
      await tester.pumpAndSettle();

      expect(taskService.queries['created']!.keyword, 'alpha');
      expect(find.text('Xóa lọc'), findsOneWidget);
    });

    testWidgets('lọc theo trạng thái', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService();
      await openScreen(tester, taskService);

      await tapFilter(tester, 'Đã hoàn thành');

      expect(taskService.queries['created']!.status, TaskStatus.completed);
      expect(find.text('Xóa lọc'), findsOneWidget);
    });

    testWidgets('lọc theo mức ưu tiên', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService();
      await openScreen(tester, taskService);

      await tapFilter(tester, 'Ưu tiên: Mọi ưu tiên');
      await tester.tap(find.text('Cao').last);
      await tester.pumpAndSettle();

      expect(taskService.queries['created']!.priority, TaskPriority.high);
      expect(find.text('Ưu tiên: Cao'), findsOneWidget);
    });

    testWidgets('sắp xếp theo tiêu đề', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService();
      await openScreen(tester, taskService);

      await tapFilter(tester, 'Sắp xếp: Mới nhất');
      await tester.tap(find.text('Tiêu đề A-Z'));
      await tester.pumpAndSettle();

      final TaskListQuery query = taskService.queries['created']!;
      expect(query.sortBy, TaskSortField.title);
      expect(query.ascending, isTrue);
      expect(find.text('Sắp xếp: Tiêu đề A-Z'), findsOneWidget);
    });

    testWidgets('xóa lọc đưa danh sách về mặc định', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService();
      await openScreen(tester, taskService);

      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.tap(find.byTooltip('Tìm kiếm'));
      await tester.pumpAndSettle();
      await tapFilter(tester, 'Đã hoàn thành');

      await tapFilter(tester, 'Xóa lọc');

      final TaskListQuery query = taskService.queries['created']!;
      expect(query.keyword, isEmpty);
      expect(query.status, isNull);
      expect(query.sortBy, TaskSortField.createdAt);
      expect(find.text('Xóa lọc'), findsNothing);
    });

    testWidgets('mở màn hình cá nhân và thống kê', (WidgetTester tester) async {
      await openScreen(tester, FakeTaskService());

      await tester.tap(find.byTooltip('Cá nhân và thống kê'));
      await tester.pumpAndSettle();

      expect(find.text('Cá nhân và thống kê'), findsOneWidget);
      expect(find.text('Tổng công việc'), findsOneWidget);
    });
  });
}
