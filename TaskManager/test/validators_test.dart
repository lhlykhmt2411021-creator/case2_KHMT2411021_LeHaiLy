import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/utils/validators.dart';

void main() {
  group('Validators.fullName', () {
    test('trả lỗi khi rỗng', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('   '), isNotNull);
    });

    test('hợp lệ khi có tên', () {
      expect(Validators.fullName('Lê Hải Lý'), isNull);
    });
  });

  group('Validators.email', () {
    test('trả lỗi khi sai định dạng', () {
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('abc@'), isNotNull);
    });

    test('hợp lệ khi đúng định dạng', () {
      expect(Validators.email('ly@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('trả lỗi khi ngắn hơn 6 ký tự', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('hợp lệ khi từ 6 ký tự', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('trả lỗi khi không khớp', () {
      expect(Validators.confirmPassword('123456', '123457'), isNotNull);
    });

    test('hợp lệ khi khớp', () {
      expect(Validators.confirmPassword('123456', '123456'), isNull);
    });
  });

  group('Validators.avatarUrl', () {
    test('hợp lệ khi để trống', () {
      expect(Validators.avatarUrl(''), isNull);
      expect(Validators.avatarUrl(null), isNull);
    });

    test('trả lỗi khi không phải http hoặc https', () {
      expect(Validators.avatarUrl('abc'), isNotNull);
      expect(Validators.avatarUrl('ftp://example.com/a.png'), isNotNull);
    });

    test('hợp lệ khi là đường dẫn http hoặc https', () {
      expect(Validators.avatarUrl('https://example.com/a.png'), isNull);
      expect(Validators.avatarUrl('http://example.com/a.png'), isNull);
    });
  });

  group('Validators.taskTitle', () {
    test('trả lỗi khi rỗng', () {
      expect(Validators.taskTitle(''), isNotNull);
      expect(Validators.taskTitle('   '), isNotNull);
      expect(Validators.taskTitle(null), isNotNull);
    });

    test('trả lỗi khi quá 200 ký tự', () {
      expect(Validators.taskTitle('a' * 201), isNotNull);
    });

    test('hợp lệ khi có tiêu đề', () {
      expect(Validators.taskTitle('Việc mẫu'), isNull);
      expect(Validators.taskTitle('a' * 200), isNull);
    });
  });

  group('Validators.dateRange', () {
    test('hợp lệ khi thiếu một trong hai ngày', () {
      expect(Validators.dateRange(null, DateTime(2026, 11, 1)), isNull);
      expect(Validators.dateRange(DateTime(2026, 11, 1), null), isNull);
    });

    test('hợp lệ khi hạn sau hoặc bằng ngày bắt đầu', () {
      expect(
        Validators.dateRange(DateTime(2026, 11, 1), DateTime(2026, 11, 5)),
        isNull,
      );
      expect(
        Validators.dateRange(DateTime(2026, 11, 1), DateTime(2026, 11, 1)),
        isNull,
      );
    });

    test('trả lỗi khi hạn trước ngày bắt đầu', () {
      expect(
        Validators.dateRange(DateTime(2026, 11, 5), DateTime(2026, 11, 1)),
        isNotNull,
      );
    });
  });
}
