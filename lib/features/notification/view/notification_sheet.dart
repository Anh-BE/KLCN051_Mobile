import 'package:flutter/material.dart';
import '../logic/notification_service.dart';
import '../model/notification_model.dart';
import '../../auth/model/user_model.dart';
import '../../lecturer/review_report/view/lecturer_weekly_report_list_screen.dart';
import '../../lecturer/topic/view/lecturer_topic_list_screen.dart';
import 'app_notification_screen.dart';

class NotificationSheet extends StatefulWidget {
  final UserModel? user;
  final VoidCallback? onNotificationChanged;

  const NotificationSheet({
    super.key,
    this.user,
    this.onNotificationChanged,
  });

  static Future<void> show(BuildContext context, {UserModel? user, VoidCallback? onNotificationChanged}) {
    return AppNotificationScreen.show(context, user: user);
  }

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  final NotificationService _service = NotificationService();
  bool _isLoading = true;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final list = await _service.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _service.markAllAsRead();
    if (success && mounted) {
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      widget.onNotificationChanged?.call();
    }
  }

  Future<void> _handleNotificationTap(AppNotification notif) async {
    if (!notif.isRead) {
      await _service.markAsRead(notif.notificationId);
      setState(() {
        final index = _notifications.indexWhere((n) => n.notificationId == notif.notificationId);
        if (index != -1) {
          _notifications[index] = notif.copyWith(isRead: true);
        }
      });
      widget.onNotificationChanged?.call();
    }

    if (!mounted || widget.user == null) return;

    // Điều hướng theo yêu cầu:
    // - Nhóm đăng ký đề tài & sinh viên nộp báo cáo tuần -> Chuyển sang Xem báo cáo tuần
    // - Đề tài được duyệt / từ chối / chỉnh sửa -> Chuyển sang Đề tài & Trạng thái
    if (notif.category == 'thesis_registration' || notif.category == 'weekly_report') {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LecturerWeeklyReportListScreen(user: widget.user!),
        ),
      );
    } else {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LecturerTopicListScreen(user: widget.user!),
        ),
      );
    }
  }

  IconData _getIconForType(String type, String category) {
    if (category == 'weekly_report') return Icons.assignment_turned_in_rounded;
    if (category == 'thesis_registration') return Icons.group_add_rounded;
    switch (type.toLowerCase()) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'danger':
        return Icons.cancel_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type, String category) {
    if (category == 'weekly_report') return const Color(0xFF2563EB);
    if (category == 'thesis_registration') return const Color(0xFF0D9488);
    switch (type.toLowerCase()) {
      case 'success':
        return const Color(0xFF16A34A);
      case 'danger':
        return const Color(0xFFDC2626);
      case 'warning':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF0284C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded, color: Color(0xFF0F766E), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Thông báo hệ thống',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (hasUnread)
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF0D9488)),
                    label: const Text(
                      'Đọc tất cả',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_off_outlined,
                                size: 48,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Chưa có thông báo nào',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Các thông báo liên quan đến duyệt đề tài, nhóm đăng ký\nvà báo cáo tiến độ tuần sẽ xuất hiện tại đây.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: const Color(0xFF0D9488),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 72,
                            endIndent: 16,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final iconColor = _getColorForType(notif.type, notif.category);
                            final iconData = _getIconForType(notif.type, notif.category);

                            return InkWell(
                              onTap: () => _handleNotificationTap(notif),
                              child: Container(
                                color: notif.isRead ? Colors.transparent : const Color(0xFFF0FDF9),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(iconData, color: iconColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: notif.isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.w800,
                                                    color: const Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ),
                                              if (!notif.isRead) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 9,
                                                  height: 9,
                                                  margin: const EdgeInsets.only(top: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEF4444),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 1.5),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFFEF4444).withOpacity(0.4),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: notif.isRead
                                                  ? const Color(0xFF64748B)
                                                  : const Color(0xFF334155),
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            notif.timeAgo.isNotEmpty ? notif.timeAgo : 'Gần đây',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
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
                      ),
          ),
        ],
      ),
    );
  }
}
