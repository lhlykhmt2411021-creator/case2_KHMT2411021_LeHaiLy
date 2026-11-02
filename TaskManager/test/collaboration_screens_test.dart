import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/user.dart';
import 'package:task_manager/screens/tasks/task_assignees_screen.dart';
import 'package:task_manager/screens/tasks/task_shares_screen.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/services/task_service.dart';
import 'package:task_manager/services/user_service.dart';

Task copyTask(
  Task task, {
  List<TaskUserRef>? assignees,
  List<TaskShareInfo>? shares,
  bool replacePrimary = false,
  TaskUserRef? primaryAssignee,
}) {
  final List<TaskUserRef> nextAssignees = assignees ?? task.assignees;
  return Task(
    id: task.id,
    title: task.title,
    description: task.description,
    status: task.status,
    priority: task.priority,
    startDate: task.startDate,
    dueDate: task.dueDate,
    createdAt: task.createdAt,
    createdBy: task.createdBy,
    primaryAssignee: replacePrimary ? primaryAssignee : task.primaryAssignee,
    assigneeCount: nextAssignees.length,
    assignees: nextAssignees,
    shares: shares ?? task.shares,
    role: task.role,
  );
}

class FakeTaskService extends TaskService {
  FakeTaskService({required this.task}) : super(authService: AuthService());

  Task task;

  List<String>? assignedUserIds;
  List<String>? addedShareUserIds;
  String? addedPermission;
  String? primaryAssigneeId;
  String? removedAssigneeId;
  String? updatedShareId;
  String? updatedPermission;
  String? removedShareId;

  @override
  Future<Task> assignUsers(
    String id, {
    required List<String> userIds,
    String? primaryAssigneeId,
  }) async {
    assignedUserIds = userIds;
    final List<TaskUserRef> added = userIds
        .map(
          (String userId) => TaskUserRef(
            id: userId,
            fullName: 'Người $userId',
            email: '$userId@example.com',
          ),
        )
        .toList();
    final List<TaskUserRef> merged = <TaskUserRef>[...task.assignees, ...added];

    TaskUserRef? primary = task.primaryAssignee;
    if (primaryAssigneeId != null) {
      for (final TaskUserRef user in merged) {
        if (user.id == primaryAssigneeId) {
          primary = user;
        }
      }
    } else if (primary == null && merged.isNotEmpty) {
      primary = merged.first;
    }

    task = copyTask(
      task,
      assignees: merged,
      replacePrimary: true,
      primaryAssignee: primary,
    );
    return task;
  }

  @override
  Future<Task> setPrimaryAssignee(String id, String userId) async {
    primaryAssigneeId = userId;
    TaskUserRef? primary;
    for (final TaskUserRef user in task.assignees) {
      if (user.id == userId) {
        primary = user;
      }
    }
    task = copyTask(task, replacePrimary: true, primaryAssignee: primary);
    return task;
  }

  @override
  Future<Task> removeAssignee(String id, String userId) async {
    removedAssigneeId = userId;
    final List<TaskUserRef> remaining = task.assignees
        .where((TaskUserRef user) => user.id != userId)
        .toList();
    final bool wasPrimary = task.primaryAssignee?.id == userId;
    task = copyTask(
      task,
      assignees: remaining,
      replacePrimary: wasPrimary,
      primaryAssignee: remaining.isEmpty ? null : remaining.first,
    );
    return task;
  }

  @override
  Future<Task> addShares(
    String id, {
    required List<String> userIds,
    required String permission,
  }) async {
    addedShareUserIds = userIds;
    addedPermission = permission;
    final List<TaskShareInfo> added = userIds
        .map(
          (String userId) => TaskShareInfo(
            id: 'share-$userId',
            permission: permission,
            user: TaskUserRef(
              id: userId,
              fullName: 'Người $userId',
              email: '$userId@example.com',
            ),
          ),
        )
        .toList();
    task = copyTask(task, shares: <TaskShareInfo>[...task.shares, ...added]);
    return task;
  }

  @override
  Future<Task> updateShare(
    String id,
    String shareId, {
    required String permission,
  }) async {
    updatedShareId = shareId;
    updatedPermission = permission;
    final List<TaskShareInfo> shares = task.shares
        .map(
          (TaskShareInfo share) => share.id == shareId
              ? TaskShareInfo(
                  id: share.id,
                  permission: permission,
                  user: share.user,
                )
              : share,
        )
        .toList();
    task = copyTask(task, shares: shares);
    return task;
  }

  @override
  Future<Task> removeShare(String id, String shareId) async {
    removedShareId = shareId;
    task = copyTask(
      task,
      shares: task.shares
          .where((TaskShareInfo share) => share.id != shareId)
          .toList(),
    );
    return task;
  }
}

class FakeUserService extends UserService {
  FakeUserService({this.users = const <User>[]})
      : super(authService: AuthService());

  final List<User> users;
  String? lastQuery;

  @override
  Future<List<User>> searchUsers(String query) async {
    lastQuery = query;
    return users;
  }
}

const TaskUserRef creatorRef = TaskUserRef(
  id: 'user-creator',
  fullName: 'Le Thi Chi',
  email: 'chi.case2@example.com',
);

const TaskUserRef assigneeRef = TaskUserRef(
  id: 'user-a',
  fullName: 'Nguyễn Văn A',
  email: 'a@example.com',
);

const TaskUserRef assigneeRefB = TaskUserRef(
  id: 'user-b',
  fullName: 'Trần Thị B',
  email: 'b@example.com',
);

