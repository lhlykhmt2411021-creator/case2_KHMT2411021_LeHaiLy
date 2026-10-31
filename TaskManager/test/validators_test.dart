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
}
