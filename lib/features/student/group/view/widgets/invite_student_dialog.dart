import 'package:flutter/material.dart';
import '../../../../../core/localization/app_language_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/huit_loading.dart';
import '../../logic/student_group_service.dart';
import '../../model/student_group_model.dart';

/// Hộp thoại tìm kiếm và mời sinh viên chưa có nhóm tham gia vào nhóm
class InviteStudentDialog extends StatefulWidget {
  final String groupId;
  final StudentGroupService groupService;
  final StudentGroupModel? myGroup;
  final VoidCallback onInvited;

  const InviteStudentDialog({
    super.key,
    required this.groupId,
    required this.groupService,
    this.myGroup,
    required this.onInvited,
  });

  @override
  State<InviteStudentDialog> createState() => _InviteStudentDialogState();
}

class _InviteStudentDialogState extends State<InviteStudentDialog> {
  static const int _maxInvites = 5;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _invitedStudentKeys = {};
  List<CandidateStudentModel> _candidates = [];
  bool _isLoading = true;

  AppColors get _colors => AppColors.of(context);

  @override
  void initState() {
    super.initState();
    if (widget.myGroup != null) {
      for (final req in widget.myGroup!.requests) {
        if (req.isInvite && req.isPending) {
          final key = req.studentCode.isNotEmpty ? req.studentCode : req.studentId;
          if (key.isNotEmpty) _invitedStudentKeys.add(key);
        }
      }
    }
    _search();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isStudentInvited(CandidateStudentModel s) {
    final key = s.studentCode.isNotEmpty ? s.studentCode : s.id;
    return s.hasInvited || _invitedStudentKeys.contains(key) || _invitedStudentKeys.contains(s.id);
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
    });
    final list = await widget.groupService.searchCandidateStudents(_searchController.text);
    if (mounted) {
      setState(() {
        _candidates = list.map((s) {
          final isInvited = _isStudentInvited(s);
          return s.copyWith(hasInvited: isInvited);
        }).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleInvite(CandidateStudentModel student) async {
    final isAlreadyInvited = _isStudentInvited(student);
    final key = student.studentCode.isNotEmpty ? student.studentCode : student.id;

    if (isAlreadyInvited) {
      await widget.groupService.cancelInvitation(student.id);
      setState(() {
        _invitedStudentKeys.remove(key);
        _invitedStudentKeys.remove(student.id);
        _invitedStudentKeys.remove(student.studentCode);
      });
      _search();
    } else {
      if (_invitedStudentKeys.length >= _maxInvites) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn chỉ được gửi lời mời tối đa 5 lần!'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      try {
        final success = await widget.groupService.inviteStudent(
          groupId: widget.groupId,
          studentCodeOrId: student.id.isNotEmpty ? student.id : student.studentCode,
        );
        if (success) {
          setState(() {
            _invitedStudentKeys.add(key);
          });
          widget.onInvited();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể gửi lời mời. Vui lòng kiểm tra lại!'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 10,
      backgroundColor: _colors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0084FF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('invite_modal_title'),
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _colors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đã gửi: ${_invitedStudentKeys.length}/$_maxInvites lời mời',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _invitedStudentKeys.length >= _maxInvites
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0084FF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: _colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Ô Tìm kiếm
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: _colors.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _colors.inputBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _search(),
                style: TextStyle(fontSize: 13, color: _colors.textPrimary),
                decoration: InputDecoration(
                  hintText: tr('invite_search_hint'),
                  hintStyle: TextStyle(color: _colors.textMuted, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF0084FF)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Danh sách sinh viên
            Expanded(
              child: _isLoading
                  ? const Center(child: HuitLoading(size: 60, showMessage: false))
                  : _candidates.isEmpty
                      ? Center(
                          child: Text(
                            'Không tìm thấy sinh viên phù hợp.',
                            style: TextStyle(fontSize: 13, color: _colors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _candidates.length,
                          itemBuilder: (context, index) {
                            final s = _candidates[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _colors.subCardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _colors.subCardBorder),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF0084FF),
                                    child: Text(
                                      s.fullName.isNotEmpty ? s.fullName[0] : 'S',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.fullName,
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _colors.textPrimary),
                                        ),
                                        Text(
                                          '${s.studentCode} • ${s.major}',
                                          style: TextStyle(fontSize: 11.5, color: _colors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: s.hasInvited
                                          ? (_colors.isDark ? const Color(0xFF452B14) : const Color(0xFFFFFBEB))
                                          : const Color(0xFF0084FF),
                                      foregroundColor: s.hasInvited
                                          ? (_colors.isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706))
                                          : Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: s.hasInvited
                                              ? (_colors.isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A))
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    onPressed: () => _toggleInvite(s),
                                    child: Text(
                                      s.hasInvited ? tr('btn_cancel_invite') : tr('btn_send_invite'),
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
