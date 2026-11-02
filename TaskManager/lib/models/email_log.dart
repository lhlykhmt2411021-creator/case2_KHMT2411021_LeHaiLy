class EmailLog {
  const EmailLog({
    required this.id,
    required this.recipientEmail,
    required this.eventType,
    required this.subject,
    required this.status,
    required this.attempts,
    required this.errorMessage,
    this.taskId,
    this.sentAt,
    this.createdAt,
  });

  final String id;
  final String? taskId;
  final String recipientEmail;
  final String eventType;
  final String subject;
  final String status;
  final int attempts;
  final String errorMessage;
  final DateTime? sentAt;
  final DateTime? createdAt;

  bool get canRetry => attempts < 3;

  String get statusLabel {
    switch (status) {
      case 'sent':
        return 'Đã gửi';
      case 'failed':
        return 'Gửi lỗi';
      case 'skipped':
        return 'Bỏ qua';
      default:
        return 'Đang chờ';
    }
  }

  String get eventLabel {
    switch (eventType) {
      case 'assigned':
        return 'Giao việc';
      case 'shared':
        return 'Chia sẻ';
      case 'due_date_changed':
        return 'Đổi hạn hoàn thành';
      case 'completed':
        return 'Hoàn thành';
      default:
        return eventType;
    }
  }

  factory EmailLog.fromJson(Map<String, dynamic> json) {
    final Object? sentAt = json['sentAt'];
    final Object? createdAt = json['createdAt'];
    return EmailLog(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      taskId: json['taskId'] as String?,
      recipientEmail: json['recipientEmail'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String? ?? '',
      sentAt: sentAt is String ? DateTime.tryParse(sentAt)?.toLocal() : null,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt)?.toLocal() : null,
    );
  }
}
