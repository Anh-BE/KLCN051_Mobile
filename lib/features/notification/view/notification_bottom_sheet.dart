import 'package:flutter/material.dart';
import '../../../core/utils/storage_service.dart';
import '../../student/group/view/student_manage_group_screen.dart';
import '../../student/topic/view/student_topic_list_screen.dart';
import '../logic/notification_service.dart';
import '../model/notification_model.dart';

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationBottomSheet(),
    );
  }

  @override
  State<NotificationBottomSheet> createState() => _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  final NotificationService _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _service.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.82;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // 1. THANH KÉO (DRAG HANDLE)
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // 2. HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0072E8).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFF0072E8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),

                // Badge số lượng chưa đọc
                ListenableBuilder(
                  listenable: _service,
                  builder: (context, _) {
                    if (_service.unreadCount <= 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_service.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Nút Đọc tất cả
                ListenableBuilder(
                  listenable: _service,
                  builder: (context, _) {
                    if (_service.unreadCount <= 0) return const SizedBox.shrink();
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _service.markAllAsRead(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Đọc tất cả',
                          style: TextStyle(
                            color: Color(0xFF0072E8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // 3. DANH SÁCH THÔNG BÁO
          Expanded(
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                if (_service.isLoading && _service.notifications.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0072E8)),
                  );
                }

                if (_service.notifications.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _service.fetchNotifications(),
                    child: ListView(
                      children: [
                        SizedBox(height: sheetHeight * 0.22),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 36,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Chưa có thông báo nào',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Các lời mời nhóm, duyệt đề tài và lịch khóa luận\nsẽ xuất hiện tại đây theo thời gian thực.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF0072E8),
                  onRefresh: () => _service.fetchNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _service.notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _service.notifications[index];
                      return _buildNotificationCard(item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel item) {
    Color iconBg = const Color(0xFFEEF5FE);
    Color iconColor = const Color(0xFF0072E8);
    IconData icon = Icons.notifications_rounded;

    final type = item.type ?? '';
    final category = item.category ?? '';

    if (type.contains('success') || category.contains('accepted')) {
      iconBg = const Color(0xFFE8FDF4);
      iconColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (type.contains('warning') || category.contains('thesis')) {
      iconBg = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFF97316);
      icon = Icons.assignment_turned_in_rounded;
    } else if (category.contains('invite') || category.contains('group')) {
      iconBg = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF059669);
      icon = Icons.group_add_rounded;
    }

    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleItemTap(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
              width: item.isRead ? 1 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon biểu thị loại thông báo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),

              // Nội dung thông báo
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
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0072E8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Thời gian
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.timeAgo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Future<void> _handleItemTap(NotificationModel item) async {
    // 1. Đánh dấu đã đọc
    if (!item.isRead) {
      await _service.markAsRead(item.notificationId);
    }

    // 2. Điều hướng tương ứng với actionUrl nếu có
    if (!mounted) return;
    final actionUrl = (item.actionUrl ?? '').toLowerCase();

    if (actionUrl.contains('group')) {
      final user = await StorageService.getUser();
      if (!mounted || user == null) return;
      Navigator.of(context).pop(); // đóng bottom sheet
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentManageGroupScreen(user: user),
        ),
      );
    } else if (actionUrl.contains('topic') || actionUrl.contains('thes')) {
      final user = await StorageService.getUser();
      if (!mounted || user == null) return;
      Navigator.of(context).pop(); // đóng bottom sheet
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentTopicListScreen(user: user),
        ),
      );
    }
  }
}
