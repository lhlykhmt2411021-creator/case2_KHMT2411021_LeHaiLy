import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/app_notification.dart';
import 'package:task_manager/models/email_log.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/task_activity.dart';
import 'package:task_manager/screens/notifications/notification_screen.dart';
import 'package:task_manager/screens/tasks/task_activity_screen.dart';
import 'package:task_manager/screens/tasks/task_email_logs_screen.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/services/notification_service.dart';
import 'package:task_manager/services/task_service.dart';

const TaskUserRef actorRef = TaskUserRef(
  id: 'user-creator',
  fullName: 'Tran Thi Binh',
  email: 'binh.case2@example.com',
);

Task buildTask() {
  return const Task(
    id: 'task-1',
    title: 'Hop nhom tuan nay',
    description: 'Mô tả',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    createdBy: actorRef,
    role: 'creator',
  );
}

class FakeNotificationService extends NotificationService {
  FakeNotificationService({
    required this.items,
    required this.unreadCount,
  }) : super(authService: AuthService());

  List<AppNotification> items;
  int unreadCount;
  final List<String> markedIds = <String>[];
  int markAllCalls = 0;

  @override
  Future<NotificationList> fetchNotifications({bool? isRead, int? limit}) async {
    return NotificationList(notifications: items, unreadCount: unreadCount);
  }

  @override
  Future<int> fetchUnreadCount() async => unreadCount;

  @override
  Future<AppNotification> markRead(String id) async {
    markedIds.add(id);
    items = items
        .map(
          (AppNotification item) =>
              item.id == id ? item.copyWith(isRead: true) : item,
        )
        .toList();
    if (unreadCount > 0) {
      unreadCount -= 1;
    }
    return items.firstWhere((AppNotification item) => item.id == id);
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls += 1;
    items = items
        .map((AppNotification item) => item.copyWith(isRead: true))
        .toList();
    unreadCount = 0;
    return items.length;
  }
}

class FakeTaskService extends TaskService {
  FakeTaskService({
    Task? task,
    this.activities = const <TaskActivity>[],
    this.logs = const <EmailLog>[],
  })  : task = task ?? buildTask(),
        super(authService: AuthService());

  Task task;
  List<TaskActivity> activities;
  List<EmailLog> logs;
  String? retriedLogId;

  @override
  Future<Task> fetchTask(String id) async => task;

  @override
  Future<List<TaskActivity>> fetchActivities(String id) async => activities;

  @override
  Future<List<EmailLog>> fetchEmailLogs(String id) async => logs;

  @override
  Future<EmailLog> retryEmailLog(String logId) async {
    retriedLogId = logId;
    final EmailLog current = logs.firstWhere((EmailLog log) => log.id == logId);
    final EmailLog updated = EmailLog(
      id: current.id,
      taskId: current.taskId,
      recipientEmail: current.recipientEmail,
      eventType: current.eventType,
      subject: current.subject,
      status: current.status,
      attempts: current.attempts + 1,
      errorMessage: current.errorMessage,
      createdAt: current.createdAt,
    );
    logs = logs
        .map((EmailLog log) => log.id == logId ? updated : log)
        .toList();
    return updated;
  }
}

AppNotification buildNotification({
  String id = 'noti-1',
  String type = 'assigned',
  String title = 'Bạn được giao công việc',
  String message = 'Bạn được giao công việc "Hop nhom tuan nay".',
  bool isRead = false,
  String? taskId = 'task-1',
}) {
  return AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    isRead: isRead,
    taskId: taskId,
    actor: actorRef,
    createdAt: DateTime(2026, 11, 2, 9, 30),
  );
}

