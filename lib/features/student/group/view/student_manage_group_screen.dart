import 'package:flutter/material.dart';
import '../../../../core/localization/app_language_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/student_group_service.dart';
import '../model/student_group_model.dart';
import 'widgets/invite_student_dialog.dart';
import 'widgets/student_create_group_form.dart';
import 'widgets/student_group_member_card.dart';
import 'widgets/student_group_summary_card.dart';
import 'widgets/student_invitations_section.dart';
import 'widgets/student_join_request_card.dart';

class StudentManageGroupScreen extends StatefulWidget {
  final UserModel user;
  final int initialTab;

  const StudentManageGroupScreen({
    super.key,
    required this.user,
    this.initialTab = 0,
  });

  @override
  State<StudentManageGroupScreen> createState() => _StudentManageGroupScreenState();
}

class _StudentManageGroupScreenState extends State<StudentManageGroupScreen> {
  final StudentGroupService _groupService = StudentGroupService();
  AppColors get _colors => AppColors.of(context);

  bool _isLoading = true;
  StudentGroupModel? _myGroup;
  List<GroupRequestModel> _joinRequests = [];
  List<StudentInvitationModel> _myInvitations = [];
  late int _selectedTab; // 0: Thành viên, 1: Yêu cầu xin vào

  bool get _isLeader => _myGroup != null && _myGroup!.isUserLeader(widget.user);

  // Controllers cho Form Tạo nhóm
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedMajor = 'Công nghệ phần mềm';
  bool _isSubmitting = false;
  bool _isProcessingAction = false;

