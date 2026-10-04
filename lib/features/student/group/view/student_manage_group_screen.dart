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
  int _selectedTab = 0; // 0: Thành viên, 1: Yêu cầu xin vào

  // Controllers cho Form Tạo nhóm
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedMajor = 'Công nghệ phần mềm';
  bool _isSubmitting = false;

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

    final group = await _groupService.getMyGroup(widget.user);
    List<GroupRequestModel> requests = [];
    if (group != null) {
      requests = await _groupService.getJoinRequests(group.id);
    }

    if (mounted) {
      setState(() {
        _myGroup = group;
        _joinRequests = requests;
        _isLoading = false;
      });
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
  }

  // Duyệt yêu cầu
  Future<void> _handleApproveRequest(GroupRequestModel request) async {
    if (_myGroup == null) return;
    final success = await _groupService.approveJoinRequest(_myGroup!.id, request);
    if (success) {
      _showSnackBar(tr('approve_request_success'), isError: false);
      _loadGroupData();
    } else {
      _showSnackBar('Nhóm đã đủ số lượng thành viên tối đa (3/3)!', isError: true);
    }
  }

  // Từ chối yêu cầu
  Future<void> _handleRejectRequest(GroupRequestModel request) async {
    if (_myGroup == null) return;
    final success = await _groupService.rejectJoinRequest(_myGroup!.id, request.id);
    if (success) {
      _showSnackBar(tr('reject_request_success'), isError: false);
      _loadGroupData();
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _InviteStudentDialog(
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
      child: Container(
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
    );
  }

  // ==========================================
  // GIAO DIỆN 2: BẢNG QUẢN LÝ NHÓM (DÀNH CHO TRƯỞNG NHÓM)
  // ==========================================
  Widget _buildGroupManagementView() {
    final group = _myGroup!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. THẺ TÓM TẮT NHÓM CỦA TÔI
          Container(
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
                      child: const Icon(Icons.groups_rounded, color: Color(0xFF0084FF), size: 22),
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
          ),

          const SizedBox(height: 16),

          // 2. SEGMENTED TABS (THÀNH VIÊN & YÊU CẦU XIN VÀO)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    label: '${tr('tab_my_members')} (${group.currentMembers}/${group.maxMembers})',
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    label: '${tr('tab_join_requests')} (${_joinRequests.length})',
                    hasBadge: _joinRequests.isNotEmpty,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. NỘI DUNG TƯƠNG ỨNG VỚI TAB
          if (_selectedTab == 0) ...[
            // Nút Mời thành viên mới
            if (!group.isFull) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0084FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                  label: Text(
                    tr('btn_invite_member'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                  ),
                  onPressed: _showInviteStudentDialog,
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Danh sách thành viên hiện có
            ...group.members.map((m) => _buildMemberCard(m)),
          ] else ...[
            // Danh sách yêu cầu xin vào nhóm
            if (_joinRequests.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 44, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 10),
                    Text(
                      tr('no_pending_requests'),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              ..._joinRequests.map((req) => _buildJoinRequestCard(req)),
          ],
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

  Widget _buildTabButton({required int index, required String label, bool hasBadge = false}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0084FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0084FF).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // Thẻ thành viên
  Widget _buildMemberCard(GroupMemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: member.isLeader ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: member.isLeader ? const Color(0xFF0084FF) : const Color(0xFF94A3B8),
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0] : 'S',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0084FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Trưởng nhóm',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('MSSV: ${member.studentCode} ${member.phone != null ? "• ${member.phone}" : ""}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (!member.isLeader)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              tooltip: tr('btn_remove_member'),
              onPressed: () => _handleRemoveMember(member),
            ),
        ],
      ),
    );
  }

  // Thẻ yêu cầu xin vào nhóm (Duyệt / Từ chối chuẩn theo ảnh thiết kế)
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
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0284C7),
                child: Text(
                  req.studentName.isNotEmpty ? req.studentName[0] : 'S',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Text('MSSV: ${req.studentCode} • ${req.major}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Text(
                req.createdAt,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),

          if (req.note != null && req.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '💬 "${req.note}"',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 2 NÚT HÀNH ĐỘNG: TỪ CHỐI & DUYỆT CHUẨN THEO ẢNH MẪU
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _handleRejectRequest(req),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          tr('btn_reject'),
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _handleApproveRequest(req),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          tr('btn_approve'),
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
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

// ==========================================
// HỘP THOẠI CĂN GIỮA: TÌM & MỜI BẠN VÀO NHÓM
// ==========================================
class _InviteStudentDialog extends StatefulWidget {
  final StudentGroupService groupService;
  final VoidCallback onInvited;

  const _InviteStudentDialog({
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
      await widget.groupService.inviteStudent(student.id);
      widget.onInvited();
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
