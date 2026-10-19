import 'package:flutter/material.dart';
import '../../../../core/localization/app_language_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/student_group_service.dart';
import '../model/student_group_model.dart';
import 'widgets/group_members_detail_sheet.dart';
import 'widgets/join_group_dialog.dart';
import 'widgets/student_group_card.dart';

class StudentGroupListScreen extends StatefulWidget {
  final UserModel user;

  const StudentGroupListScreen({super.key, required this.user});

  @override
  State<StudentGroupListScreen> createState() => _StudentGroupListScreenState();
}

class _StudentGroupListScreenState extends State<StudentGroupListScreen> {
  final StudentGroupService _groupService = StudentGroupService();
  final TextEditingController _searchController = TextEditingController();

  AppColors get _colors => AppColors.of(context);

  String _selectedTab = 'all'; // 'all', 'recruiting', 'full'
  List<StudentGroupModel> _groups = [];
  bool _isLoading = true;
  StudentGroupModel? _myGroup;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _groupService.getGroups(
      query: _searchController.text,
      statusFilter: _selectedTab,
    );

    StudentGroupModel? myGroup;
    try {
      myGroup = await _groupService.getMyGroup(widget.user);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _groups = data;
        _myGroup = myGroup;
        _isLoading = false;
      });
    }
  }

  bool _isMyGroupLeader(StudentGroupModel group) {
    return group.isUserLeader(widget.user);
  }

  bool _isMyGroupMember(StudentGroupModel group) {
    return group.isUserMember(widget.user);
  }

  Future<void> _handleJoinRequest(StudentGroupModel group) async {
    if (_isMyGroupLeader(group)) {
      _showSnackBar(
        'Nhóm do bạn làm Nhóm trưởng tạo ra, không thể tự gửi yêu cầu xin vào nhóm của chính mình!',
        isError: true,
      );
      return;
    }

    if (_isMyGroupMember(group)) {
      _showSnackBar('Bạn đã là thành viên trong nhóm này rồi!', isError: true);
      return;
    }

    if (_myGroup != null && _myGroup!.id != group.id) {
      _showSnackBar(
        'Bạn đã tham gia nhóm "${_myGroup!.name}". Theo quy định, mỗi sinh viên chỉ được tham gia 1 nhóm khóa luận!',
        isError: true,
      );
      return;
    }

    if (group.hasRequested) {
      // Xác nhận hủy yêu cầu
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: _colors.cardBg,
          title: Text('Hủy yêu cầu tham gia', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: _colors.textPrimary)),
          content: Text('Bạn có chắc muốn hủy yêu cầu tham gia ${group.name}?', style: TextStyle(color: _colors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'), style: TextStyle(color: _colors.textSecondary)),
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
        await _groupService.cancelJoinRequest(group.id);
        if (!mounted) return;
        _showSnackBar(tr('join_request_cancelled'), isError: false);
        _fetchGroups();
      }
      return;
    }

    // Modal dialog nhập lời nhắn xin vào nhóm
    final note = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => JoinGroupDialog(group: group),
    );

    if (note != null) {
      try {
        final success = await _groupService.requestJoinGroup(group.id, note: note);
        if (!mounted) return;
        if (success) {
          _showSnackBar(tr('join_request_success'), isError: false);
          _fetchGroups();
        } else {
          _showSnackBar('Gửi yêu cầu không thành công. Vui lòng thử lại!', isError: true);
        }
      } catch (e) {
        if (!mounted) return;
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _showGroupDetails(StudentGroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GroupMembersDetailSheet(
        group: group,
        isLeader: _isMyGroupLeader(group),
        isMember: _isMyGroupMember(group),
        otherGroupName: (_myGroup != null && _myGroup!.id != group.id) ? _myGroup!.name : null,
        onActionPressed: () => _handleJoinRequest(group),
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
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. TOP APP BAR
                _buildHeader(),

                // 2. SEARCH BAR & FILTER ROW
                _buildSearchAndFilter(),

                // 3. GROUP CARDS LIST
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: HuitLoading(size: 74),
                        )
                      : _groups.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchGroups,
                              color: const Color(0xFF0084FF),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _groups.length,
                                itemBuilder: (context, index) {
                                  final group = _groups[index];
                                  return StudentGroupCard(
                                    group: group,
                                    isLeader: _isMyGroupLeader(group),
                                    isMember: _isMyGroupMember(group),
                                    otherGroupName: (_myGroup != null && _myGroup!.id != group.id) ? _myGroup!.name : null,
                                    onTapDetail: () => _showGroupDetails(group),
                                    onAction: () => _handleJoinRequest(group),
                                    onHasOtherGroupTap: (otherName) {
                                      _showSnackBar(
                                        'Bạn đã tham gia nhóm "$otherName". Theo quy định, sinh viên chỉ được tham gia 1 nhóm khóa luận.',
                                        isError: true,
                                      );
                                    },
                                  );
                                },
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

  Widget _buildHeader() {
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
                tr('group_list_title'),
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

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          // Ô Tìm kiếm
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _colors.searchBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _colors.searchBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetchGroups(),
                style: TextStyle(fontSize: 13, color: _colors.textPrimary),
                decoration: InputDecoration(
                  hintText: tr('group_search_hint'),
                  hintStyle: TextStyle(fontSize: 12.5, color: _colors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0084FF)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: _colors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _fetchGroups();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nút Lọc theo Trạng thái (Dropdown: Tất cả, Đang tuyển, Đã đủ)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _colors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Lọc trạng thái',
              offset: const Offset(0, 48),
              color: _colors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (status) {
                setState(() {
                  _selectedTab = status;
                });
                _fetchGroups();
              },
              itemBuilder: (context) => [
                _buildStatusMenuItem('all', tr('status_all')),
                _buildStatusMenuItem('recruiting', tr('status_recruiting_filter')),
                _buildStatusMenuItem('full', tr('status_full_filter')),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list_rounded, size: 20, color: Color(0xFF0084FF)),
                  const SizedBox(width: 4),
                  Text(
                    _selectedTab == 'all'
                        ? tr('tab_all')
                        : _selectedTab == 'recruiting'
                            ? tr('status_recruiting_filter')
                            : tr('status_full_filter'),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _colors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _colors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem(String value, String label) {
    final isCurrent = _selectedTab == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 16,
            color: isCurrent ? const Color(0xFF0084FF) : _colors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? const Color(0xFF0084FF) : _colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _colors.cardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_outlined, size: 48, color: _colors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            tr('no_groups_found'),
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
