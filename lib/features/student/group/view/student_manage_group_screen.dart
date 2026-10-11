import 'package:flutter/material.dart';
import '../../../../core/localization/app_language_service.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/student_group_service.dart';
import '../model/student_group_model.dart';

class StudentManageGroupScreen extends StatefulWidget {
  final UserModel user;

  const StudentManageGroupScreen({super.key, required this.user});

  @override
  State<StudentManageGroupScreen> createState() => _StudentManageGroupScreenState();
}

class _StudentManageGroupScreenState extends State<StudentManageGroupScreen> {
  final StudentGroupService _groupService = StudentGroupService();

  bool _isLoading = true;
  StudentGroupModel? _myGroup;
  List<GroupRequestModel> _joinRequests = [];
  List<StudentInvitationModel> _myInvitations = [];
  int _selectedTab = 0; // 0: Thành viên, 1: Yêu cầu xin vào

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
      _showSnackBar('Nhóm đã đủ số lượng thành viên tối đa (3/3)!', isError: true);
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

  // Xóa thành viên
  Future<void> _handleRemoveMember(GroupMemberModel member) async {
    if (_myGroup == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa thành viên', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5)),
        content: Text('Bạn có chắc chắn muốn xóa ${member.fullName} khỏi nhóm không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('confirm'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _groupService.removeMember(_myGroup!.id, member.id);
      _showSnackBar(tr('remove_member_success'), isError: false);
      _loadGroupData();
    }
  }

  // Mở Dialog Mời thành viên mới
  void _showInviteStudentDialog() {
    if (_myGroup == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _InviteStudentDialog(
        groupId: _myGroup!.id,
        groupService: _groupService,
        onInvited: () {
          _showSnackBar(tr('invite_success'), isError: false);
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
          // Ảnh nền
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_main.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF1F5F9),
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
                          ? _buildCreateGroupForm()
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
    final isLeader = _myGroup != null;
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
                isLeader ? tr('my_group_title') : tr('create_group_title'),
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
  // GIAO DIỆN 1: FORM TẠO NHÓM MỚI (CHO BẠN CHƯA CÓ NHÓM)
  // ==========================================
  Widget _buildCreateGroupForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInvitationsSection(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                    color: const Color(0xFFE0F2FE),
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
                        tr('create_group_title'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        tr('create_group_subtitle'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 18),

            // 1. Tên nhóm
            Text(tr('group_name_label'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            TextField(
              controller: _groupNameController,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: tr('group_name_hint'),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(Icons.groups_rounded, size: 20, color: Color(0xFF0084FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Chuyên ngành
            Text(tr('group_major_select'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMajor,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  items: _majors.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMajor = val;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Số điện thoại Trưởng nhóm
            Text(tr('leader_phone_label'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: tr('leader_phone_hint'),
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFF0084FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Thông tin quy định nhóm
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF0084FF)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Theo quy định của Khoa CNTT, mỗi nhóm khóa luận gồm tối đa 3 sinh viên.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
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
                onPressed: _isSubmitting ? null : _handleCreateGroup,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : Text(
                        tr('btn_create_group'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
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

  Widget _buildInvitationsSection() {
    if (_myInvitations.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_email_unread_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bạn có ${_myInvitations.length} lời mời gia nhập nhóm',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF14532D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._myInvitations.map((inv) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.groupName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Lời mời từ nhóm trưởng',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => _handleRejectInvitation(inv),
                  child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleAcceptInvitation(inv),
                  child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN 2: BẢNG QUẢN LÝ NHÓM (DÀNH CHO TRƯỞNG NHÓM)
  // ==========================================
  Widget _buildGroupManagementView() {
    final group = _myGroup!;
    final isLeader = _isLeader;

    if (!isLeader) {
      // Thành viên bình thường: chỉ xem thông tin nhóm và danh sách thành viên
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: _buildMyGroupTabContent(group),
      );
    }

    return Column(
      children: [
        // 1. THANH TAB DÀNH CHO TRƯỞNG NHÓM (Nhóm của tôi / Yêu cầu xin vào)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildUnderlineTabBar(group),
            ),
          ),
        ),

        // 2. NỘI DUNG CUỘN THEO TAB ĐANG CHỌN
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _selectedTab == 0
                ? _buildMyGroupTabContent(group)
                : _buildJoinRequestsTabContent(),
          ),
        ),
      ],
    );
  }

  // TAB 1: NHÓM CỦA TÔI (GỒM Ô THÔNG TIN NHÓM VÀ CÁC THÀNH VIÊN Ở DƯỚI)
  Widget _buildMyGroupTabContent(StudentGroupModel group) {
    final isLeader = _isLeader;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ô THÔNG TIN NHÓM
        _buildGroupSummaryCard(group),

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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Nhóm đã đủ số lượng thành viên (3/3)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],

        // DANH SÁCH THÀNH VIÊN TRONG NHÓM
        ...group.members.map((m) => _buildMemberCard(m)),
      ],
    );
  }

  // TAB 2: YÊU CẦU XIN VÀO (CHỈ HIỆN DANH SÁCH SINH VIÊN XIN VÀO)
  Widget _buildJoinRequestsTabContent() {
    if (_joinRequests.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              tr('no_pending_requests'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _joinRequests.map((req) => _buildJoinRequestCard(req)).toList(),
    );
  }

  // Ô THÔNG TIN TÓM TẮT NHÓM
  Widget _buildGroupSummaryCard(StudentGroupModel group) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: Color(0xFF0072E8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: group.isFull ? const Color(0xFFF1F5F9) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: group.isFull ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  group.isFull ? 'Đã đủ' : 'Đang tuyển',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: group.isFull ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),
          _buildSummaryRow(Icons.school_rounded, tr('group_major'), group.major),
          const SizedBox(height: 6),
          _buildSummaryRow(Icons.phone_android_rounded, tr('group_contact'), group.leaderPhone),
          const SizedBox(height: 6),
          _buildSummaryRow(Icons.groups_rounded, tr('group_members'), '${group.currentMembers}/${group.maxMembers} thành viên'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // TAB BAR VỚI HIỆU ỨNG GẠCH CHÂN CHUẨN DOANH NGHIỆP
  Widget _buildUnderlineTabBar(StudentGroupModel group) {
    const activeColor = Color(0xFF0072E8);
    const inactiveColor = Color(0xFF64748B);
    const inactiveIconColor = Color(0xFF94A3B8);

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
              color: const Color(0xFFE2E8F0),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: _selectedTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
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

  Widget _buildUnderlineTabItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    required Color inactiveIconColor,
    bool hasBadge = false,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : inactiveIconColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasBadge) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_joinRequests.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
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

  // Thẻ thành viên với viền avatar chuẩn theo ảnh mẫu
  Widget _buildMemberCard(GroupMemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: member.isLeader ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: member.isLeader ? const Color(0xFF0072E8) : const Color(0xFF93C5FD),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: member.isLeader ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              child: Text(
                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'S',
                style: TextStyle(
                  color: member.isLeader ? const Color(0xFF0072E8) : const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0072E8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Trưởng nhóm',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'MSSV: ${member.studentCode.isNotEmpty ? member.studentCode : getStudentCodeForName(member.fullName)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    if (member.phone != null && member.phone!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${member.phone}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_isLeader && !member.isLeader)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              tooltip: tr('btn_remove_member'),
              onPressed: () => _handleRemoveMember(member),
            ),
        ],
      ),
    );
  }

  // Định dạng thời gian gửi yêu cầu hiển thị thân thiện
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

  // Thẻ yêu cầu xin vào nhóm (Duyệt / Từ chối chuẩn phong cách doanh nghiệp)
  Widget _buildJoinRequestCard(GroupRequestModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    req.studentName.isNotEmpty ? req.studentName[0].toUpperCase() : 'S',
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
                      req.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MSSV: ${req.studentCode.isNotEmpty ? req.studentCode : getStudentCodeForName(req.studentName)} • ${req.major}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatRequestTime(req.createdAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          if (req.note != null && req.note!.trim().isNotEmpty && req.note != 'StudentJoinRequest' && req.note != 'LeaderInvite') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_rounded, size: 15, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do: "${req.note}"',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 2 NÚT HÀNH ĐỘNG: TỪ CHỐI & DUYỆT RÕ RÀNG VÀ CHUYÊN NGHIỆP
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessingAction ? null : () => _handleRejectRequest(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFFECACA)),
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
                  onPressed: (_isProcessingAction || (_myGroup?.isFull ?? false))
                      ? null
                      : () => _handleApproveRequest(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_myGroup?.isFull ?? false)
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text(
                    (_myGroup?.isFull ?? false) ? 'NHÓM ĐÃ ĐỦ (3/3)' : 'DUYỆT VÀO NHÓM',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3),
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

// ==========================================
// HỘP THOẠI CĂN GIỮA: TÌM & MỜI BẠN VÀO NHÓM
// ==========================================
class _InviteStudentDialog extends StatefulWidget {
  final String groupId;
  final StudentGroupService groupService;
  final VoidCallback onInvited;

  const _InviteStudentDialog({
    required this.groupId,
    required this.groupService,
    required this.onInvited,
  });

  @override
  State<_InviteStudentDialog> createState() => _InviteStudentDialogState();
}

class _InviteStudentDialogState extends State<_InviteStudentDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<CandidateStudentModel> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
    });
    final list = await widget.groupService.searchCandidateStudents(_searchController.text);
    if (mounted) {
      setState(() {
        _candidates = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleInvite(CandidateStudentModel student) async {
    if (student.hasInvited) {
      await widget.groupService.cancelInvitation(student.id);
    } else {
      try {
        await widget.groupService.inviteStudent(
          groupId: widget.groupId,
          studentCodeOrId: student.studentCode.isNotEmpty ? student.studentCode : student.id,
        );
        widget.onInvited();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 10,
      backgroundColor: Colors.white,
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
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0084FF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('invite_modal_title'),
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Ô Tìm kiếm
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _search(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: tr('invite_search_hint'),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
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
                      ? const Center(
                          child: Text(
                            'Không tìm thấy sinh viên phù hợp.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        Text('${s.studentCode} • ${s.major}',
                                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: s.hasInvited ? const Color(0xFFFFFBEB) : const Color(0xFF0084FF),
                                      foregroundColor: s.hasInvited ? const Color(0xFFD97706) : Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: s.hasInvited ? const Color(0xFFFDE68A) : Colors.transparent,
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
