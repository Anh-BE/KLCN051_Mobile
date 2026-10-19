import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../group/model/student_group_model.dart';
import '../../model/thesis_topic_model.dart';

/// BottomSheet hiển thị chi tiết đề tài khóa luận và nút đăng ký
class TopicDetailSheet extends StatelessWidget {
  final ThesisTopicModel topic;
  final StudentGroupModel? myGroup;
  final bool isLeader;
  final bool hasRegisteredTopic;
  final VoidCallback onRegisterPressed;

  const TopicDetailSheet({
    super.key,
    required this.topic,
    required this.myGroup,
    required this.isLeader,
    this.hasRegisteredTopic = false,
    required this.onRegisterPressed,
  });

  static const Color _primaryBlue = Color(0xFF1A73E8);

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

  Widget _buildSectionHeader(String title, Color textPrimary) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cardBg = colors.cardBg;
    final sectionBoxBg = colors.subCardBg;
    final tagBgBlue = colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF5FE);
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;
    final borderSubtle = colors.cardBorder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Thanh gạt modal
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),

          // Header Modal: "Chi tiết đề tài" + Nút đóng X
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 14, 10),
            child: Row(
              children: [
                Text(
                  'Chi tiết đề tài',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderSubtle),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên đề tài
                  Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Mã đề tài
                  Text(
                    topic.topicCode,
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Hàng Tag
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPillTag(topic.researchDirection, tagBgBlue),
                      _buildPillTag(topic.periodName, tagBgBlue),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Mục 1: Giảng viên hướng dẫn
                  _buildSectionHeader('Giảng viên hướng dẫn', textPrimary),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sectionBoxBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderSubtle.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tagBgBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              topic.lecturerInitials,
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.lecturerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topic.periodName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Mục 2: Số lượng SV tối đa
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: sectionBoxBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderSubtle.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: _primaryBlue, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Số lượng SV tối đa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          topic.maxStudents > 0 ? '${topic.maxStudents} SV' : '—',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Mục 3: Nội dung yêu cầu
                  _buildSectionHeader('Nội dung yêu cầu', textPrimary),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Mục tiêu: ',
                          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        TextSpan(
                          text: '${topic.description}\n\n',
                          style: TextStyle(color: textSecondary, height: 1.55),
                        ),
                        TextSpan(
                          text: 'Yêu cầu nghiệp vụ/kỹ thuật:\n',
                          style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary, height: 1.6),
                        ),
                        TextSpan(
                          text: topic.requirements,
                          style: TextStyle(color: textSecondary, height: 1.55),
                        ),
                        if (topic.targetOutput != null && topic.targetOutput!.isNotEmpty) ...[
                          TextSpan(
                            text: '\n\nSản phẩm / Kết quả dự kiến:\n',
                            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary, height: 1.6),
                          ),
                          TextSpan(
                            text: topic.targetOutput!,
                            style: TextStyle(color: textSecondary, height: 1.55),
                          ),
                        ],
                      ],
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 22),

                    // Mục 4: Thông tin Nhóm thực hiện
                    _buildSectionHeader('Nhóm thực hiện', textPrimary),
                    const SizedBox(height: 10),
                    _buildGroupInfoSection(
                      context: context,
                      colors: colors,
                      sectionBoxBg: sectionBoxBg,
                      borderSubtle: borderSubtle,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

          // Nút Đăng ký ở dưới đáy Modal
          _buildBottomAction(context, cardBg, borderSubtle),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection({
    required BuildContext context,
    required AppColors colors,
    required Color sectionBoxBg,
    required Color borderSubtle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isMy = topic.isRegisteredByMyGroup(myGroup?.id);
    final isTakenByOther = topic.isRegisteredByOther(myGroup?.id);
    final hasGroup = topic.hasGroup || isMy || isTakenByOther;

    if (!hasGroup) {
      // TRƯỜNG HỢP: CHƯA CÓ NHÓM
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: sectionBoxBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group_off_outlined, color: Color(0xFF94A3B8), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có nhóm',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đề tài này hiện chưa có nhóm sinh viên nào đăng ký.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // TRƯỜNG HỢP: CÓ NHÓM
    String groupName = '';
    if (isMy && myGroup != null) {
      groupName = myGroup!.name;
    } else if (topic.registeredGroupName != null && topic.registeredGroupName!.trim().isNotEmpty) {
      groupName = topic.registeredGroupName!;
    } else {
      groupName = 'Nhóm sinh viên thực hiện';
    }

    List<String> members = topic.getDisplayMemberNames(
      fallbackMembers: isMy && myGroup != null
          ? myGroup!.members.map((m) => m.fullName).toList()
          : null,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sectionBoxBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: Color(0xFF0072E8), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tên nhóm:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Có nhóm',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0072E8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderSubtle),
          const SizedBox(height: 10),
          const Text(
            'Thành viên nhóm:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          if (members.isNotEmpty)
            ...members.map(
              (memberName) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF0072E8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        memberName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Đã có thành viên tham gia nhóm.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, Color cardBg, Color borderSubtle) {
    final isMy = topic.isRegisteredByMyGroup(myGroup?.id);
    final isTakenByOther = topic.isRegisteredByOther(myGroup?.id);
    final hasExistingTopic = !isMy &&
        (hasRegisteredTopic ||
            (myGroup != null && myGroup!.hasRegisteredTopic) ||
            (myGroup?.topicName != null && myGroup!.topicName!.trim().isNotEmpty));

    // 1. Khi nhóm đã đăng ký đề tài rồi -> Ẩn toàn bộ nút đăng ký ở các đề tài khác để tránh spam
    if (hasExistingTopic) {
      return const SizedBox.shrink();
    }

    final memberCount = myGroup != null
        ? (myGroup!.currentMembers > 0
            ? myGroup!.currentMembers
            : myGroup!.members.length)
        : 0;
    final isGroupExceedsLimit = myGroup != null &&
        topic.maxStudents > 0 &&
        memberCount > topic.maxStudents;

    Color btnColor;
    String btnText;
    bool btnEnabled;
    IconData? btnIcon;

    if (isMy) {
      btnColor = const Color(0xFF10B981);
      btnText = 'ĐÃ ĐĂNG KÝ';
      btnEnabled = false;
      btnIcon = Icons.check_circle_outline_rounded;
    } else if (isTakenByOther) {
      btnColor = const Color(0xFF94A3B8);
      btnText = 'ĐỀ TÀI ĐÃ CÓ NHÓM ĐĂNG KÝ';
      btnEnabled = false;
      btnIcon = Icons.lock_outline_rounded;
    } else if (!topic.isOpen) {
      btnColor = const Color(0xFF94A3B8);
      btnText = 'ĐỀ TÀI ĐÃ ĐÓNG';
      btnEnabled = false;
      btnIcon = Icons.lock_outline_rounded;
    } else if (myGroup == null) {
      btnColor = const Color(0xFF64748B);
      btnText = 'CẦN CÓ NHÓM ĐỂ ĐĂNG KÝ';
      btnEnabled = false;
      btnIcon = Icons.group_off_outlined;
    } else if (!isLeader) {
      btnColor = const Color(0xFF64748B);
      btnText = 'CHỈ DÀNH CHO NHÓM TRƯỞNG';
      btnEnabled = false;
      btnIcon = Icons.lock_outline_rounded;
    } else if (isGroupExceedsLimit) {
      btnColor = const Color(0xFFDC2626);
      btnText = 'VƯỢT GIỚI HẠN SV ($memberCount/${topic.maxStudents} SV)';
      btnEnabled = false;
      btnIcon = Icons.group_off_rounded;
    } else {
      btnColor = _primaryBlue;
      btnText = 'ĐĂNG KÝ ĐỀ TÀI NÀY (TRƯỞNG NHÓM)';
      btnEnabled = true;
      btnIcon = Icons.assignment_turned_in_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderSubtle)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            disabledBackgroundColor: btnColor,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: btnEnabled
              ? () {
                  Navigator.pop(context);
                  onRegisterPressed();
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(btnIcon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  btnText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
