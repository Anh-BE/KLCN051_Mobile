import 'package:flutter/material.dart';
import 'package:app_mobile/features/auth/model/user_model.dart';
import '../logic/notification_service.dart';
import 'student_task_deadline_screen.dart';

class StudentNotificationScreen extends StatelessWidget {
  final UserModel user;

  const StudentNotificationScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final notifService = NotificationService();

    return AnimatedBuilder(
      animation: notifService,
      builder: (context, _) {
        final notifications = notifService.notifications;
        final unreadCount = notifService.unreadCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF0072E8),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                const Text(
                  'THÔNG BÁO NHẮC VIỆC',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => notifService.markAllAsRead(),
                  child: const Text(
                    'Đọc tất cả',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? const Center(
                  child: Text(
                    'Bạn không có thông báo nào!',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return InkWell(
                      onTap: () {
                        notifService.markAsRead(item.id);
                        // Điều hướng sang chi tiết deadline nếu có task liên kết
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentTaskDeadlineScreen(user: user),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
                            width: item.isRead ? 1.0 : 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon theo loại thông báo
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.bgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: item.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF0072E8),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    item.message,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: const Color(0xFF475569),
                                      height: 1.35,
                                      fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')} ngày ${item.createdAt.day}/${item.createdAt.month}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                      const Spacer(),
                                      const Text(
                                        'Xem chi tiết >',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF0072E8),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
