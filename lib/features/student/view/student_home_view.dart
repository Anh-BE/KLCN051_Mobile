import 'package:flutter/material.dart';
import '../../../core/localization/app_language_service.dart';
import '../../auth/model/user_model.dart';
import '../group/view/student_group_list_screen.dart';
import '../group/view/student_manage_group_screen.dart';
import '../tasks/logic/notification_service.dart';
import '../tasks/logic/student_task_service.dart';
import '../tasks/model/student_task_model.dart';
import '../tasks/view/student_notification_screen.dart';
import '../tasks/view/student_task_deadline_screen.dart';
import '../topic/view/student_topic_list_screen.dart';

class StudentHomeView extends StatelessWidget {
  final UserModel user;
  final Function(int)? onTabChange;

  const StudentHomeView({super.key, required this.user, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final taskService = StudentTaskService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // 1. HEADER DẠNG VIÊN THUỐC NỔI (FLOATING PILL CAPSULE) CHUẨN TRANGCHU
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0072E8), Color(0xFF0091FF), Color(0xFF00A2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Avatar tròn viền trắng
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white.withValues(alpha: 0.25),
                      image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                          : null,
                    ),
child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Tên và MSSV
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'MSSV: ${user.identifierCode}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quả chuông thông báo (Hiển thị badge số lượng thông báo deadline & mở màn hình thông báo)
                  AnimatedBuilder(
                    animation: NotificationService(),
                    builder: (context, _) {
                      final unreadCount = NotificationService().unreadCount;

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentNotificationScreen(user: user),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. BANNER NHẮC VIỆC & DEADLINE TỰ ĐỘNG (THEO MỐC 23:59:59)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: taskService,
              builder: (context, _) {
                final urgentTask = taskService.upcomingUrgentTask;
                if (urgentTask == null) return const SizedBox.shrink();

                final isOverdue = urgentTask.status == TaskStatus.overdue;

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentTaskDeadlineScreen(user: user),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isOverdue ? Colors.red : const Color(0xFF007AFF)).withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isOverdue ? Icons.warning_amber_rounded : Icons.alarm_on_rounded,
                                color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOverdue ? 'NHẮC VIỆC: CÓ BÁO CÁO QUÁ HẠN 23:59' : 'NHẮC VIỆC: DEADLINE SẮP TỚI (23:59)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          urgentTask.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: urgentTask.statusBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                urgentTask.remainingTimeFormatted,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: urgentTask.statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hạn chót: ${urgentTask.deadline.day}/${urgentTask.deadline.month} 23:59',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 3. KHỐI CARD CHỨC NĂNG CHÍNH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề khối
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF5FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          size: 16,
                          color: Color(0xFF0072E8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr('main_functions'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Khóa luận 2026',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Lưới 4 nút chức năng (2 dòng x 2 cột)
                  Row(
                    children: [
                      // Nút 1: Xem nhóm
                      Expanded(
                        child: _buildActionItem(
                          icon: Icons.groups_rounded,
                          title: tr('view_group'),
                          iconBg: const Color(0xFFE8F1FE),
                          iconColor: const Color(0xFF0072E8),
                          borderColor: const Color(0xFFD4E5FC),
                          onTap: () async {
                            final targetIndex = await Navigator.of(context).push<int>(
                              MaterialPageRoute(
                                builder: (_) => StudentGroupListScreen(user: user),
                              ),
                            );
                            if (targetIndex != null && onTabChange != null) {
                              onTabChange!(targetIndex);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nút 2: Tạo / Mời nhóm
                      Expanded(
                        child: _buildActionItem(
                          icon: Icons.person_add_alt_1_rounded,
                          title: tr('create_invite_group'),
                          iconBg: const Color(0xFFE0F7FA),
                          iconColor: const Color(0xFF0097A7),
                          borderColor: const Color(0xFFB2EBF2),
                          onTap: () async {
                            final targetIndex = await Navigator.of(context).push<int>(
                              MaterialPageRoute(
                                builder: (_) => StudentManageGroupScreen(user: user),
                              ),
                            );
                            if (targetIndex != null && onTabChange != null) {
                              onTabChange!(targetIndex);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Nút 3: Đăng ký đề tài
                      Expanded(
                        child: _buildActionItem(
                          icon: Icons.edit_note_rounded,
                          title: tr('register_topic'),
                          iconBg: const Color(0xFFEEF2FF),
                          iconColor: const Color(0xFF4F46E5),
                          borderColor: const Color(0xFFE0E7FF),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentTopicListScreen(user: user),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nút 4: Nhắc việc & Deadline (23:59)
                      Expanded(
                        child: _buildActionItem(
                          icon: Icons.alarm_rounded,
                          title: 'Nhắc việc & Deadline',
                          iconBg: const Color(0xFFFFF7ED),
                          iconColor: const Color(0xFFEA580C),
                          borderColor: const Color(0xFFFED7AA),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentTaskDeadlineScreen(user: user),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  // WIDGET NÚT CHỨC NĂNG BÊN TRONG KHỐI CARD
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required Color iconBg,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
