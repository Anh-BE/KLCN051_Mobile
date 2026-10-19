import 'package:flutter/material.dart';
import '../../../../../core/localization/app_language_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// Thẻ hiển thị thông tin nhóm trong danh sách tìm kiếm nhóm của sinh viên
class StudentGroupCard extends StatelessWidget {
  final StudentGroupModel group;
  final bool isLeader;
  final bool isMember;
  final String? otherGroupName;
  final VoidCallback onTapDetail;
  final VoidCallback onAction;
  final void Function(String otherGroupName)? onHasOtherGroupTap;

  const StudentGroupCard({
    super.key,
    required this.group,
    required this.isLeader,
    required this.isMember,
    this.otherGroupName,
    required this.onTapDetail,
    required this.onAction,
    this.onHasOtherGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header của card: Tên nhóm & nút chevron
          InkWell(
            onTap: onTapDetail,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: group.isFull ? colors.textMuted : const Color(0xFF0084FF),
                        width: 2.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 22),
                ],
              ),
            ),
          ),

          Divider(color: colors.divider, height: 1, thickness: 1),

          // 2. Nội dung chi tiết các hàng thông tin
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                _buildInfoRow(
                  colors: colors,
                  icon: Icons.person_rounded,
                  label: tr('group_leader'),
                  value: '${group.leaderName} (${group.leaderCode})',
                  isBold: true,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  colors: colors,
                  icon: Icons.phone_android_rounded,
                  label: tr('group_contact'),
                  value: group.leaderPhone,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  colors: colors,
                  icon: Icons.school_rounded,
                  label: tr('group_major'),
                  value: group.major,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  colors: colors,
                  icon: Icons.groups_rounded,
                  label: tr('group_members'),
                  value: '${group.currentMembers}/${group.maxMembers}',
                  valueColor: group.isFull ? const Color(0xFFEF4444) : const Color(0xFF0084FF),
                  isBold: true,
                ),
              ],
            ),
          ),

          // 3. Nút hành động tương ứng ở chân thẻ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: _buildActionButton(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required AppColors colors,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5.5),
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF0284C7)),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(AppColors colors) {
    if (isLeader) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE), width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFF0072E8)),
            SizedBox(width: 6),
            Text(
              'NHÓM CỦA BẠN (TRƯỞNG NHÓM)',
              style: TextStyle(
                color: Color(0xFF0072E8),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    if (isMember) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF143022) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.isDark ? const Color(0xFF1B4D36) : const Color(0xFFBBF7D0), width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
            SizedBox(width: 6),
            Text(
              'BẠN ĐÃ LÀ THÀNH VIÊN',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    if (otherGroupName != null) {
      return InkWell(
        onTap: () {
          onHasOtherGroupTap?.call(otherGroupName!);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: colors.subCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.subCardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'BẠN ĐÃ CÓ NHÓM',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (group.isFull) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: colors.subCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.subCardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, size: 17, color: colors.textMuted),
            const SizedBox(width: 6),
            Text(
              tr('btn_full'),
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    if (group.hasRequested) {
      return InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF452B14) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
              width: 1.2,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 17, color: Color(0xFFD97706)),
              SizedBox(width: 6),
              Text(
                'ĐÃ GỬI YÊU CẦU',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onAction,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF143022) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.isDark ? const Color(0xFF1B4D36) : const Color(0xFFBBF7D0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 18, color: Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Text(
              tr('btn_join_group'),
              style: const TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
