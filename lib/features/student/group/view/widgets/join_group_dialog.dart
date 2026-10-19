import 'package:flutter/material.dart';
import '../../../../../core/localization/app_language_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../model/student_group_model.dart';

/// Modal dialog để nhập lời nhắn xin tham gia vào nhóm
class JoinGroupDialog extends StatefulWidget {
  final StudentGroupModel group;

  const JoinGroupDialog({
    super.key,
    required this.group,
  });

  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final group = widget.group;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 10,
      backgroundColor: colors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_add_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('join_request_title'),
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: colors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.name,
                          style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.subCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.subCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👤 Nhóm trưởng: ${group.leaderName} (${group.leaderCode})',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('📞 Liên hệ: ${group.leaderPhone}',
                        style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('👥 Hiện có: ${group.currentMembers}/${group.maxMembers} thành viên',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF0084FF), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                maxLines: 3,
                autofocus: false,
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: tr('join_request_note_hint'),
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 12.5),
                  filled: true,
                  fillColor: colors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, null),
                      child: Text(tr('cancel'), style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF0084FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, _noteController.text.trim()),
                      child: Text(tr('confirm'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
