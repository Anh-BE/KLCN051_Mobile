import 'package:flutter/material.dart';
import '../../../../../core/localization/app_language_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// BottomSheet hiển thị danh sách thành viên chi tiết của một nhóm
class GroupMembersDetailSheet extends StatelessWidget {
  final StudentGroupModel group;
  final bool isLeader;
  final bool isMember;
  final String? otherGroupName;
  final VoidCallback onActionPressed;

  const GroupMembersDetailSheet({
    super.key,
    required this.group,
    required this.isLeader,
    required this.isMember,
    this.otherGroupName,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: Color(0xFF0084FF), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.name,
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.divider, height: 1),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👥 DANH SÁCH THÀNH VIÊN HIỆN TẠI',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ...group.members.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: m.isLeader
                              ? (colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                              : colors.subCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: m.isLeader ? const Color(0xFF0084FF) : colors.subCardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: m.isLeader ? const Color(0xFF0084FF) : colors.textMuted,
                              child: Text(
                                m.fullName.isNotEmpty ? m.fullName[0] : 'S',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                                        m.fullName,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: colors.textPrimary),
                                      ),
                                      if (m.isLeader) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0084FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Trưởng nhóm',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'MSSV: ${m.studentCode.isNotEmpty ? m.studentCode : getStudentCodeForName(m.fullName)} ${m.phone != null ? "• ${m.phone}" : ""}',
                                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildFooterAction(context, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(BuildContext context, AppColors colors) {
    if (isLeader) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 20, color: Color(0xFF0072E8)),
            SizedBox(width: 8),
            Text(
              'NHÓM DO BẠN TẠO (TRƯỞNG NHÓM)',
              style: TextStyle(color: Color(0xFF0072E8), fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    if (isMember) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF143022) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.isDark ? const Color(0xFF1B4D36) : const Color(0xFFBBF7D0)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text(
              'BẠN ĐÃ LÀ THÀNH VIÊN NHÓM NÀY',
              style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    if (otherGroupName != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.subCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.subCardBorder),
        ),
        child: Text(
          'BẠN ĐÃ THAM GIA NHÓM KHÁC ($otherGroupName)',
          style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (group.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.subCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          tr('btn_full'),
          style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w700),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: group.hasRequested ? const Color(0xFFF59E0B) : const Color(0xFF0084FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: () {
        Navigator.pop(context);
        onActionPressed();
      },
      child: Text(
        group.hasRequested ? tr('btn_requested') : tr('btn_join_group'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
