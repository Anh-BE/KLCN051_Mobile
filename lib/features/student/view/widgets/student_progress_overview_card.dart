import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../progress/model/student_progress_model.dart';

/// Card tổng quan tiến độ đề tài khóa luận của sinh viên
class StudentProgressOverviewCard extends StatelessWidget {
  final StudentThesisProgressModel data;

  const StudentProgressOverviewCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF007AFF).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ thực hiện đề tài',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: colors.sectionTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đang thực hiện',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.thesisTitle.isNotEmpty ? data.thesisTitle : 'Đề tài khóa luận',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_pin_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'GVHD: ${data.supervisorName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ nộp báo cáo:',
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
              Text(
                '${data.submittedCount} / ${data.weeklyPlans.length} tuần (${data.completionPercent}%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: data.weeklyPlans.isEmpty ? 0 : data.completionPercent / 100,
              minHeight: 7,
              backgroundColor: colors.isDark ? const Color(0xFF26282C) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(colors.sectionTitle),
            ),
          ),
        ],
      ),
    );
  }
}
