import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/user.dart';
import 'package:task_manager/services/api_client.dart';
import 'package:task_manager/services/auth_service.dart';
import 'package:task_manager/screens/profile/change_password_screen.dart';
import 'package:task_manager/screens/profile/profile_edit_screen.dart';
import 'package:task_manager/screens/profile/profile_screen.dart';

class FakeAuthService extends AuthService {
  FakeAuthService({this.failure});

  final ApiException? failure;

  String? lastFullName;
  String? lastAvatarUrl;
  String? lastCurrentPassword;
  String? lastNewPassword;
  int updateProfileCalls = 0;
  int changePasswordCalls = 0;
  int logoutCalls = 0;

  @override
  Future<User> updateProfile({
    required String fullName,
    required String avatarUrl,
  }) async {
    updateProfileCalls += 1;
    lastFullName = fullName;
    lastAvatarUrl = avatarUrl;
    if (failure != null) {
      throw failure!;
    }
    return User(
      id: 'user-1',
      fullName: fullName,
      email: 'chi.case2@example.com',
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls += 1;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    if (failure != null) {
      throw failure!;
    }
  }

  @override
  Future<String?> readToken() async => 'token-test';

  @override
  Future<User> fetchCurrentUser(String token) async {
    return const User(
      id: 'user-1',
      fullName: 'Le Thi Chi',
      email: 'chi.case2@example.com',
    );
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }
}

const User testUser = User(
  id: 'user-1',
  fullName: 'Le Thi Chi',
  email: 'chi.case2@example.com',
);

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
  group('ProfileEditScreen', () {
    testWidgets('gửi đúng họ tên và ảnh đại diện đã nhập', (
      WidgetTester tester,
    ) async {
      final FakeAuthService authService = FakeAuthService();
      await openScreen(
        tester,
        ProfileEditScreen(authService: authService, user: testUser),
      );

      expect(find.text('Le Thi Chi'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Le Thi Chi A2');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'https://example.com/avatar.png',
      );
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(authService.updateProfileCalls, 1);
      expect(authService.lastFullName, 'Le Thi Chi A2');
      expect(authService.lastAvatarUrl, 'https://example.com/avatar.png');
      expect(find.byType(ProfileEditScreen), findsNothing);
    });

    testWidgets('chặn lưu khi họ tên để trống', (WidgetTester tester) async {
      final FakeAuthService authService = FakeAuthService();
      await openScreen(
        tester,
        ProfileEditScreen(authService: authService, user: testUser),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '   ');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
      expect(authService.updateProfileCalls, 0);
      expect(find.byType(ProfileEditScreen), findsOneWidget);
    });

    testWidgets('chặn lưu khi ảnh đại diện sai định dạng', (
      WidgetTester tester,
    ) async {
      final FakeAuthService authService = FakeAuthService();
      await openScreen(
        tester,
        ProfileEditScreen(authService: authService, user: testUser),
      );

      await tester.enterText(find.byType(TextFormField).at(1), 'abc');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(
        find.text('Đường dẫn ảnh phải bắt đầu bằng http hoặc https'),
        findsOneWidget,
      );
      expect(authService.updateProfileCalls, 0);
    });

    testWidgets('hiện thông báo lỗi khi API trả về lỗi', (
      WidgetTester tester,
    ) async {
      final FakeAuthService authService = FakeAuthService(
        failure: const ApiException('Họ tên không được để trống', statusCode: 400),
      );
      await openScreen(
        tester,
        ProfileEditScreen(authService: authService, user: testUser),
      );

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.text('Họ tên không được để trống'), findsOneWidget);
      expect(find.byType(ProfileEditScreen), findsOneWidget);
    });
  });

  group('ChangePasswordScreen', () {
    testWidgets('gửi đúng mật khẩu hiện tại và mật khẩu mới', (
      WidgetTester tester,
    ) async {
      final FakeAuthService authService = FakeAuthService();
      await openScreen(
        tester,
        ChangePasswordScreen(authService: authService),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '123456');
      await tester.enterText(find.byType(TextFormField).at(1), 'matkhaumoi');
      await tester.enterText(find.byType(TextFormField).at(2), 'matkhaumoi');
      await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
      await tester.pumpAndSettle();

      expect(authService.changePasswordCalls, 1);
      expect(authService.lastCurrentPassword, '123456');
      expect(authService.lastNewPassword, 'matkhaumoi');
      expect(find.byType(ChangePasswordScreen), findsNothing);
    });

    testWidgets('chặn gửi khi xác nhận mật khẩu không khớp', (
      WidgetTester tester,
    ) async {
      final FakeAuthService authService = FakeAuthService();
      await openScreen(
        tester,
        ChangePasswordScreen(authService: authService),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '123456');
      await tester.enterText(find.byType(TextFormField).at(1), 'matkhaumoi');
      await tester.enterText(find.byType(TextFormField).at(2), 'khacnhau');
      await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
      expect(authService.changePasswordCalls, 0);
    });

    testWidgets('hiện lỗi khi mật khẩu hiện tại không đúng', (
      WidgetTester tester,
    ) async {
      final FakeAuthService authService = FakeAuthService(
        failure: const ApiException('Mật khẩu hiện tại không đúng', statusCode: 400),
      );
      await openScreen(
        tester,
        ChangePasswordScreen(authService: authService),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'saimatkhau');
      await tester.enterText(find.byType(TextFormField).at(1), 'matkhaumoi');
      await tester.enterText(find.byType(TextFormField).at(2), 'matkhaumoi');
      await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
      await tester.pumpAndSettle();

      expect(find.text('Mật khẩu hiện tại không đúng'), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });
  });

  group('ProfileScreen', () {
    testWidgets('hiện thông tin người dùng và hỏi xác nhận khi đăng xuất', (
      WidgetTester tester,
    ) async {
      final FakeAuthService authService = FakeAuthService();
      await openScreen(
        tester,
        ProfileScreen(authService: authService, user: testUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('Le Thi Chi'), findsOneWidget);
      expect(find.text('chi.case2@example.com'), findsOneWidget);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn có chắc muốn đăng xuất khỏi ứng dụng?'), findsOneWidget);

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(authService.logoutCalls, 0);
      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
      await tester.pumpAndSettle();

      expect(authService.logoutCalls, 1);
      expect(find.byType(ProfileScreen), findsNothing);
    });
  });
}