void main() {
  group('NotificationScreen', () {
    testWidgets('hiển thị danh sách thông báo và nút đọc tất cả', (
      WidgetTester tester,
    ) async {
      final FakeNotificationService service = FakeNotificationService(
        items: <AppNotification>[
          buildNotification(),
          buildNotification(
            id: 'noti-2',
            type: 'shared',
            title: 'Công việc được chia sẻ với bạn',
            isRead: true,
          ),
        ],
        unreadCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            notificationService: service,
            taskService: FakeTaskService(),
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Bạn được giao công việc'), findsOneWidget);
      expect(find.text('Công việc được chia sẻ với bạn'), findsOneWidget);
      expect(find.text('Đọc tất cả'), findsOneWidget);
    });

    testWidgets('đọc tất cả thông báo', (WidgetTester tester) async {
      final FakeNotificationService service = FakeNotificationService(
        items: <AppNotification>[buildNotification()],
        unreadCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            notificationService: service,
            taskService: FakeTaskService(),
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đọc tất cả'));
      await tester.pumpAndSettle();

      expect(service.markAllCalls, 1);
      expect(find.text('Đọc tất cả'), findsNothing);
      expect(find.text('Đã đánh dấu tất cả là đã đọc'), findsOneWidget);
    });

    testWidgets('mở thông báo đánh dấu đã đọc và mở chi tiết công việc', (
      WidgetTester tester,
    ) async {
      final FakeNotificationService service = FakeNotificationService(
        items: <AppNotification>[buildNotification()],
        unreadCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            notificationService: service,
            taskService: FakeTaskService(),
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bạn được giao công việc'));
      await tester.pumpAndSettle();

      expect(service.markedIds, <String>['noti-1']);
      expect(find.text('Chi tiết công việc'), findsOneWidget);
      expect(find.text('Hop nhom tuan nay'), findsOneWidget);
    });

    testWidgets('thông báo công việc đã xóa không mở chi tiết', (
      WidgetTester tester,
    ) async {
      final FakeNotificationService service = FakeNotificationService(
        items: <AppNotification>[
          buildNotification(
            type: 'task_deleted',
            title: 'Công việc đã bị xóa',
            taskId: null,
          ),
        ],
        unreadCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            notificationService: service,
            taskService: FakeTaskService(),
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Công việc đã bị xóa'));
      await tester.pumpAndSettle();

      expect(service.markedIds, <String>['noti-1']);
      expect(find.text('Chi tiết công việc'), findsNothing);
    });

    testWidgets('hiển thị trạng thái rỗng khi không có thông báo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            notificationService: FakeNotificationService(
              items: const <AppNotification>[],
              unreadCount: 0,
            ),
            taskService: FakeTaskService(),
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không có thông báo'), findsOneWidget);
      expect(find.text('Đọc tất cả'), findsNothing);
    });
  });

  group('TaskActivityScreen', () {
    testWidgets('hiển thị lịch sử hoạt động', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService(
        activities: <TaskActivity>[
          TaskActivity(
            id: 'act-1',
            action: 'assigned',
            details: 'Đã giao việc cho Nguyen Van An',
            user: actorRef,
            createdAt: DateTime(2026, 11, 2, 9, 30),
          ),
          TaskActivity(
            id: 'act-2',
            action: 'status_changed',
            details: 'Trạng thái: todo -> in_progress',
            user: actorRef,
            createdAt: DateTime(2026, 11, 2, 10, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskActivityScreen(
            taskId: 'task-1',
            taskTitle: 'Hop nhom tuan nay',
            taskService: taskService,
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử hoạt động'), findsOneWidget);
      expect(find.text('Giao việc'), findsOneWidget);
      expect(find.text('Đổi trạng thái'), findsOneWidget);
      expect(find.text('Đã giao việc cho Nguyen Van An'), findsOneWidget);
      expect(find.text('Trạng thái: todo -> in_progress'), findsOneWidget);
    });

    testWidgets('hiển thị trạng thái rỗng khi chưa có hoạt động', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskActivityScreen(
            taskId: 'task-1',
            taskTitle: 'Hop nhom tuan nay',
            taskService: FakeTaskService(),
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có hoạt động nào'), findsOneWidget);
    });
  });

  group('TaskEmailLogsScreen', () {
    EmailLog buildLog({
      String id = 'log-1',
      String status = 'skipped',
      int attempts = 1,
      String errorMessage = 'Chưa cấu hình SMTP',
    }) {
      return EmailLog(
        id: id,
        taskId: 'task-1',
        recipientEmail: 'an.case2@example.com',
        eventType: 'assigned',
        subject: '[Task Manager] Bạn được giao công việc: Hop nhom tuan nay',
        status: status,
        attempts: attempts,
        errorMessage: errorMessage,
        createdAt: DateTime(2026, 11, 2, 9, 30),
      );
    }

    testWidgets('hiển thị lịch sử email và trạng thái gửi', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(
        logs: <EmailLog>[buildLog()],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskEmailLogsScreen(
            taskId: 'task-1',
            taskTitle: 'Hop nhom tuan nay',
            taskService: taskService,
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử email'), findsOneWidget);
      expect(find.text('Người nhận: an.case2@example.com'), findsOneWidget);
      expect(find.text('Loại: Giao việc'), findsOneWidget);
      expect(find.text('Số lần gửi: 1/3'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(find.text('Chưa cấu hình SMTP'), findsOneWidget);
    });

    testWidgets('gửi lại email cập nhật số lần gửi', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(
        logs: <EmailLog>[buildLog()],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskEmailLogsScreen(
            taskId: 'task-1',
            taskTitle: 'Hop nhom tuan nay',
            taskService: taskService,
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gửi lại'));
      await tester.pumpAndSettle();

      expect(taskService.retriedLogId, 'log-1');
      expect(find.text('Số lần gửi: 2/3'), findsOneWidget);
      expect(find.text('Đã gửi lại email (Bỏ qua)'), findsOneWidget);
    });

    testWidgets('hết lượt gửi lại thì nút bị vô hiệu hóa', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(
        logs: <EmailLog>[buildLog(attempts: 3)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskEmailLogsScreen(
            taskId: 'task-1',
            taskTitle: 'Hop nhom tuan nay',
            taskService: taskService,
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đã hết lượt'), findsOneWidget);
      final TextButton button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Đã hết lượt'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('hiển thị trạng thái rỗng khi chưa có email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskEmailLogsScreen(
            taskId: 'task-1',
            taskTitle: 'Hop nhom tuan nay',
            taskService: FakeTaskService(),
            authService: AuthService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có email nào'), findsOneWidget);
    });
  });
}
