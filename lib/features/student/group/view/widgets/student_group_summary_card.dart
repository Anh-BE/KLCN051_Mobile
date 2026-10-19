import 'package:flutter/material.dart';
import '../../../../../core/localization/app_language_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// Ô thẻ tóm tắt thông tin nhóm (Tên nhóm, chuyên ngành, SĐT, số lượng SV, trạng thái)
class StudentGroupSummaryCard extends StatelessWidget {
  final StudentGroupModel group;

  const StudentGroupSummaryCard({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: Color(0xFF0072E8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.name,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: group.isFull
                      ? colors.subCardBg
                      : (colors.isDark ? const Color(0xFF143022) : const Color(0xFFF0FDF4)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: group.isFull
                        ? colors.subCardBorder
                        : (colors.isDark ? const Color(0xFF1B4D36) : const Color(0xFFBBF7D0)),
                  ),
                ),
                child: Text(
                  group.isFull ? 'Đã đủ' : 'Đang tuyển',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: group.isFull ? colors.textSecondary : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.cardBorder, height: 16, thickness: 1.0),
          _buildInfoRow(colors, 'ID nhóm', group.id.isNotEmpty ? group.id : group.code),
          Divider(height: 16, thickness: 1.0, color: colors.cardBorder),
          _buildInfoRow(colors, tr('group_major'), group.major),
          Divider(height: 16, thickness: 1.0, color: colors.cardBorder),
          _buildInfoRow(colors, tr('group_contact'), group.leaderPhone),
          Divider(height: 16, thickness: 1.0, color: colors.cardBorder),
          _buildInfoRow(colors, tr('group_members'), '${group.currentMembers}/${group.maxMembers} thành viên'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(AppColors colors, String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.2,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.2,
                fontWeight: isStatus ? FontWeight.w800 : FontWeight.w700,
                color: isStatus ? const Color(0xFF0084FF) : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
