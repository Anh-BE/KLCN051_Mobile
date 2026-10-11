import 'package:flutter/material.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/weekly_report_service.dart';
import '../model/weekly_report_model.dart';
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

  List<LecturerThesisProgressModel> _allTheses = [];
  List<LecturerThesisProgressModel> _filteredTheses = [];
  String _selectedFilter = 'all'; // 'all', 'pending', 'in_progress', 'completed'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _service.getLecturerTheses(lecturerId: widget.user.userId);
    if (mounted) {
      setState(() {
        _allTheses = data;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final data = await _service.getLecturerTheses(lecturerId: widget.user.userId);
    if (mounted) {
      setState(() {
        _allTheses = data;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    List<LecturerThesisProgressModel> list = List.from(_allTheses);

    // Lọc theo tab
    if (_selectedFilter == 'pending') {
      list = list.where((t) => t.hasPendingReports).toList();
    } else if (_selectedFilter == 'in_progress') {
      list = list.where((t) => !t.isCompleted).toList();
    } else if (_selectedFilter == 'completed') {
      list = list.where((t) => t.isCompleted).toList();
    }

    // Lọc theo tìm kiếm
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final title = t.thesisTitle.toLowerCase();
        final code = t.thesisCode.toLowerCase();
        final group = t.groupName.toLowerCase();
        final leader = t.leaderName.toLowerCase();
        final leaderCode = t.leaderCode.toLowerCase();
        return title.contains(query) ||
            code.contains(query) ||
            group.contains(query) ||
            leader.contains(query) ||
            leaderCode.contains(query);
      }).toList();
    }

    _filteredTheses = list;
  }

  int get _totalPendingReports =>
      _allTheses.fold(0, (sum, t) => sum + t.pendingWeeksCount);

  int get _totalApprovedReports =>
      _allTheses.fold(0, (sum, t) => sum + t.approvedWeeksCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Chuẩn Scaffold App_Mobile.md
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING PILL HEADER CHUẨN DESIGN SYSTEM
            _buildFloatingHeader(),

            // 2. STATS SUMMARY CARDS
            _buildStatsOverview(),

            // 3. SEARCH & FILTER TABS
            _buildSearchAndFilters(),

            const SizedBox(height: 6),

            // 4. DANH SÁCH ĐỀ TÀI & TIẾN ĐỘ BÁO CÁO TUẦN
            Expanded(
              child: _isLoading
                  ? const Center(child: HuitLoading(size: 48, message: 'Đang tải danh sách báo cáo tuần...'))
                  : _filteredTheses.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: const Color(0xFF0F766E),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _filteredTheses.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              return _buildThesisCard(_filteredTheses[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Floating Pill Header
  Widget _buildFloatingHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
              blurRadius: 12,
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
                'TIẾN ĐỘ & BÁO CÁO TUẦN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (_totalPendingReports > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalPendingReports chờ duyệt',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  // 2. Stats Overview Cards
  Widget _buildStatsOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              icon: Icons.menu_book_rounded,
              value: '${_allTheses.length}',
              label: 'Đề tài HD',
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.hourglass_top_rounded,
              value: '$_totalPendingReports',
              label: 'Chờ duyệt',
              color: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFEF3C7),
              isHighlighted: _totalPendingReports > 0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.check_circle_rounded,
              value: '$_totalApprovedReports',
              label: 'Báo cáo đạt',
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFFD1FAE5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Search & Filters
  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Search box
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() => _applyFilters());
              },
              decoration: InputDecoration(
                hintText: 'Tìm đề tài, nhóm, nhóm trưởng...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applyFilters());
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả (${_allTheses.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Chờ duyệt (${_allTheses.where((t) => t.hasPendingReports).length})',
                    badgeColor: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'Đang thực hiện'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Hoàn thành'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? badgeColor}) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = key;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // 4. Thesis Progress Card (ĐẠI DIỆN NỘP CỐ ĐỊNH LÀ NHÓM TRƯỞNG)
  Widget _buildThesisCard(LecturerThesisProgressModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LecturerWeeklyTimelineScreen(
                  thesis: item,
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
                // Top row: Mã đề tài + Badge trạng thái nộp
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.thesisCode.isNotEmpty ? item.thesisCode : 'KLCN',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (item.hasPendingReports)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${item.pendingWeeksCount} báo cáo chờ duyệt',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (item.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Hoàn thành 12 tuần',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Tên đề tài
                Text(
                  item.thesisTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // KHUNG THÔNG TIN NHÓM & ĐẠI DIỆN NỘP (CỐ ĐỊNH NHÓM TRƯỞNG)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Tên nhóm & số thành viên
                      Row(
                        children: [
                          const Icon(Icons.group_rounded, color: Color(0xFF0F766E), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.groupName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.memberCount} SV',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 14, color: Color(0xFFE2E8F0)),
                      // DÒNG CỐ ĐỊNH NHÓM TRƯỞNG LÀ NGƯỜI ĐẠI DIỆN NỘP
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Đại diện nộp: ',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      item.leaderName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCCFBF1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Trưởng nhóm',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.leaderCode.isNotEmpty)
                                  Text(
                                    'MSSV: ${item.leaderCode}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // THANH TIẾN ĐỘ 12 TUẦN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ lộ trình 12 tuần',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '${item.approvedWeeksCount}/${item.totalWeeks} tuần (${item.progressPercentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: item.totalWeeks > 0 ? (item.approvedWeeksCount / item.totalWeeks).clamp(0.0, 1.0) : 0,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                  ),
                ),

                const SizedBox(height: 10),

                // 3 CHIP CHỈ SỐ NHANH
                Row(
                  children: [
                    _buildPillIndicator(
                      label: '${item.approvedWeeksCount} đã duyệt',
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFD1FAE5),
                    ),
                    const SizedBox(width: 6),
                    _buildPillIndicator(
                      label: '${item.pendingWeeksCount} chờ duyệt',
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFEF3C7),
                    ),
                    const SizedBox(width: 6),
                    _buildPillIndicator(
                      label: '${item.totalWeeks - item.submittedWeeksCount} chưa nộp',
                      color: const Color(0xFF64748B),
                      bgColor: const Color(0xFFF1F5F9),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // NÚT ĐIỀU HƯỚNG SANG LỘ TRÌNH 12 TUẦN
                Container(
                  width: double.infinity,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timeline_rounded, color: Colors.white, size: 17),
                      const SizedBox(width: 6),
                      Text(
                        item.hasPendingReports ? 'Duyệt báo cáo tuần ngay' : 'Xem chi tiết 12 tuần',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillIndicator({required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_late_outlined, size: 48, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy báo cáo nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy thử thay đổi từ khóa tìm kiếm hoặc bộ lọc trạng thái phía trên.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
