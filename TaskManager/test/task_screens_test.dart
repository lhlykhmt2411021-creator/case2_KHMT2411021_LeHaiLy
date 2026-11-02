import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/services/api_client.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/services/task_service.dart';
import 'package:task_manager/screens/tasks/task_detail_screen.dart';
import 'package:task_manager/screens/tasks/task_form_screen.dart';

class FakeTaskService extends TaskService {
  FakeTaskService({this.task, this.failure}) : super(authService: AuthService());

  Task? task;
  ApiException? failure;

  String? createdTitle;
  String? createdDescription;
  TaskPriority? createdPriority;

  String? updatedId;
  String? updatedTitle;
  TaskPriority? updatedPriority;

  TaskStatus? updatedStatus;
  String? deletedId;

  @override
  Future<Task> fetchTask(String id) async {
    if (failure != null) {
      throw failure!;
    }
    return task!;
  }

  @override
  Future<Task> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    if (failure != null) {
      throw failure!;
    }
    createdTitle = title;
    createdDescription = description;
    createdPriority = priority;
    return Task(
      id: 'new-task',
      title: title,
      description: description,
      status: TaskStatus.todo,
      priority: priority,
      startDate: startDate,
      dueDate: dueDate,
    );
  }

  @override
  Future<Task> updateTask(
    String id, {
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    if (failure != null) {
      throw failure!;
    }
    updatedId = id;
    updatedTitle = title;
    updatedPriority = priority;
    return Task(
      id: id,
      title: title,
      description: description,
      status: task?.status ?? TaskStatus.todo,
      priority: priority,
      startDate: startDate,
      dueDate: dueDate,
    );
  }

  @override
  Future<Task> updateStatus(String id, TaskStatus status) async {
    if (failure != null) {
      throw failure!;
    }
    updatedStatus = status;
    return task!;
  }

  @override
  Future<void> deleteTask(String id) async {
    if (failure != null) {
      throw failure!;
    }
    deletedId = id;
  }
}

Task buildTask({String role = 'creator', String status = 'todo'}) {
  return Task(
    id: 'task-1',
    title: 'Việc mẫu',
    description: 'Mô tả mẫu',
    status: status == 'completed' ? TaskStatus.completed : TaskStatus.todo,
    priority: TaskPriority.medium,
    createdBy: const TaskUserRef(
      id: 'user-1',
      fullName: 'Le Thi Chi',
      email: 'chi.case2@example.com',
    ),
    role: role,
  );
}

Future<void> openScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => screen),
                ),
                child: const Text('mo-man-hinh'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('mo-man-hinh'));
  await tester.pumpAndSettle();
}

void main() {
  group('TaskFormScreen tạo mới', () {
    testWidgets('gửi đúng dữ liệu đã nhập', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService();
      await openScreen(tester, TaskFormScreen(taskService: taskService));

      await tester.enterText(find.byType(TextFormField).at(0), 'Việc mới');
      await tester.enterText(find.byType(TextFormField).at(1), 'Mô tả mới');

      await tester.tap(find.text('Trung bình').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cao').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo công việc'));
      await tester.pumpAndSettle();

      expect(taskService.createdTitle, 'Việc mới');
      expect(taskService.createdDescription, 'Mô tả mới');
      expect(taskService.createdPriority, TaskPriority.high);
      expect(find.byType(TaskFormScreen), findsNothing);
    });

    testWidgets('chặn tạo khi tiêu đề rỗng', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService();
      await openScreen(tester, TaskFormScreen(taskService: taskService));

      await tester.tap(find.text('Tạo công việc'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tiêu đề công việc'), findsOneWidget);
      expect(taskService.createdTitle, isNull);
      expect(find.byType(TaskFormScreen), findsOneWidget);
    });

    testWidgets('hiện lỗi khi API trả về lỗi', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService(
        failure: const ApiException('Dữ liệu không hợp lệ', statusCode: 400),
      );
      await openScreen(tester, TaskFormScreen(taskService: taskService));

      await tester.enterText(find.byType(TextFormField).at(0), 'Việc lỗi');
      await tester.tap(find.text('Tạo công việc'));
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu không hợp lệ'), findsOneWidget);
      expect(find.byType(TaskFormScreen), findsOneWidget);
    });
  });

  group('TaskFormScreen chỉnh sửa', () {
    testWidgets('điền sẵn dữ liệu và gửi đúng id', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(task: buildTask());
      await openScreen(
        tester,
        TaskFormScreen(taskService: taskService, task: buildTask()),
      );

      expect(find.text('Việc mẫu'), findsOneWidget);
      expect(find.text('Mô tả mẫu'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Việc đã sửa');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(taskService.updatedId, 'task-1');
      expect(taskService.updatedTitle, 'Việc đã sửa');
      expect(find.byType(TaskFormScreen), findsNothing);
    });
  });

  group('TaskDetailScreen', () {
    testWidgets('người tạo thấy menu và đổi được trạng thái', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(task: buildTask());
      await openScreen(
        tester,
        TaskDetailScreen(
          taskId: 'task-1',
          taskService: taskService,
          authService: AuthService(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Việc mẫu'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Chỉnh sửa công việc'), findsOneWidget);
      expect(find.text('Giao việc'), findsOneWidget);
      expect(find.text('Chia sẻ công việc'), findsOneWidget);
      expect(find.text('Xóa công việc'), findsOneWidget);

      await tester.tap(find.text('Đổi trạng thái'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đã hoàn thành'));
      await tester.pumpAndSettle();

      expect(taskService.updatedStatus, TaskStatus.completed);
    });

    testWidgets('người tạo xóa công việc sau khi xác nhận', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(task: buildTask());
      await openScreen(
        tester,
        TaskDetailScreen(
          taskId: 'task-1',
          taskService: taskService,
          authService: AuthService(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa công việc'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn có chắc muốn xóa công việc "Việc mẫu"?'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await tester.pumpAndSettle();

      expect(taskService.deletedId, 'task-1');
      expect(find.byType(TaskDetailScreen), findsNothing);
    });

    testWidgets('viewer không thấy menu thao tác', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService(
        task: buildTask(role: 'viewer'),
      );
      await openScreen(
        tester,
        TaskDetailScreen(
          taskId: 'task-1',
          taskService: taskService,
          authService: AuthService(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });
}
