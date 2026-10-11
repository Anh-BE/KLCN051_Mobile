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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] ?? 0,
      userId: json['userId'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      category: json['category'] ?? 'general',
      actionUrl: json['actionUrl'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeAgo: json['timeAgo'] ?? '',
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
