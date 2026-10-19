import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// Thẻ hiển thị thông tin từng thành viên trong nhóm
class StudentGroupMemberCard extends StatelessWidget {
  final GroupMemberModel member;
  final bool isCurrentLeader;
  const StudentGroupMemberCard({
    super.key,
    required this.member,
    required this.isCurrentLeader,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: member.isLeader ? const Color(0xFF0072E8) : colors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: member.isLeader ? const Color(0xFF0072E8) : const Color(0xFF93C5FD),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: member.isLeader
                  ? (colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                  : (colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9)),
              child: Text(
                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'S',
                style: TextStyle(
                  color: member.isLeader ? const Color(0xFF0072E8) : colors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
                    Flexible(
                      child: Text(
                        member.fullName,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0072E8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Trưởng nhóm',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'MSSV: ${member.studentCode.isNotEmpty ? member.studentCode : getStudentCodeForName(member.fullName)}',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    if (member.phone != null && member.phone!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${member.phone}',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
