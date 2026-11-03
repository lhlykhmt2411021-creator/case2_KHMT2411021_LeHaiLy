import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/statistics.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/user.dart';
import 'package:task_manager/screens/statistics/statistics_screen.dart';
import 'package:task_manager/services/api_client.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/services/statistics_service.dart';

const User testUser = User(
  id: 'user-1',
  fullName: 'Tran Thi Binh',
  email: 'binh.case2@example.com',
);

Task buildTask({
  String id = 'task-1',
  String title = 'Hop nhom tuan nay',
  TaskPriority priority = TaskPriority.high,
  DateTime? dueDate,
}) {
  return Task(
    id: id,
    title: title,
    description: 'Mô tả',
    status: TaskStatus.todo,
    priority: priority,
    dueDate: dueDate ?? DateTime(2026, 11, 5),
    createdBy: const TaskUserRef(
      id: 'user-1',
      fullName: 'Tran Thi Binh',
      email: 'binh.case2@example.com',
    ),
  );
}

class FakeStatisticsService extends StatisticsService {
  FakeStatisticsService({
    this.tasks,
    this.assignments,
    this.deadlines,
    this.failure,
  }) : super(authService: AuthService());

  final TaskStatistics? tasks;
  final AssignmentStatistics? assignments;
  final DeadlineStatistics? deadlines;
  final ApiException? failure;

  @override
  Future<TaskStatistics> fetchTaskStatistics() async {
    if (failure != null) {
      throw failure!;
    }
    return tasks ?? emptyTaskStatistics;
  }

  @override
  Future<AssignmentStatistics> fetchAssignmentStatistics() async {
    if (failure != null) {
      throw failure!;
    }
    return assignments ??
        const AssignmentStatistics(
          totalAssignees: 0,
          assignments: <AssignmentStat>[],
        );
  }

  @override
  Future<DeadlineStatistics> fetchDeadlineStatistics() async {
    if (failure != null) {
      throw failure!;
    }
    return deadlines ?? emptyDeadlineStatistics;
  }
}

const TaskStatistics emptyTaskStatistics = TaskStatistics(
  total: 0,
  byStatus: <String, int>{},
  byPriority: <String, int>{},
  completed: 0,
  completionRate: 0,
);

const DeadlineStatistics emptyDeadlineStatistics = DeadlineStatistics(
  overdueCount: 0,
  dueSoonCount: 0,
  noDueDateCount: 0,
  completedCount: 0,
  dueSoonDays: 7,
  overdue: <Task>[],
  dueSoon: <Task>[],
);

Future<void> openScreen(
  WidgetTester tester,
  FakeStatisticsService service,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: StatisticsScreen(
        authService: AuthService(),
        user: testUser,
        statisticsService: service,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StatisticsScreen', () {
    testWidgets('hiển thị thông tin cá nhân và số liệu tổng quan', (
      WidgetTester tester,
    ) async {
      final FakeStatisticsService service = FakeStatisticsService(
        tasks: const TaskStatistics(
          total: 5,
          byStatus: <String, int>{'todo': 2, 'in_progress': 1, 'completed': 2},
          byPriority: <String, int>{'high': 2, 'medium': 2, 'low': 1},
          completed: 2,
          completionRate: 40,
        ),
        assignments: const AssignmentStatistics(
          totalAssignees: 1,
          assignments: <AssignmentStat>[
            AssignmentStat(
              userId: 'user-2',
              fullName: 'Nguyen Van An',
              email: 'an.case2@example.com',
              total: 3,
              completed: 1,
              inProgress: 1,
              todo: 1,
              overdue: 1,
            ),
          ],
        ),
        deadlines: DeadlineStatistics(
          overdueCount: 1,
          dueSoonCount: 1,
          noDueDateCount: 0,
          completedCount: 2,
          dueSoonDays: 7,
          overdue: <Task>[
            buildTask(id: 'task-overdue', title: 'Nop bao cao thang'),
          ],
          dueSoon: <Task>[
            buildTask(id: 'task-soon', title: 'Chuan bi slide demo'),
          ],
        ),
      );

      await openScreen(tester, service);

      expect(find.text('Cá nhân và thống kê'), findsOneWidget);
      expect(find.text('Tran Thi Binh'), findsOneWidget);
      expect(find.text('binh.case2@example.com'), findsOneWidget);
      expect(find.text('Tổng công việc'), findsOneWidget);
      expect(find.text('Tỷ lệ hoàn thành'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Theo trạng thái'), findsOneWidget);
      expect(find.text('Theo mức ưu tiên'), findsOneWidget);
      expect(find.text('Phân công theo người'), findsOneWidget);
      expect(find.text('Nguyen Van An'), findsOneWidget);
      expect(find.text('3 việc • 1 hoàn thành • 1 quá hạn'), findsOneWidget);
      expect(find.text('Công việc quá hạn (1)'), findsOneWidget);
      expect(find.text('Nop bao cao thang'), findsOneWidget);
      expect(find.text('Sắp đến hạn trong 7 ngày (1)'), findsOneWidget);
      expect(find.text('Chuan bi slide demo'), findsOneWidget);
    });

    testWidgets('hiển thị trạng thái rỗng khi chưa có dữ liệu', (
      WidgetTester tester,
    ) async {
      await openScreen(tester, FakeStatisticsService());

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Chưa có người được giao'), findsOneWidget);
      expect(find.text('Không có công việc quá hạn'), findsOneWidget);
      expect(find.text('Không có công việc sắp đến hạn'), findsOneWidget);
    });

    testWidgets('hiển thị lỗi và cho phép thử lại', (
      WidgetTester tester,
    ) async {
      await openScreen(
        tester,
        FakeStatisticsService(
          failure: const ApiException(
            'Không tải được thống kê',
            statusCode: 500,
          ),
        ),
      );

      expect(find.text('Không tải được thống kê'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
