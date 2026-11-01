class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    return null;
  }

  static String? email(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  static String? taskTitle(String? value) {
    final String title = value?.trim() ?? '';
    if (title.isEmpty) {
      return 'Vui lòng nhập tiêu đề công việc';
    }
    if (title.length > 200) {
      return 'Tiêu đề không được vượt quá 200 ký tự';
    }
    return null;
  }

  static String? dateRange(DateTime? startDate, DateTime? dueDate) {
    if (startDate != null && dueDate != null && dueDate.isBefore(startDate)) {
      return 'Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu';
    }
    return null;
  }

  static String? avatarUrl(String? value) {
    final String url = value?.trim() ?? '';
    if (url.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return 'Đường dẫn ảnh phải bắt đầu bằng http hoặc https';
    }
    return null;
  }
}
