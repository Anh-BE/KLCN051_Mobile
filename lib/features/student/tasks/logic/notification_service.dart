import 'package:flutter/material.dart';

enum NotificationType {
  deadlineUrgent, // Sắp đến hạn
  deadlineOverdue, // Quá hạn nộp bài
  newDeadline, // Giảng viên vừa giao deadline mới
  general, // Thông báo chung
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final String? relatedTaskId;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.relatedTaskId,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.deadlineUrgent:
        return Icons.alarm_on_rounded;
      case NotificationType.deadlineOverdue:
        return Icons.warning_amber_rounded;
      case NotificationType.newDeadline:
        return Icons.event_available_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.deadlineUrgent:
        return const Color(0xFF0284C7);
      case NotificationType.deadlineOverdue:
        return const Color(0xFFDC2626);
      case NotificationType.newDeadline:
        return const Color(0xFF0D9488);
      case NotificationType.general:
        return const Color(0xFF64748B);
    }
  }

  Color get bgColor {
    switch (type) {
      case NotificationType.deadlineUrgent:
        return const Color(0xFFE0F2FE);
      case NotificationType.deadlineOverdue:
        return const Color(0xFFFEE2E2);
      case NotificationType.newDeadline:
        return const Color(0xFFCCFBF1);
      case NotificationType.general:
        return const Color(0xFFF1F5F9);
    }
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _initSampleNotifications();
  }

  final List<AppNotificationItem> _notifications = [];

  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _initSampleNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      AppNotificationItem(
        id: 'NOTIF-01',
        title: 'Nhắc deadline: Báo cáo Tuần 5 sắp đến hạn',
        message: 'Bạn có nhiệm vụ "Nộp đề cương chi tiết & Báo cáo tiến độ Tuần 5" hết hạn vào 23:59:59 ngày ${now.add(const Duration(days: 2)).day}/${now.add(const Duration(days: 2)).month}. Hãy hoàn thành đúng hạn!',
        createdAt: now.subtract(const Duration(hours: 3)),
        type: NotificationType.deadlineUrgent,
        relatedTaskId: 'TASK-W05',
        isRead: false,
      ),
      AppNotificationItem(
        id: 'NOTIF-02',
        title: 'Cảnh báo quá hạn: Báo cáo Tuần 4 chưa nộp',
        message: 'Nhiệm vụ "Báo cáo tiến độ Tuần 4: Thiết kế CSDL & Sơ đồ ERD" đã quá mốc 23:59. Hệ thống vẫn mở nộp bài nhưng sẽ gắn cờ "Nộp trễ".',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        type: NotificationType.deadlineOverdue,
        relatedTaskId: 'TASK-W04',
        isRead: false,
      ),
      AppNotificationItem(
        id: 'NOTIF-03',
        title: 'Giảng viên giao deadline mới: Tuần 6',
        message: 'ThS. Vũ Văn Vinh vừa giao nhiệm vụ "Xây dựng Module Mobile & API" với hạn chót là 23:59:59 ngày ${now.add(const Duration(days: 9)).day}/${now.add(const Duration(days: 9)).month}.',
        createdAt: now.subtract(const Duration(days: 2)),
        type: NotificationType.newDeadline,
        relatedTaskId: 'TASK-W06',
        isRead: true,
      ),
    ]);
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedTaskId,
  }) {
    _notifications.insert(
      0,
      AppNotificationItem(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        createdAt: DateTime.now(),
        type: type,
        relatedTaskId: relatedTaskId,
        isRead: false,
      ),
    );
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }
}
