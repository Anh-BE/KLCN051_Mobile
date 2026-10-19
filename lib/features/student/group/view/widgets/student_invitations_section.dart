import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// Khối hiển thị lời mời gia nhập nhóm theo chuẩn Google AI / Material 3 (1 khung duy nhất, không lồng nhau)
class StudentInvitationsSection extends StatelessWidget {
  final List<StudentInvitationModel> invitations;
  final Function(StudentInvitationModel) onAccept;
  final Function(StudentInvitationModel) onReject;

  const StudentInvitationsSection({
    super.key,
    required this.invitations,
    required this.onAccept,
    required this.onReject,
  });

  static const Color _huitBlue = Color(0xFF0072E8);

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề danh sách lời mời (dạng text gọn gàng, không dùng khung bọc)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, size: 18, color: _huitBlue),
              const SizedBox(width: 8),
              Text(
                'Lời mời gia nhập nhóm (${invitations.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Mỗi lời mời là 1 thẻ Card duy nhất theo chuẩn Material 3 / Google AI Design
        ...invitations.map((inv) => _buildInvitationCard(context, inv)),
      ],
    );
  }

  Widget _buildInvitationCard(BuildContext context, StudentInvitationModel inv) {
    final colors = AppColors.of(context);
    final leaderName = inv.leaderName.isNotEmpty ? inv.leaderName : 'Nhóm trưởng';
    final leaderCode = inv.leaderCode;
    final initial = leaderName.isNotEmpty ? leaderName.trim()[0].toUpperCase() : 'N';
    final tonalBlue = colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0FE);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.cardBg, // Màu trắng chuẩn ở Light Mode
        borderRadius: BorderRadius.circular(20), // Bo góc 20 chuẩn Material You / Google AI
        border: Border.all(
          color: colors.isDark ? const Color(0xFF2E3846) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Icon nhóm + Tên nhóm + Badge "Lời mời"
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tonalBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: _huitBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.groupName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lời mời tham gia nhóm khóa luận',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tonalBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Lời mời',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _huitBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Đường kẻ ngăn cách mờ nhạt chuẩn Google
            Divider(
              height: 1,
              thickness: 1,
              color: colors.isDark ? const Color(0xFF2E3846) : const Color(0xFFF1F5F9),
            ),

            const SizedBox(height: 14),

            // 2. Thông tin Trưởng nhóm (Layout phẳng, không dùng thêm khung viền lồng nhau)
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: tonalBlue,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _huitBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            leaderName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tonalBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Trưởng nhóm',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _huitBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (leaderCode.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Mã SV: $leaderCode',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _huitBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 3. Hệ thống nút bấm chuẩn Material 3 (Pill buttons: Từ chối & Chấp nhận)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => onReject(inv),
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _huitBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  onPressed: () => onAccept(inv),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Chấp nhận',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
