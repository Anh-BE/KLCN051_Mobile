import 'package:flutter/material.dart';
import '../../../core/localization/app_language_service.dart';
import '../../auth/model/user_model.dart';
import '../group/view/student_group_list_screen.dart';
import '../group/view/student_manage_group_screen.dart';
import '../topic/view/student_topic_list_screen.dart';

class StudentHomeView extends StatelessWidget {
  final UserModel user;
  final Function(int)? onTabChange;

  const StudentHomeView({super.key, required this.user, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

            // 1. HEADER DẠNG VIÊN THUỐC NỔI (FLOATING PILL CAPSULE) CHUẨN 100% THEO TRANGCHU.PNG
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
                    // Avatar tròn viền trắng tinh tế
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

                    // Quả chuông thông báo trong vòng tròn mờ có chấm cam đỏ
                    Stack(
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
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 2. KHỐI CARD CHỨC NĂNG CHÍNH ĐỒNG BỘ VỚI HEADER VÀ BOTTOM BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

                    // Hàng 3 nút chức năng căn đều
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(width: 8),

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
                        const SizedBox(width: 8),

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Khung icon bo góc 16px
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 28),
              ),
            ),
            const SizedBox(height: 8),

            // Tên chức năng
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
