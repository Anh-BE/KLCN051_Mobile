import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../progress/model/student_progress_model.dart';

/// Card hiển thị kế hoạch và trạng thái báo cáo theo từng tuần của sinh viên
class WeeklyPlanCard extends StatelessWidget {
  final WeeklyPlanModel plan;
  final bool isLeader;
  final VoidCallback onSubmitPressed;
  final VoidCallback onUnsubmitPressed;

  const WeeklyPlanCard({
    super.key,
    required this.plan,
    this.isLeader = true,
    required this.onSubmitPressed,
    required this.onUnsubmitPressed,
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null || dt.year <= 2000) return 'Chưa có hạn nộp';
    String pad(int n) => n < 10 ? '0$n' : '$n';
    return '${pad(dt.hour)}:${pad(dt.minute)} ${pad(dt.day)}/${pad(dt.month)}/${dt.year}';
  }

  String _cleanPlanTitle(String title, int weekNumber) {
    final cleaned = title.replaceFirst(RegExp(r'^Tuần\s*\d+\s*[:\-\.]?\s*', caseSensitive: false), '').trim();
    return cleaned.isNotEmpty ? cleaned : title;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Phân tích trạng thái
    String? statusText;
    Color? statusColor;
    Color? statusBg;

    if (plan.report != null && plan.report!.isGraded && isLeader) {
      statusText = plan.report!.isPassed == true ? 'ĐẠT' : 'CHƯA ĐẠT';
      statusColor = plan.report!.isPassed == true ? const Color(0xFF10B981) : const Color(0xFFEF4444);
      statusBg = plan.report!.isPassed == true
          ? (colors.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
          : (colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2));
    } else if (plan.report != null && plan.report!.submittedAt != null) {
      final isTurnedIn = plan.report!.submissionStatus != 'Late' && plan.report!.submissionStatus != 'LateTurnedIn';
      statusText = isTurnedIn ? 'Đã nộp bài' : 'Nộp muộn';
      statusColor = isTurnedIn ? const Color(0xFF0284C7) : const Color(0xFFF59E0B);
      statusBg = isTurnedIn
          ? (colors.isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE))
          : (colors.isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7));
    } else if (plan.hasValidDeadline) {
      statusText = plan.isOverdue ? 'Quá hạn' : 'Đã giao bài';
      statusColor = plan.isOverdue ? const Color(0xFFEF4444) : colors.textSecondary;
      statusBg = plan.isOverdue
          ? (colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2))
          : (colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9));
    } else {
      statusText = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF007AFF).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuần ${plan.weekNumber}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              if (statusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Tên tuần
          Text(
            _cleanPlanTitle(plan.title, plan.weekNumber),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // Hạn chót
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: colors.textMuted),
              const SizedBox(width: 5),
              Text(
                plan.hasValidDeadline
                    ? 'Hạn chót: ${_formatDateTime(plan.deadline)}'
                    : 'Chưa có hạn nộp',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: (plan.isOverdue && !plan.isSubmitted && plan.hasValidDeadline)
                      ? const Color(0xFFEF4444)
                      : colors.textSecondary,
                ),
              ),
            ],
          ),

          if (plan.detailedRequirements.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.7, color: colors.divider),
            const SizedBox(height: 10),
            Text(
              plan.detailedRequirements,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          // Đã nộp bài
          if (plan.report != null && plan.report!.submittedAt != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'Đã nộp lúc: ${_formatDateTime(plan.report!.submittedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (plan.report!.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '“${plan.report!.content}”',
                      style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ],
                  if (plan.report!.reportFileUrl != null && plan.report!.reportFileUrl!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...plan.report!.reportFileUrl!.split(';').map((rawItem) {
                      final item = rawItem.trim();
                      if (item.isEmpty) return const SizedBox.shrink();
                      final isUploaded = item.contains('/uploads/');
                      String displayName = item;
                      if (isUploaded) {
                        displayName = item.split('/').last;
                        if (displayName.contains('_')) {
                          displayName = displayName.substring(displayName.indexOf('_') + 1);
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              isUploaded ? Icons.insert_drive_file_rounded : Icons.link_rounded,
                              size: 15,
                              color: isUploaded ? const Color(0xFF10B981) : colors.sectionTitle,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUploaded ? colors.textPrimary : colors.sectionTitle,
                                  decoration: isUploaded ? TextDecoration.none : TextDecoration.underline,
                                  fontWeight: isUploaded ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],

          // Nhận xét của giảng viên (Chỉ nhóm trưởng mới nhận đánh giá)
          if (isLeader &&
              plan.report != null &&
              plan.report!.isGraded &&
              (plan.report!.supervisorScore != null ||
                  (plan.report!.supervisorFeedback != null && plan.report!.supervisorFeedback!.trim().isNotEmpty))) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nhận xét từ GVHD:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (plan.report!.supervisorScore != null)
                        Text(
                          'Điểm: ${plan.report!.supervisorScore}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                  if (plan.report!.supervisorFeedback != null && plan.report!.supervisorFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${plan.report!.supervisorFeedback}”',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Nút hành động (Chỉ nhóm trưởng mới được nộp / hủy nộp bài)
          if (isLeader) ...[
            if (plan.report == null || plan.report!.submittedAt == null) ...[
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: onSubmitPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0084FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Nộp báo cáo tuần', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ),
            ] else if (!plan.report!.isGraded) ...[
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: onUnsubmitPressed,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFEF4444)),
                  label: const Text('Hủy nộp bài', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ] else ...[
            if (plan.report == null || plan.report!.submittedAt == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: colors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Chỉ nhóm trưởng mới có quyền nộp báo cáo tuần',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
