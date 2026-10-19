import 'package:flutter/material.dart';
import '../../../../../core/localization/app_language_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// Form tạo nhóm mới khi sinh viên chưa gia nhập nhóm nào
class StudentCreateGroupForm extends StatelessWidget {
  final TextEditingController groupNameController;
  final TextEditingController phoneController;
  final String selectedMajor;
  final List<String> majors;
  final ValueChanged<String?> onMajorChanged;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final List<StudentInvitationModel> invitations;
  final Function(StudentInvitationModel)? onAcceptInvitation;
  final Function(StudentInvitationModel)? onRejectInvitation;

  const StudentCreateGroupForm({
    super.key,
    required this.groupNameController,
    required this.phoneController,
    required this.selectedMajor,
    required this.majors,
    required this.onMajorChanged,
    required this.isSubmitting,
    required this.onSubmit,
    this.invitations = const [],
    this.onAcceptInvitation,
    this.onRejectInvitation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Khung nhập thông tin tạo nhóm mới
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.04),
                  blurRadius: 12,
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.group_add_rounded,
                        color: colors.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('create_group_title'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            tr('create_group_subtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: colors.cardBorder, height: 1),
                const SizedBox(height: 18),

                // 1. Tên nhóm
                Text(
                  tr('group_name_label'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: groupNameController,
                  style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: tr('group_name_hint'),
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: colors.inputBg,
                    prefixIcon: const Icon(Icons.groups_rounded, size: 20, color: Color(0xFF0084FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Chuyên ngành
                Text(
                  tr('group_major_select'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMajor,
                      isExpanded: true,
                      dropdownColor: colors.cardBg,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary),
                      items: majors.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: onMajorChanged,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Số điện thoại Trưởng nhóm
                Text(
                  tr('leader_phone_label'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: tr('leader_phone_hint'),
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: colors.inputBg,
                    prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFF0084FF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Thông tin quy định nhóm
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0084FF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Theo quy định của Khoa CNTT, mỗi nhóm khóa luận gồm tối đa 3 sinh viên.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Nút Tạo nhóm
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0084FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: isSubmitting ? null : onSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Text(
                            tr('btn_create_group'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