Task buildTask({
  List<TaskUserRef> assignees = const <TaskUserRef>[assigneeRef],
  TaskUserRef? primaryAssignee = assigneeRef,
  List<TaskShareInfo> shares = const <TaskShareInfo>[],
}) {
  return Task(
    id: 'task-1',
    title: 'Việc mẫu',
    description: 'Mô tả',
    status: TaskStatus.todo,
    priority: TaskPriority.medium,
    createdBy: creatorRef,
    primaryAssignee: primaryAssignee,
    assigneeCount: assignees.length,
    assignees: assignees,
    shares: shares,
    role: 'creator',
  );
}

void main() {
  group('TaskAssigneesScreen', () {
    testWidgets('hiển thị người được giao và người phụ trách chính', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(task: buildTask());
      await tester.pumpWidget(
        MaterialApp(
          home: TaskAssigneesScreen(
            task: taskService.task,
            taskService: taskService,
            userService: FakeUserService(),
          ),
        ),
      );

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(
        find.text('Người phụ trách chính: Nguyễn Văn A'),
        findsOneWidget,
      );
      expect(find.text('a@example.com • Phụ trách chính'), findsOneWidget);
    });

    testWidgets('giao thêm người qua màn hình tìm kiếm', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(task: buildTask());
      final FakeUserService userService = FakeUserService(
        users: const <User>[
          User(
            id: 'user-b',
            fullName: 'Trần Thị B',
            email: 'b@example.com',
          ),
          User(
            id: 'user-c',
            fullName: 'Lê Văn C',
            email: 'c@example.com',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskAssigneesScreen(
            task: taskService.task,
            taskService: taskService,
            userService: userService,
          ),
        ),
      );

      await tester.tap(find.text('Thêm người'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'B');
      await tester.tap(find.text('Tìm'));
      await tester.pumpAndSettle();

      expect(userService.lastQuery, 'B');
      expect(find.text('Trần Thị B'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsNothing);

      await tester.tap(find.text('Trần Thị B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn (1)'));
      await tester.pumpAndSettle();

      expect(taskService.assignedUserIds, <String>['user-b']);
      expect(find.text('Người user-b'), findsOneWidget);
      expect(find.text('Đã giao việc'), findsOneWidget);
    });

    testWidgets('đặt người phụ trách chính khác', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService(
        task: buildTask(
          assignees: const <TaskUserRef>[assigneeRef, assigneeRefB],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskAssigneesScreen(
            task: taskService.task,
            taskService: taskService,
            userService: FakeUserService(),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt làm phụ trách chính'));
      await tester.pumpAndSettle();

      expect(taskService.primaryAssigneeId, 'user-b');
      expect(
        find.text('Người phụ trách chính: Trần Thị B'),
        findsOneWidget,
      );
    });

    testWidgets('hủy giao việc sau khi xác nhận', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService(task: buildTask());

      await tester.pumpWidget(
        MaterialApp(
          home: TaskAssigneesScreen(
            task: taskService.task,
            taskService: taskService,
            userService: FakeUserService(),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy giao việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hủy giao'));
      await tester.pumpAndSettle();

      expect(taskService.removedAssigneeId, 'user-a');
      expect(find.text('Chưa giao việc cho ai'), findsOneWidget);
      expect(
        find.text('Người phụ trách chính: Chưa chỉ định'),
        findsOneWidget,
      );
    });
  });

  group('TaskSharesScreen', () {
    testWidgets('chia sẻ cho người mới với quyền chỉnh sửa', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(task: buildTask());
      final FakeUserService userService = FakeUserService(
        users: const <User>[
          User(
            id: 'user-d',
            fullName: 'Phạm Văn D',
            email: 'd@example.com',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskSharesScreen(
            task: taskService.task,
            taskService: taskService,
            userService: userService,
          ),
        ),
      );

      expect(find.text('Chưa chia sẻ cho ai'), findsOneWidget);

      await tester.tap(find.text('Thêm người'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'D');
      await tester.tap(find.text('Tìm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phạm Văn D'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn quyền chia sẻ'), findsOneWidget);
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();

      expect(taskService.addedShareUserIds, <String>['user-d']);
      expect(taskService.addedPermission, 'editor');
      expect(find.text('user-d@example.com • Chỉnh sửa'), findsOneWidget);
    });

    testWidgets('đổi quyền của người đã được chia sẻ', (
      WidgetTester tester,
    ) async {
      final FakeTaskService taskService = FakeTaskService(
        task: buildTask(
          shares: const <TaskShareInfo>[
            TaskShareInfo(
              id: 'share-1',
              permission: 'viewer',
              user: TaskUserRef(
                id: 'user-d',
                fullName: 'Phạm Văn D',
                email: 'd@example.com',
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskSharesScreen(
            task: taskService.task,
            taskService: taskService,
            userService: FakeUserService(),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển thành chỉnh sửa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();

      expect(taskService.updatedShareId, 'share-1');
      expect(taskService.updatedPermission, 'editor');
      expect(find.text('d@example.com • Chỉnh sửa'), findsOneWidget);
    });

    testWidgets('thu hồi quyền sau khi xác nhận', (WidgetTester tester) async {
      final FakeTaskService taskService = FakeTaskService(
        task: buildTask(
          shares: const <TaskShareInfo>[
            TaskShareInfo(
              id: 'share-1',
              permission: 'viewer',
              user: TaskUserRef(
                id: 'user-d',
                fullName: 'Phạm Văn D',
                email: 'd@example.com',
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskSharesScreen(
            task: taskService.task,
            taskService: taskService,
            userService: FakeUserService(),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu hồi quyền'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Thu hồi'));
      await tester.pumpAndSettle();

      expect(taskService.removedShareId, 'share-1');
      expect(find.text('Chưa chia sẻ cho ai'), findsOneWidget);
    });
  });
}
