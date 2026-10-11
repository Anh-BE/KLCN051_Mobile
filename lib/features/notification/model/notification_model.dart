class AppNotification {
  final int notificationId;
  final int userId;
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
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
    required this.timeAgo,
  });

  factory AppNotification.fromJson(Map<dynamic, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return AppNotification(
      notificationId: parseId(json['notificationId']),
      userId: parseId(json['userId']),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      category: json['category']?.toString() ?? 'general',
      actionUrl: json['actionUrl']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeAgo: json['timeAgo']?.toString() ?? '',
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      notificationId: notificationId,
      userId: userId,
      title: title,
      message: message,
      type: type,
      category: category,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      timeAgo: timeAgo,
    );
  }
}
