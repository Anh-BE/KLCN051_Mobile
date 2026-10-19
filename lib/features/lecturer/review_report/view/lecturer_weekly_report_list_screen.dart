import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../../topic/model/lecturer_thesis_model.dart';
import '../logic/weekly_report_service.dart';
import 'lecturer_weekly_timeline_screen.dart';

class LecturerWeeklyReportListScreen extends StatefulWidget {
  final UserModel user;

  const LecturerWeeklyReportListScreen({super.key, required this.user});

  @override
  State<LecturerWeeklyReportListScreen> createState() => _LecturerWeeklyReportListScreenState();
}

class _LecturerWeeklyReportListScreenState extends State<LecturerWeeklyReportListScreen> {
  final WeeklyReportService _service = WeeklyReportService();
  final TextEditingController _searchController = TextEditingController();

  List<LecturerThesisModel> _allApprovedTheses = [];
  List<LecturerThesisModel> _filteredTheses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Khởi tạo dữ liệu từ CSDL thật: Tải dữ liệu toàn bộ đề tài có nhóm thực hiện
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final data = await _service.getApprovedTheses(
      periodId: null,
      groupFilter: 'has_group',
      searchQuery: null,
    );

    if (mounted) {
      setState(() {
        _allApprovedTheses = data;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final data = await _service.getApprovedTheses(
      periodId: null,
      groupFilter: 'has_group',
      searchQuery: null,
    );
    if (mounted) {
      setState(() {
        _allApprovedTheses = data;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    // Chỉ lấy các đề tài đã có nhóm làm tiến độ tuần
    List<LecturerThesisModel> list = _allApprovedTheses.where((t) => t.hasGroup).toList();

    // Lọc theo tìm kiếm
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final title = t.thesisTitle.toLowerCase();
        final code = t.periodCode.toLowerCase();
        final hasMatchGroup = t.registeredGroups.any((g) =>
            g.groupName.toLowerCase().contains(query) ||
            g.members.any((m) =>
                m.fullName.toLowerCase().contains(query) ||
                m.studentCode.toLowerCase().contains(query)));
        return title.contains(query) || code.contains(query) || hasMatchGroup;
      }).toList();
    }

    _filteredTheses = list;
  }


  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền chung (Ảnh nền ban ngày / Gradient tối cho Dark Mode đồng bộ Trang chủ)
          Positioned.fill(
            child: colors.isDark
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: colors.pageGradient,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/bg_main.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: colors.pageGradient,
                        ),
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. FLOATING PILL HEADER
                _buildFloatingHeader(),

                // 2. THANH TÌM KIẾM
                _buildSearchBar(colors),

                const SizedBox(height: 4),

                // 3. DANH SÁCH ĐỀ TÀI ĐÃ CÓ NHÓM & TIẾN ĐỘ TUẦN
                Expanded(
                  child: _isLoading
                      ? const Center(child: HuitLoading(size: 48, message: 'Đang tải danh sách báo cáo tuần...'))
                      : _filteredTheses.isEmpty
                          ? _buildEmptyState(colors)
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              color: const Color(0xFF0072E8),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _filteredTheses.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  return _buildThesisCard(_filteredTheses[index], colors);
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

  // 1. Floating Pill Header (Bỏ nút reload xoay tròn, căn giữa tiêu đề)
  Widget _buildFloatingHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
              color: const Color(0xFF007AFF).withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Quay lại',
            ),
            const Expanded(
              child: Text(
                'TIẾN ĐỘ TUẦN - QUẢN LÝ ĐỀ TÀI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            // Cân đối khoảng trống với nút back bên trái để tiêu đề nằm chính giữa
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // 2. Ô tìm kiếm toàn diện 100% bề ngang
  Widget _buildSearchBar(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: colors.searchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.subCardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() => _applyFilters()),
          style: TextStyle(fontSize: 13, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tìm theo tên đề tài, nhóm, MSSV...',
            hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0072E8), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, size: 18, color: colors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _applyFilters());
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  // 4. Thẻ Đề tài đã duyệt & Hiển thị đầy đủ sinh viên trong nhóm (Chuẩn Mobile & HUIT)
  Widget _buildThesisCard(LecturerThesisModel thesis, AppColors colors) {
    final hasGroup = thesis.hasGroup;
    final group = hasGroup ? thesis.registeredGroups.first : null;
    final members = group?.members ?? [];

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF007AFF).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LecturerWeeklyTimelineScreen(
                  thesis: thesis.toProgressModel(),
                  user: widget.user,
                ),
              ),
            ).then((_) => _refresh());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card: Mã đề tài bên trái + Tên đợt rút gọn bên phải
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Text(
                        thesis.periodCode.isNotEmpty ? thesis.periodCode : 'DT${thesis.thesisId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        thesis.periodName.replaceAll('Khóa luận tốt nghiệp ', 'KLTN '),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tên đề tài
                Text(
                  thesis.thesisTitle,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 14),

                // Khung thông tin nhóm & HIỂN THỊ ĐẦY ĐỦ TẤT CẢ SINH VIÊN
                if (hasGroup && group != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF0F1E36) : const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dòng tiêu đề nhóm
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.group_rounded, color: Color(0xFF0072E8), size: 17),
                                const SizedBox(width: 7),
                                Text(
                                  group.groupName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: colors.isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${group.memberCount} sinh viên',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (members.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            thickness: 0.8,
                            color: colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE).withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),

                          // Hiển thị từng sinh viên trong nhóm
                          ...members.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final m = entry.value;
                            final bool isLeader = m.role.toLowerCase() == 'leader' || idx == 0;

                            return Padding(
                              padding: EdgeInsets.only(bottom: idx == members.length - 1 ? 0 : 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isLeader
                                          ? (colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                                          : (colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isLeader ? Icons.stars_rounded : Icons.person_rounded,
                                      size: 14,
                                      color: isLeader
                                          ? const Color(0xFF0072E8)
                                          : colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${m.fullName} • ${m.studentCode}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isLeader ? FontWeight.w800 : FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isLeader
                                          ? (colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
                                          : (colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isLeader ? 'Trưởng nhóm' : 'Thành viên',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isLeader ? FontWeight.w800 : FontWeight.w600,
                                        color: isLeader
                                            ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Nút bấm chuẩn HUIT (Touch Target 42px)
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LecturerWeeklyTimelineScreen(
                              thesis: thesis.toProgressModel(),
                              user: widget.user,
                            ),
                          ),
                        ).then((_) => _refresh());
                      },
                      icon: const Icon(Icons.view_timeline_rounded, size: 18),
                      label: const Text(
                        'Xem tiến độ & Đánh giá tuần',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0072E8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.assignment_late_outlined, color: Color(0xFF94A3B8), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đề tài nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Không tìm thấy đề tài hoặc sinh viên nào khớp với từ khóa tìm kiếm.'
                  : 'Hiện chưa có đề tài nào có nhóm sinh viên đăng ký để theo dõi tiến độ tuần.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
