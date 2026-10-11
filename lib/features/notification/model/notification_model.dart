class NotificationModel {
  final int notificationId;
  final int? userId;
  final String title;
  final String message;
  final String? type;
  final String? category;
  final String? actionUrl;
  final bool isRead;
  final DateTime? createdAt;
  final String timeAgo;

  NotificationModel({
    required this.notificationId,
    this.userId,
    required this.title,
    required this.message,
    this.type,
    this.category,
    this.actionUrl,
    this.isRead = false,
    this.createdAt,
    this.timeAgo = 'Vừa xong',
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    return NotificationModel(
      notificationId: json['notificationId'] ?? json['id'] ?? 0,
      userId: json['userId'],
      title: json['title'] ?? 'Thông báo',
      message: json['message'] ?? '',
      type: json['type']?.toString().toLowerCase(),
      category: json['category']?.toString().toLowerCase(),
      actionUrl: json['actionUrl'],
      isRead: json['isRead'] ?? false,
      createdAt: parsedDate,
      timeAgo: json['timeAgo']?.toString() ?? _calculateTimeAgo(parsedDate),
    );
  }

  NotificationModel copyWith({
    int? notificationId,
    int? userId,
    String? title,
    String? message,
    String? type,
    String? category,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
    String? timeAgo,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }

  static String _calculateTimeAgo(DateTime? date) {
    if (date == null) return 'Vừa xong';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