  final List<String> _majors = [
    'Công nghệ phần mềm',
    'Hệ thống thông tin',
    'Mạng máy tính & TT',
    'An toàn thông tin',
    'Khoa học dữ liệu',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _phoneController.text = widget.user.phoneNumber ?? '';
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final group = await _groupService.getMyGroup(widget.user);
      List<GroupRequestModel> requests = [];
      if (group != null) {
        requests = await _groupService.getJoinRequests(group.id);
      }
      final invitations = await _groupService.getMyInvitations();

      if (mounted) {
        setState(() {
          _myGroup = group;
          _joinRequests = requests;
          _myInvitations = invitations;
          if (group == null) {
            // Khi chưa có nhóm:
            if (widget.initialTab == 1 || widget.initialTab == 2) {
              _selectedTab = 1; // Tab Lời mời nhận được
            } else if (invitations.isNotEmpty) {
              _selectedTab = 1; // Tự động chọn Tab Lời mời nếu có lời mời đang chờ duyệt
            } else {
              _selectedTab = 0; // Mặc định mở Tab Tạo nhóm mới
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading group data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Xử lý tạo nhóm mới
  Future<void> _handleCreateGroup() async {
    final name = _groupNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('Vui lòng nhập Tên nhóm khóa luận!', isError: true);
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar('Vui lòng nhập Số điện thoại liên lạc!', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newGroup = await _groupService.createGroup(
        name: name,
        major: _selectedMajor,
        phone: phone,
        user: widget.user,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _myGroup = newGroup;
        });
        _showSnackBar(tr('create_group_success'), isError: false);
        _loadGroupData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  // Duyệt yêu cầu
  Future<void> _handleApproveRequest(GroupRequestModel request) async {
    if (_myGroup == null || _isProcessingAction) return;

    if (_myGroup!.isFull) {
      _showSnackBar(
        'Nhóm đã đủ số lượng thành viên tối đa (${_myGroup!.currentMembers}/${_myGroup!.maxMembers})!',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessingAction = true;
    });

    try {
      final success = await _groupService.approveJoinRequest(_myGroup!.id, request);
      if (success) {
        _showSnackBar('Đã duyệt sinh viên ${request.studentName} vào nhóm thành công!', isError: false);
        await _loadGroupData();
      } else {
        _showSnackBar('Không thể duyệt yêu cầu.', isError: true);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  // Từ chối yêu cầu
  Future<void> _handleRejectRequest(GroupRequestModel request) async {
    if (_myGroup == null || _isProcessingAction) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận từ chối', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5)),
        content: Text('Bạn có chắc chắn muốn từ chối yêu cầu tham gia nhóm của sinh viên ${request.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessingAction = true;
    });

    try {
      final success = await _groupService.rejectJoinRequest(_myGroup!.id, request.id);
      if (success) {
        _showSnackBar('Đã từ chối yêu cầu của ${request.studentName}.', isError: false);
        await _loadGroupData();
      } else {
        _showSnackBar('Không thể từ chối yêu cầu.', isError: true);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  // Xử lý chấp nhận lời mời tham gia nhóm
  Future<void> _handleAcceptInvitation(StudentInvitationModel inv) async {
    try {
      final ok = await _groupService.acceptInvitation(inv.requestId);
      if (ok) {
        _showSnackBar('Đã gia nhập nhóm ${inv.groupName} thành công!', isError: false);
        _selectedTab = 0;
        _loadGroupData();
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  // Xử lý từ chối lời mời tham gia nhóm
  Future<void> _handleRejectInvitation(StudentInvitationModel inv) async {
    try {
      final ok = await _groupService.rejectInvitation(inv.requestId);
      if (ok) {
        _showSnackBar('Đã từ chối lời mời vào ${inv.groupName}', isError: false);
        _loadGroupData();
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  // Mở Dialog Mời thành viên mới
  void _showInviteStudentDialog() {
    if (_myGroup == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InviteStudentDialog(
        groupId: _myGroup!.id,
        groupService: _groupService,
        myGroup: _myGroup,
        onInvited: () {
          _showSnackBar(tr('invite_success'), isError: false);
          _loadGroupData();
        },
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh nền hoặc Dark Gradient
          Positioned.fill(
            child: _colors.isDark
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _colors.pageGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/bg_main.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: _colors.scaffoldBg,
                    ),
                  ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. TOP APP BAR
                _buildHeader(),

                // 2. NỘI DUNG MÀN HÌNH
                Expanded(
                  child: _isLoading
                      ? const Center(child: HuitLoading(size: 74))
                      : _myGroup == null
                          ? _buildNoGroupView()
                          : _buildGroupManagementView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String title;
    if (_myGroup != null) {
      title = tr('my_group_title');
    } else {
      title = _selectedTab == 1 ? 'LỜI MỜI GIA NHẬP NHÓM' : 'TẠO NHÓM KHÓA LUẬN';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0072E8), Color(0xFF0091FF), Color(0xFF00A2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN 1: KHI SINH VIÊN CHƯA CÓ NHÓM
  // (Tách thành 2 Tab riêng biệt: Tạo nhóm mới & Lời mời nhận được)
  // ==========================================
  Widget _buildNoGroupView() {
    return Column(
      children: [
        // 1. THANH TAB DÀNH CHO BẠN CHƯA CÓ NHÓM
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: _colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildNoGroupUnderlineTabBar(),
          ),
        ),

        // 2. NỘI DUNG THEO TAB
        Expanded(
          child: _selectedTab == 1
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _buildInvitationsTabContent(),
                )
              : StudentCreateGroupForm(
                  groupNameController: _groupNameController,
                  phoneController: _phoneController,
                  selectedMajor: _selectedMajor,
                  majors: _majors,
                  onMajorChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMajor = val;
                      });
                    }
                  },
                  isSubmitting: _isSubmitting,
                  onSubmit: _handleCreateGroup,
                ),
        ),
      ],
    );
  }

  // TAB BAR 2 MỤC CHO SINH VIÊN CHƯA CÓ NHÓM
  Widget _buildNoGroupUnderlineTabBar() {
    const activeColor = Color(0xFF0072E8);
    final inactiveColor = _colors.textSecondary;
    final inactiveIconColor = _colors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildUnderlineTabItem(
                index: 0,
                icon: Icons.group_add_rounded,
                label: 'Tạo nhóm mới',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                inactiveIconColor: inactiveIconColor,
              ),
            ),
            Expanded(
              child: _buildUnderlineTabItem(
                index: 1,
                icon: Icons.mark_email_unread_rounded,
                label: 'Lời mời nhận được',
                hasBadge: _myInvitations.isNotEmpty,
                badgeCount: _myInvitations.length,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                inactiveIconColor: inactiveIconColor,
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(
              height: 2.0,
              color: _colors.cardBorder,
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: _selectedTab == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // GIAO DIỆN 2: BẢNG QUẢN LÝ NHÓM (DÀNH CHO TRƯỞNG NHÓM)
  // ==========================================
  Widget _buildGroupManagementView() {
    final group = _myGroup!;
    final isLeader = _isLeader;

    return Column(
      children: [
        // 1. THANH TAB DÀNH CHO NHÓM (Nhóm của tôi / Yêu cầu xin vào / Lời mời nhóm)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: _colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildUnderlineTabBar(group, isLeader: isLeader),
            ),
          ),
        ),

        // 2. NỘI DUNG CUỘN THEO TAB ĐANG CHỌN
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _buildCurrentTabContent(group, isLeader),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTabContent(StudentGroupModel group, bool isLeader) {
    if (isLeader) {
      if (_selectedTab == 1) {
        return _buildJoinRequestsTabContent();
      }
      if (_selectedTab == 2) {
        return _buildInvitationsTabContent();
      }
      return _buildMyGroupTabContent(group);
    } else {
      if (_selectedTab == 1) {
        return _buildInvitationsTabContent();
      }
      return _buildMyGroupTabContent(group);
    }
  }

  // TAB 1: NHÓM CỦA TÔI (GỒM Ô THÔNG TIN NHÓM VÀ CÁC THÀNH VIÊN Ở DƯỚI)
  Widget _buildMyGroupTabContent(StudentGroupModel group) {
    final isLeader = _isLeader;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ô THÔNG TIN NHÓM
        StudentGroupSummaryCard(group: group),

        const SizedBox(height: 14),

        // NÚT MỜI THÀNH VIÊN MỚI (CHỈ DÀNH CHO TRƯỞNG NHÓM)
        if (isLeader) ...[
          if (!group.isFull) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                label: Text(
                  tr('btn_invite_member'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: _showInviteStudentDialog,
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: _colors.subCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _colors.subCardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    'Nhóm đã đủ số lượng thành viên (${group.currentMembers}/${group.maxMembers})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],

        // DANH SÁCH THÀNH VIÊN TRONG NHÓM
        ...group.members.map((m) => StudentGroupMemberCard(
          member: m,
          isCurrentLeader: isLeader,
        )),
      ],
    );
  }

  // TAB 2: YÊU CẦU XIN VÀO (CHỈ HIỆN DANH SÁCH SINH VIÊN XIN VÀO NHÓM NÀY)
  Widget _buildJoinRequestsTabContent() {
    if (_joinRequests.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _colors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _colors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.person_add_disabled_rounded, size: 48, color: _colors.textMuted),
            const SizedBox(height: 12),
            Text(
              tr('no_pending_requests'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._joinRequests.map((req) => StudentJoinRequestCard(
          request: req,
          isProcessingAction: _isProcessingAction,
          isGroupFull: _myGroup?.isFull ?? false,
          currentMembers: _myGroup?.currentMembers ?? 0,
          maxMembers: _myGroup?.maxMembers ?? 3,
          onApprove: _handleApproveRequest,
          onReject: _handleRejectRequest,
        )),
      ],
    );
  }

  // TAB 3: LỜI MỜI NHÓM (CHỈ HIỆN CÁC LỜI MỜI DO NHÓM KHÁC GỬI ĐẾN TÀI KHOẢN NÀY)
  Widget _buildInvitationsTabContent() {
    if (_myInvitations.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _colors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _colors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.mail_outline_rounded, size: 48, color: _colors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Không có lời mời gia nhập nhóm nào',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return StudentInvitationsSection(
      invitations: _myInvitations,
      onAccept: _handleAcceptInvitation,
      onReject: _handleRejectInvitation,
    );
  }

  // TAB BAR VỚI HIỆU ỨNG GẠCH CHÂN CHUẨN DOANH NGHIỆP
  Widget _buildUnderlineTabBar(StudentGroupModel group, {required bool isLeader}) {
    const activeColor = Color(0xFF0072E8);
    final inactiveColor = _colors.textSecondary;
    final inactiveIconColor = _colors.textMuted;

    if (isLeader) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildUnderlineTabItem(
                  index: 0,
                  icon: Icons.groups_rounded,
                  label: 'Nhóm của tôi',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  inactiveIconColor: inactiveIconColor,
                ),
              ),
              Expanded(
                child: _buildUnderlineTabItem(
                  index: 1,
                  icon: Icons.person_add_rounded,
                  label: 'Yêu cầu xin vào',
                  hasBadge: _joinRequests.isNotEmpty,
                  badgeCount: _joinRequests.length,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  inactiveIconColor: inactiveIconColor,
                ),
              ),
              Expanded(
                child: _buildUnderlineTabItem(
                  index: 2,
                  icon: Icons.mark_email_unread_rounded,
                  label: 'Lời mời nhóm',
                  hasBadge: _myInvitations.isNotEmpty,
                  badgeCount: _myInvitations.length,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  inactiveIconColor: inactiveIconColor,
                ),
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                height: 2.0,
                color: _colors.cardBorder,
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: _selectedTab == 0
                    ? const Alignment(-1.0, 0.0)
                    : _selectedTab == 1
                        ? const Alignment(0.0, 0.0)
                        : const Alignment(1.0, 0.0),
                child: FractionallySizedBox(
                  widthFactor: 1.0 / 3.0,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildUnderlineTabItem(
                  index: 0,
                  icon: Icons.groups_rounded,
                  label: 'Nhóm của tôi',
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  inactiveIconColor: inactiveIconColor,
                ),
              ),
              Expanded(
                child: _buildUnderlineTabItem(
                  index: 1,
                  icon: Icons.mark_email_unread_rounded,
                  label: 'Lời mời nhóm',
                  hasBadge: _myInvitations.isNotEmpty,
                  badgeCount: _myInvitations.length,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  inactiveIconColor: inactiveIconColor,
                ),
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                height: 2.0,
                color: _colors.cardBorder,
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: _selectedTab == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildUnderlineTabItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    required Color inactiveIconColor,
    bool hasBadge = false,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : inactiveIconColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasBadge && badgeCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
