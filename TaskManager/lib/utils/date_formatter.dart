class DateFormatter {
  DateFormatter._();

  static String format(DateTime? date) {
    if (date == null) {
      return 'Chưa đặt';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Không rõ thời gian';
    }
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '${format(date)} $hour:$minute';
  }
}
