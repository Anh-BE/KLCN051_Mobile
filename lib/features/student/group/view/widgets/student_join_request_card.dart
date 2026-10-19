import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// Thẻ yêu cầu xin vào nhóm dành cho Trưởng nhóm xem xét (Duyệt / Từ chối)
class StudentJoinRequestCard extends StatelessWidget {
  final GroupRequestModel request;
  final bool isProcessingAction;
  final bool isGroupFull;
  final int currentMembers;
  final int maxMembers;
  final Function(GroupRequestModel) onApprove;
  final Function(GroupRequestModel) onReject;

  const StudentJoinRequestCard({
    super.key,
    required this.request,
    required this.isProcessingAction,
    required this.isGroupFull,
    this.currentMembers = 0,
    this.maxMembers = 3,
    required this.onApprove,
    required this.onReject,
  });

  String _formatRequestTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (isToday) {
        return '$timeStr Hôm nay';
      }
      return '$timeStr ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw.contains('T') ? raw.split('T').first : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0072E8),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                  child: Text(
                    request.studentName.isNotEmpty ? request.studentName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Color(0xFF0072E8), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MSSV: ${request.studentCode.isNotEmpty ? request.studentCode : getStudentCodeForName(request.studentName)} • ${request.major}',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: colors.subCardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatRequestTime(request.createdAt),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          if (request.note != null &&
              request.note!.trim().isNotEmpty &&
              request.note != 'StudentJoinRequest' &&
              request.note != 'LeaderInvite') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF143022) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.isDark ? const Color(0xFF1B4D36) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_rounded, size: 15, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do: "${request.note}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 2 Nút hành động: Từ chối & Duyệt vào nhóm
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessingAction ? null : () => onReject(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                    foregroundColor: colors.isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                    elevation: 0,
                    side: BorderSide(
                      color: colors.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text(
                    'TỪ CHỐI',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isProcessingAction || isGroupFull) ? null : () => onApprove(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGroupFull ? const Color(0xFF94A3B8) : const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text(
                    isGroupFull ? 'NHÓM ĐÃ ĐỦ ($currentMembers/$maxMembers)' : 'DUYỆT VÀO NHÓM',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
