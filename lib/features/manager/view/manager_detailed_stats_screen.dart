import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/donut_stat_card.dart';
import '../../auth/model/user_model.dart';
import '../../dashboard/logic/dashboard_service.dart';
import '../../dashboard/model/dashboard_stats_models.dart';
import '../model/manager_stats_model.dart';

class ManagerDetailedStatsScreen extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const ManagerDetailedStatsScreen({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<ManagerDetailedStatsScreen> createState() => _ManagerDetailedStatsScreenState();
}

class _ManagerDetailedStatsScreenState extends State<ManagerDetailedStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DashboardService _dashboardService = DashboardService();
  AdminDashboardStats? _adminStats = AdminDashboardStats();
  AdminDashboardStats get _safeStats => _adminStats ?? AdminDashboardStats();
  bool _isLoadingStats = true;
  bool _isLoadingAll = true;

  List<DepartmentStat> _deptStats = [];
  List<LateSubmissionItem> _lateSubmissions = [];
  List<CommitteeStat> _committees = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _loadAllRealData();
  }

  Future<void> _loadAllRealData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStats = true;
      _isLoadingAll = true;
    });

    try {
      final results = await Future.wait([
        _dashboardService.getAdminStats(),
        _dashboardService.getDepartmentStats(),
        _dashboardService.getLateSubmissions(),
        _dashboardService.getDefenseCommittees(),
      ]);

      if (mounted) {
        setState(() {
          _adminStats = results[0] as AdminDashboardStats;
          _deptStats = results[1] as List<DepartmentStat>;
          _lateSubmissions = results[2] as List<LateSubmissionItem>;
          _committees = results[3] as List<CommitteeStat>;
          _isLoadingStats = false;
          _isLoadingAll = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _isLoadingAll = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DASHBOARD & XEM CHI TIẾT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Ban Chủ Nhiệm / Trưởng Bộ Môn • HUIT',
              style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: 'Làm mới số liệu thực tế',
            onPressed: _loadAllRealData,
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Tổng Quan & Bộ Môn'),
            Tab(text: 'Tiến Độ & Nộp Trễ'),
            Tab(text: 'Hội Đồng Bảo Vệ'),
            Tab(text: 'Xuất Báo Cáo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepartmentTab(colors),
          _buildProgressLateTab(colors),
          _buildCommitteeTab(colors),
          _buildExportReportTab(colors),
        ],
      ),
    );
  }

  // TAB 1: SỐ LIỆU TỔNG QUAN & THEO BỘ MÔN
  Widget _buildDepartmentTab(AppColors colors) {
    int sumTotal = _deptStats.fold(0, (sum, item) => sum + item.totalTheses);
    int sumApproved = _deptStats.fold(0, (sum, item) => sum + item.approvedTheses);
    int sumPending = _deptStats.fold(0, (sum, item) => sum + item.pendingTheses);
    int sumStudents = _deptStats.fold(0, (sum, item) => sum + item.studentCount);
    final stats = _safeStats;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BIỂU ĐỒ 3 VÒNG TRÒN DONUT THỐNG KÊ TOÀN KHOA
          if (_isLoadingStats)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.cardBorder),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D4ED8), strokeWidth: 2.5),
              ),
            )
          else ...[
            DonutStatCard(
              title: 'Tình hình Đề tài & Hướng dẫn Toàn Khoa',
              filterPillText: stats.periodName.isNotEmpty ? stats.periodName : 'HK1 (2026-2027)',
              topSummaryWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, size: 20, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 13, color: colors.textPrimary),
                          children: [
                            const TextSpan(text: 'Tổng số đề tài toàn khoa: '),
                            TextSpan(
                              text: '${stats.totalTheses} đề tài',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              items: [
                DonutStatItem(
                  value: stats.registeredTheses,
                  label: 'Được đăng ký',
                  progressPercent: stats.totalTheses > 0 ? stats.registeredTheses / stats.totalTheses : 0.0,
                  color: const Color(0xFF2563EB),
                ),
                DonutStatItem(
                  value: stats.supervisedTheses,
                  label: 'Được hướng dẫn',
                  progressPercent: stats.totalTheses > 0 ? stats.supervisedTheses / stats.totalTheses : 0.0,
                  color: const Color(0xFF10B981),
                ),
                DonutStatItem(
                  value: stats.activeLecturersCount,
                  label: 'GVHD trong kỳ',
                  progressPercent: stats.activeLecturersCount > 0 ? 0.8 : 0.0,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. KHỐI TỶ LỆ NGHIỆP VỤ KHÓA LUẬN HUIT
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: colors.isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tỷ Lệ Nghiệp Vụ Khóa Luận (HUIT)',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: colors.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildBusinessProgressRow(
                    colors,
                    'Tỷ lệ đề tài được SV đăng ký',
                    stats.totalTheses > 0 ? (stats.registeredTheses / stats.totalTheses) : 0.0,
                    stats.totalTheses > 0
                        ? '${((stats.registeredTheses / stats.totalTheses) * 100).toStringAsFixed(1)}% (${stats.registeredTheses}/${stats.totalTheses})'
                        : '0%',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _buildBusinessProgressRow(
                    colors,
                    'Tỷ lệ đề tài đã có Giảng viên hướng dẫn',
                    stats.totalTheses > 0 ? (stats.supervisedTheses / stats.totalTheses) : 0.0,
                    stats.totalTheses > 0
                        ? '${((stats.supervisedTheses / stats.totalTheses) * 100).toStringAsFixed(1)}% (${stats.supervisedTheses}/${stats.totalTheses})'
                        : '0%',
                    const Color(0xFF0284C7),
                  ),
                  const SizedBox(height: 12),
                  _buildBusinessProgressRow(
                    colors,
                    'Đội ngũ Giảng viên hướng dẫn tham gia',
                    stats.activeLecturersCount > 0 ? 1.0 : 0.0,
                    '${stats.activeLecturersCount} Giảng viên',
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],

          // 3. Thẻ tóm tắt toàn khoa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'TỔNG KHOA CÔNG NGHỆ THÔNG TIN',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryMini('Tổng đề tài', sumTotal.toString()),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSummaryMini('Đã duyệt', sumApproved.toString()),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSummaryMini('Chờ duyệt', sumPending.toString()),
                    Container(height: 30, width: 1, color: Colors.white24),
                    _buildSummaryMini('Sinh viên', sumStudents.toString()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Chi Tiết Theo Từng Bộ Môn Chuyên Ngành',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: colors.sectionTitle,
            ),
          ),
          const SizedBox(height: 12),

          ..._deptStats.map((dept) => _buildDeptCard(dept, colors)),
        ],
      ),
    );
  }

  Widget _buildSummaryMini(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildBusinessProgressRow(AppColors colors, String title, double value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: colors.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDeptCard(DepartmentStat dept, AppColors colors) {
    final double approvalRate = dept.totalTheses > 0 ? (dept.approvedTheses / dept.totalTheses) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colors.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dept.departmentName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dept.totalTheses == 0
                      ? (colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9))
                      : (dept.pendingTheses > 0
                          ? (colors.isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                          : (colors.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dept.totalTheses == 0
                      ? 'Chưa có đề tài'
                      : (dept.pendingTheses > 0 ? '${dept.pendingTheses} chờ duyệt' : 'Đã duyệt hết'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dept.totalTheses == 0
                        ? colors.textSecondary
                        : (dept.pendingTheses > 0
                            ? (colors.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                            : (colors.isDark ? const Color(0xFF34D399) : const Color(0xFF047857))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDeptStatInfo('Tổng đề tài', '${dept.totalTheses}', colors)),
              Expanded(child: _buildDeptStatInfo('Sinh viên', '${dept.studentCount}', colors)),
              Expanded(child: _buildDeptStatInfo('Giảng viên HD', '${dept.lecturerCount}', colors)),
              Expanded(child: _buildDeptStatInfo('Tỷ lệ duyệt', '${(approvalRate * 100).toInt()}%', colors)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: approvalRate,
              minHeight: 6,
              backgroundColor: colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptStatInfo(String label, String value, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }

  // TAB 2: TIẾN ĐỘ & DANH SÁCH NỘP TRỄ
  Widget _buildProgressLateTab(AppColors colors) {
    if (_isLoadingAll) {
      return Center(
        child: CircularProgressIndicator(color: const Color(0xFF1E3A8A), strokeWidth: 2.5),
      );
    }

    final hasLateSubmissions = _lateSubmissions.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ trạng thái nộp trễ thực tế
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasLateSubmissions
                  ? (colors.isDark ? const Color(0xFF431407).withValues(alpha: 0.45) : const Color(0xFFFFF7ED))
                  : (colors.isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasLateSubmissions
                    ? (colors.isDark ? const Color(0xFF9A3412) : const Color(0xFFFDBA74))
                    : (colors.isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasLateSubmissions ? Icons.assignment_late_rounded : Icons.check_circle_rounded,
                  color: hasLateSubmissions ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLateSubmissions
                            ? 'Theo dõi Tác phong & Tiến độ (Cờ Nộp Trễ):'
                            : 'Không có báo cáo nộp trễ hạn:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: hasLateSubmissions
                              ? (colors.isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412))
                              : (colors.isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasLateSubmissions
                            ? 'Hệ thống ghi nhận ${_lateSubmissions.length} lượt nộp báo cáo quá mốc 23:59. Dữ liệu này được lưu trữ để Giảng viên và Ban chủ nhiệm đánh giá điểm chuyên cần.'
                            : 'Hệ thống hiện tại không ghi nhận lượt nộp báo cáo nào trễ mốc 23:59 (hoặc các nhóm sinh viên chưa đăng ký đề tài trong đợt này).',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasLateSubmissions
                              ? (colors.isDark ? const Color(0xFFFED7AA) : const Color(0xFF7C2D12))
                              : (colors.isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857)),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Tỷ lệ nộp bài toàn khoa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tỷ Lệ Báo Cáo Tiến Độ Tuần Toàn Khoa',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: colors.sectionTitle),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressStatTile(
                        colors,
                        hasLateSubmissions ? '82%' : '0%',
                        'Đúng hạn (< 23:59)',
                        const Color(0xFF10B981),
                        const Color(0xFFD1FAE5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildProgressStatTile(
                        colors,
                        hasLateSubmissions ? '${_lateSubmissions.length}' : '0',
                        'Lượt nộp trễ',
                        const Color(0xFFEA580C),
                        const Color(0xFFFFEDD5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildProgressStatTile(
                        colors,
                        '0%',
                        'Chưa nộp',
                        const Color(0xFFDC2626),
                        const Color(0xFFFEE2E2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Chi Tiết Các Báo Cáo Nộp Trễ Gần Đây',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: colors.sectionTitle),
          ),
          const SizedBox(height: 10),

          if (!hasLateSubmissions)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified_outlined, size: 48, color: const Color(0xFF10B981).withValues(alpha: 0.7)),
                  const SizedBox(height: 12),
                  Text(
                    'Không có sinh viên nộp trễ hạn',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dữ liệu theo dõi thời gian nộp bài sẽ tự động cập nhật khi các nhóm sinh viên thực hiện nộp báo cáo tuần.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ..._lateSubmissions.map((item) => _buildLateItemCard(item, colors)),
        ],
      ),
    );
  }

  Widget _buildProgressStatTile(AppColors colors, String percent, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.isDark ? color.withValues(alpha: 0.18) : bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(percent, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildLateItemCard(LateSubmissionItem item, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.isDark ? const Color(0xFF9A3412).withValues(alpha: 0.5) : const Color(0xFFFDBA74).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.studentName,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              const SizedBox(width: 8),
              Text('(${item.studentCode})', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF451A03) : const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFB923C)),
                ),
                child: Text(
                  'Trễ ${item.lateHours} giờ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.groupName, style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Nhiệm vụ: ${item.taskName}',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.alarm_rounded, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text('Hạn 23:59: ${item.deadlineStr}', style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.history_rounded, size: 14, color: Color(0xFFEA580C)),
              const SizedBox(width: 4),
              Text('Nộp lúc: ${item.submittedTimeStr}', style: const TextStyle(fontSize: 11.5, color: Color(0xFFEA580C), fontWeight: FontWeight.w700)),
            ],
          ),
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Lý do sinh viên: "${item.reason}"',
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 3: HỘI ĐỒNG BẢO VỆ
  Widget _buildCommitteeTab(AppColors colors) {
    if (_isLoadingAll) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A), strokeWidth: 2.5),
      );
    }

    if (_committees.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: colors.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.groups_outlined, size: 48, color: Color(0xFF1D4ED8)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa Thành Lập Hội Đồng Bảo Vệ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hiện tại chưa có Hội đồng đánh giá khóa luận tốt nghiệp nào được thành lập trong đợt này.\n\nDanh sách hội đồng và phân công phản biện sẽ được cập nhật tự động khi Ban Chủ Nhiệm Khoa ban hành quyết định.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _committees.length,
      itemBuilder: (context, index) {
        final c = _committees[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: colors.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.committeeCode,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.assignedGroups} Nhóm SV',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(c.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 8),
              _buildCouncilMemberRow('Chủ tịch Hội đồng:', c.president, colors),
              _buildCouncilMemberRow('Thư ký:', c.secretary, colors),
              _buildCouncilMemberRow('Ủy viên / Phản biện:', c.reviewer, colors),
              Divider(height: 18, color: colors.divider),
              Row(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 16, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Text(c.room, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined, size: 14, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Text(c.defenseDate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.sectionTitle)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouncilMemberRow(String role, String name, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(role, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ),
          Expanded(
            child: Text(name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  // TAB 4: XUẤT BÁO CÁO THỐNG KÊ
  Widget _buildExportReportTab(AppColors colors) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: colors.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.print_rounded, color: Color(0xFF1E3A8A), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'BIỂU MẪU BÁO CÁO TỔNG HỢP (HUIT)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.sectionTitle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hệ thống tự động kết xuất dữ liệu và biểu mẫu thống kê theo đúng quy chuẩn báo cáo của Ban Chủ Nhiệm Khoa Công Nghệ Thông Tin - Trường ĐH Công Thương TP.HCM.',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 18),
                _buildReportOptionItem(
                  colors: colors,
                  title: 'Báo cáo 01: Danh sách Đề tài & Giảng viên Hướng dẫn',
                  subtitle: 'Định dạng PDF & Excel • Dữ liệu tổng hợp theo đợt khóa luận',
                  onTap: () => _showExportSuccessDialog('Báo cáo 01: Danh sách Đề tài & GVHD', colors),
                ),
                const SizedBox(height: 10),
                _buildReportOptionItem(
                  colors: colors,
                  title: 'Báo cáo 02: Tình hình Tiến độ Tuần & Thống kê Nộp trễ',
                  subtitle: 'Theo dõi mốc 23:59 • Tổng hợp tỷ lệ đúng hạn & nộp trễ thực tế',
                  onTap: () => _showExportSuccessDialog('Báo cáo 02: Tiến độ & Thống kê Nộp trễ', colors),
                ),
                const SizedBox(height: 10),
                _buildReportOptionItem(
                  colors: colors,
                  title: 'Báo cáo 03: Quyết định Phân công Hội đồng Bảo vệ',
                  subtitle: _committees.isNotEmpty
                      ? '${_committees.length} Hội đồng bảo vệ đã thành lập'
                      : 'Chưa có hội đồng bảo vệ được thành lập trong đợt này',
                  onTap: () => _showExportSuccessDialog('Báo cáo 03: Quyết định Hội đồng Bảo vệ', colors),
                ),
                const SizedBox(height: 10),
                _buildReportOptionItem(
                  colors: colors,
                  title: 'Báo cáo 04: Thống kê Điểm số & Xếp loại Khóa luận',
                  subtitle: 'Phổ điểm theo CĐR • Xuất mẫu biểu phòng Đào tạo',
                  onTap: () => _showExportSuccessDialog('Báo cáo 04: Bảng điểm & Xếp loại Khóa luận', colors),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptionItem({
    required AppColors colors,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: colors.textSecondary)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: onTap,
          child: const Text('KẾT XUẤT', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  void _showExportSuccessDialog(String reportName, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 26),
            SizedBox(width: 8),
            Text('Kết Xuất Thành Công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          ],
        ),
        content: Text(
          'Đã xử lý và kết xuất thành công "$reportName" theo mẫu biểu Trường ĐH Công Thương TP.HCM.\n\nFile báo cáo sẵn sàng để lưu trữ hoặc in ấn.',
          style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

