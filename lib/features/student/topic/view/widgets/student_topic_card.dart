import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/thesis_topic_model.dart';

/// Thẻ hiển thị thông tin tóm tắt của một đề tài khóa luận trong danh sách
class StudentTopicCard extends StatelessWidget {
  final ThesisTopicModel topic;
  final String? myGroupId;
  final VoidCallback onTap;

  const StudentTopicCard({
    super.key,
    required this.topic,
    this.myGroupId,
    required this.onTap,
  });

  static const Color _primaryBlue = Color(0xFF1A73E8);
  static const Color _textGreen = Color(0xFF10B981);

  Widget _buildPillTag(String label, Color tagBgBlue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tagBgBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cardBg = colors.cardBg;
    final borderSubtle = colors.cardBorder;
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;
    final textMuted = colors.textMuted;
    final tagBgBlue = colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF5FE);
    final tagBgGreen = colors.isDark ? const Color(0xFF143022) : const Color(0xFFEBF8F2);

    final isMy = topic.isRegisteredByMyGroup(myGroupId);
    final isTakenByOther = topic.isRegisteredByOther(myGroupId);

    Color tagBg;
    Color tagText;
    String tagLabel;

    if (isMy) {
      tagBg = const Color(0xFFEEF5FE);
      tagText = const Color(0xFF0072E8);
      tagLabel = 'ĐÃ ĐĂNG KÝ';
    } else if (isTakenByOther) {
      tagBg = const Color(0xFFFFF7ED);
      tagText = const Color(0xFFEA580C);
      tagLabel = 'ĐÃ CÓ NHÓM';
    } else if (topic.isOpen) {
      tagBg = tagBgGreen;
      tagText = _textGreen;
      tagLabel = 'MỞ ĐĂNG KÝ';
    } else {
      tagBg = const Color(0xFFF1F5F9);
      tagText = textSecondary;
      tagLabel = 'ĐÃ ĐÓNG';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Mã đề tài (trái) + Trạng thái đề tài (phải)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      topic.topicCode,
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tagLabel,
                        style: TextStyle(
                          color: tagText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Hàng 2: Tiêu đề đề tài
                Text(
                  topic.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 12),

                // Hàng 3: Giảng viên (Avatar tròn BD + Tên)
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tagBgBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          topic.lecturerInitials,
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic.lecturerName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Hàng 4: Các Tag (Nghiên cứu, Đợt...)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPillTag(topic.researchDirection, tagBgBlue),
                    _buildPillTag(topic.periodName, tagBgBlue),
                  ],
                ),

                const SizedBox(height: 12),

                // Hàng 5: Giới hạn SV + Chevron icon
                Row(
                  children: [
                    Icon(Icons.people_alt_outlined, size: 17, color: textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      topic.studentLimitDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, size: 20, color: textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
