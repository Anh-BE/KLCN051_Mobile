class AppNotification {
  final int notificationId;
  final int? userId;
  final String title;
  final String message;
  final String type; // info, success, warning, danger
  final String category; // thesis_approval, thesis_registration, weekly_report, general
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;
  final String timeAgo;

  AppNotification({
    required this.notificationId,
    this.userId,
    required this.title,
    required this.message,
    this.type = 'info',
    this.category = 'general',
    this.actionUrl,
    this.isRead = false,
    DateTime? createdAt,
    this.timeAgo = '',
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromJson(Map<dynamic, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return AppNotification(
      notificationId: parseId(json['notificationId'] ?? json['id']),
      userId: parseId(json['userId']),
      title: json['title']?.toString() ?? 'Thông báo',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'info',
      category: json['category']?.toString().toLowerCase() ?? 'general',
      actionUrl: json['actionUrl']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeAgo: json['timeAgo']?.toString() ?? '',
    );
  }

  AppNotification copyWith({
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
    return AppNotification(
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
}

typedef NotificationModel = AppNotification;
