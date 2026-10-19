import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/weekly_report_service.dart';
import '../model/weekly_report_model.dart';
import 'lecturer_report_detail_screen.dart';

class LecturerWeeklyTimelineScreen extends StatefulWidget {
  final LecturerThesisProgressModel thesis;
  final UserModel user;

  const LecturerWeeklyTimelineScreen({
    super.key,
    required this.thesis,
    required this.user,
  });

  @override
  State<LecturerWeeklyTimelineScreen> createState() => _LecturerWeeklyTimelineScreenState();
}

class _LecturerWeeklyTimelineScreenState extends State<LecturerWeeklyTimelineScreen>
    with SingleTickerProviderStateMixin {
  final WeeklyReportService _service = WeeklyReportService();

  late TabController _tabController;
  List<WeeklyTimelineItemModel> _allWeeks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTimeline();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);
    final data = await _service.getThesisTimeline(
      widget.thesis.thesisId,
      defaultLeaderName: widget.thesis.leaderName,
      defaultLeaderCode: widget.thesis.leaderCode,
    );
    if (mounted) {
      setState(() {
        _allWeeks = data;
        _isLoading = false;
      });
    }
  }

  int get _approvedCount => _allWeeks.where((w) => w.isApproved).length;

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

                // 2. THẺ TÓM TẮT ĐỀ TÀI & SINH VIÊN ĐẠI DIỆN NỘP (CỐ ĐỊNH NHÓM TRƯỞNG)
                _buildThesisSummaryCard(colors),

                // 3. THANH ĐIỀU HƯỚNG 2 TAB: SETUP THỜI GIAN & ĐÁNH GIÁ TUẦN
                _buildSegmentedTabBar(colors),

                // 4. NỘI DUNG 2 TAB
                Expanded(
                  child: _isLoading
                      ? const Center(child: HuitLoading(size: 46, message: 'Đang tải lộ trình 12 tuần...'))
                      : _allWeeks.isEmpty
                          ? _buildEmptyState(colors)
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                // TAB 1: SETUP THỜI GIAN CHO TIẾN ĐỘ TUẦN
                                _buildSetupDeadlineTab(colors),

                                // TAB 2: ĐÁNH GIÁ TUẦN (LỊCH TUẦN & XEM BÀI SV NỘP)
                                _buildEvaluationTab(colors),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Floating Pill Header
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
                'LỘ TRÌNH TIẾN ĐỘ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.thesis.thesisCode.isNotEmpty ? widget.thesis.thesisCode : 'KLCN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Thẻ tóm tắt đề tài & CỐ ĐỊNH NHÓM TRƯỞNG LÀ NGƯỜI ĐẠI DIỆN NỘP
  Widget _buildThesisSummaryCard(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên đề tài
            Text(
              widget.thesis.thesisTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            // BOX NHÓM TRƯỞNG CỐ ĐỊNH ĐẠI DIỆN NỘP BÁO CÁO (Chuẩn HUIT Xanh dương & Trắng)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF0F1E36) : const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFF0072E8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Đại diện nộp:',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.isDark ? const Color(0xFF93C5FD) : const Color(0xFF0055A5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CỐ ĐỊNH',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.thesis.leaderName} • MSSV: ${widget.thesis.leaderCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0072E8), Color(0xFF0091FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_approvedCount/12 đạt',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Thanh điều hướng Segmented Tab Bar (Setup thời gian & Đánh giá tuần)
  Widget _buildSegmentedTabBar(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: colors.segmentBg,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0072E8), Color(0xFF0091FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0072E8).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune_rounded, size: 17),
                  SizedBox(width: 6),
                  Text('Setup thời gian'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fact_check_rounded, size: 17),
                  SizedBox(width: 6),
                  Text('Đánh giá tuần'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: SETUP THỜI GIAN CHO TIẾN ĐỘ TUẦN
  Widget _buildSetupDeadlineTab(AppColors colors) {
    final bool hasAnyDeadline = _allWeeks.any((w) => w.deadline.year > 2000);

    return RefreshIndicator(
      onRefresh: _loadTimeline,
      color: const Color(0xFF0072E8),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
        children: [
          // 1. Banner cấu hình tự động 12 tuần (Chuẩn Mobile gọn gàng, súc tích)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0072E8), Color(0xFF0056B3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0072E8).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cài hạn tự động',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAnyDeadline
                      ? 'Tự động tính lại hạn các tuần theo mốc Tuần 1 mới.'
                      : 'Tự động tạo hạn nộp 12 tuần theo mốc Tuần 1.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _allWeeks.isEmpty ? null : () => _showBatchDeadlineModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0072E8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasAnyDeadline ? 'Cập nhật lại lịch trình' : 'Cài đặt lịch trình 12 tuần',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Tiêu đề danh sách chi tiết từng tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiết hạn chót từng tuần',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_allWeeks.length} tuần',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.chipText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. Danh sách 12 tuần kèm nút đổi hạn riêng từng tuần
          ..._allWeeks.map((item) => _buildWeekDeadlineRow(item, colors)),
        ],
      ),
    );
  }

  // Card hiển thị hạn chót và nút đổi hạn của từng tuần (Chuẩn Mobile UI/UX)
  Widget _buildWeekDeadlineRow(WeeklyTimelineItemModel item, AppColors colors) {
    final hasDeadline = item.deadline.year > 2000;
    // Bỏ lặp tiền tố 'Tuần X:' nếu tiêu đề đã có sẵn
    final rawClean = item.title.replaceFirst(RegExp(r'^Tuần\s*\d+\s*[:\-]\s*', caseSensitive: false), '').trim();
    final cleanTitle = rawClean.isNotEmpty ? rawClean : item.title;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasDeadline ? colors.cardBorder : (colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF007AFF).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Chip Tuần bên trái + Tag trạng thái hạn bên phải (Chuẩn HUIT Xanh & Trắng)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  'Tuần ${item.weekNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasDeadline
                      ? (colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                      : (colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasDeadline
                        ? (colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE))
                        : (colors.isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasDeadline ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                      size: 13,
                      color: hasDeadline
                          ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasDeadline ? 'Đã thiết lập hạn' : 'Chưa có hạn nộp',
                      style: TextStyle(
                        color: hasDeadline
                            ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                            : colors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Nội dung công việc tuần (Hiển thị đầy đủ, không bị cắt chữ)
          Text(
            cleanTitle.isNotEmpty ? cleanTitle : 'Nhiệm vụ báo cáo Tuần ${item.weekNumber}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.35,
            ),
          ),

          if (item.detailedRequirements.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.detailedRequirements,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(height: 1, thickness: 0.8, color: colors.divider),
          const SizedBox(height: 12),

          // 3. Footer: Thông tin hạn nộp bên trái & Nút Đổi hạn 40px bên phải
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HẠN NỘP BÁO CÁO',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: hasDeadline
                              ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            hasDeadline
                                ? '${_formatDate(item.deadline)} (23:59:59)'
                                : 'Chưa thiết lập',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: hasDeadline
                                  ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                                  : const Color(0xFFD97706),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showSingleWeekDeadlinePicker(item),
                icon: Icon(
                  hasDeadline ? Icons.edit_calendar_rounded : Icons.add_circle_outline_rounded,
                  size: 16,
                ),
                label: Text(hasDeadline ? 'Đổi hạn' : 'Cài hạn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasDeadline
                      ? (colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                      : (colors.isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0072E8)),
                  foregroundColor: hasDeadline
                      ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                      : Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: hasDeadline
                          ? (colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE))
                          : Colors.transparent,
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

  // TAB 2: ĐÁNH GIÁ TUẦN (ĐỒNG NHẤT GIAO DIỆN VỚI LỊCH TIẾN ĐỘ TUẦN CỦA SINH VIÊN)
  Widget _buildEvaluationTab(AppColors colors) {
    return RefreshIndicator(
      onRefresh: _loadTimeline,
      color: const Color(0xFF0072E8),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Tiêu đề Section chuẩn bên sinh viên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kế hoạch báo cáo định kỳ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.sectionTitle,
                    letterSpacing: 0.1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_allWeeks.length} tuần',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.sectionTitle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Danh sách các thẻ tuần phẳng đồng nhất với sinh viên
          ..._allWeeks.map((item) => _buildWeeklyPlanCard(item, colors)),
        ],
      ),
    );
  }

  String _cleanPlanTitle(String title, int weekNumber) {
    final cleaned = title.replaceFirst(RegExp(r'^Tuần\s*\d+\s*[:\-\.]?\s*', caseSensitive: false), '').trim();
    return cleaned.isNotEmpty ? cleaned : title;
  }

  // THẺ TUẦN ĐỒNG NHẤT VỚI WEEKLY_PLAN_CARD CỦA SINH VIÊN
  Widget _buildWeeklyPlanCard(WeeklyTimelineItemModel item, AppColors colors) {
    // 1. Phân tích trạng thái giống hệt WeeklyPlanCard
    String? statusText;
    Color? statusColor;
    Color? statusBg;

    if (item.isPassed != null) {
      statusText = item.isPassed == true ? 'ĐẠT' : 'CHƯA ĐẠT';
      statusColor = item.isPassed == true ? const Color(0xFF10B981) : const Color(0xFFEF4444);
      statusBg = item.isPassed == true
          ? (colors.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
          : (colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2));
    } else if (item.isSubmitted) {
      final isTurnedIn = item.submissionStatus.toLowerCase() != 'late' && item.submissionStatus.toLowerCase() != 'lateturnedin';
      statusText = isTurnedIn ? 'Đã nộp bài' : 'Nộp muộn';
      statusColor = isTurnedIn ? const Color(0xFF0284C7) : const Color(0xFFF59E0B);
      statusBg = isTurnedIn
          ? (colors.isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE))
          : (colors.isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7));
    } else if (item.hasValidDeadline) {
      statusText = item.isOverdue ? 'Quá hạn' : 'Đã giao bài';
      statusColor = item.isOverdue ? const Color(0xFFEF4444) : colors.textSecondary;
      statusBg = item.isOverdue
          ? (colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2))
          : (colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9));
    } else {
      statusText = null;
    }

    final displayTitle = _cleanPlanTitle(item.title, item.weekNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isPending
              ? (colors.isDark ? const Color(0xFFF59E0B) : const Color(0xFFFBBF24))
              : colors.cardBorder,
          width: item.isPending ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF007AFF).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tiêu đề tuần bên trái, Badge trạng thái bên phải
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuần ${item.weekNumber}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              if (statusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Tên tuần / tiêu đề công việc
          Text(
            displayTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // Hạn chót
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: colors.textMuted),
              const SizedBox(width: 5),
              Text(
                item.hasValidDeadline
                    ? 'Hạn chót: ${item.formattedDeadline}'
                    : 'Chưa có hạn nộp',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: (item.isOverdue && !item.isSubmitted && item.hasValidDeadline)
                      ? const Color(0xFFEF4444)
                      : colors.textSecondary,
                ),
              ),
            ],
          ),

          // Yêu cầu chi tiết tuần (nếu có)
          if (item.detailedRequirements.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.7, color: colors.divider),
            const SizedBox(height: 10),
            Text(
              item.detailedRequirements,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          // Khung bài nộp của nhóm sinh viên (nếu đã nộp)
          if (item.isSubmitted) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.formattedSubmittedAt != null
                              ? 'Đã nộp lúc: ${item.formattedSubmittedAt}'
                              : 'Đã nộp báo cáo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${item.submitterName ?? widget.thesis.leaderName} (Trưởng nhóm)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                        ),
                      ),
                    ],
                  ),
                  if (item.content != null && item.content!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '“${item.content}”',
                      style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ],
                  if (item.reportFileUrl != null && item.reportFileUrl!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...item.reportFileUrl!.split(';').map((rawItem) {
                      final fileItem = rawItem.trim();
                      if (fileItem.isEmpty) return const SizedBox.shrink();
                      final isUploaded = fileItem.contains('/uploads/');
                      String displayName = fileItem;
                      if (isUploaded) {
                        displayName = fileItem.split('/').last;
                        if (displayName.contains('_')) {
                          displayName = displayName.substring(displayName.indexOf('_') + 1);
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              isUploaded ? Icons.insert_drive_file_rounded : Icons.link_rounded,
                              size: 15,
                              color: isUploaded ? const Color(0xFF10B981) : colors.sectionTitle,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUploaded ? colors.textPrimary : colors.sectionTitle,
                                  decoration: isUploaded ? TextDecoration.none : TextDecoration.underline,
                                  fontWeight: isUploaded ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ],

          // Nhận xét của Giảng viên (nếu đã chấm điểm hoặc có nhận xét)
          if (item.isApproved ||
              item.supervisorScore != null ||
              (item.supervisorFeedback != null && item.supervisorFeedback!.trim().isNotEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đánh giá của bạn:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (item.supervisorScore != null)
                        Text(
                          'Điểm: ${item.supervisorScore!.toStringAsFixed(1)}/10',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                  if (item.supervisorFeedback != null && item.supervisorFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${item.supervisorFeedback}”',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Nút hành động đáy thẻ tuần
          Row(
            children: [
              // Nút 1: Đổi hạn nộp tuần
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => _showSingleWeekDeadlinePicker(item),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: const Text(
                      'Hạn nộp',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.sectionTitle,
                      side: BorderSide(color: colors.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Nút 2: Chấm điểm / Xem chi tiết bài nộp
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LecturerReportDetailScreen(
                            timelineItem: item,
                            thesis: widget.thesis,
                            user: widget.user,
                          ),
                        ),
                      ).then((_) => _loadTimeline());
                    },
                    icon: Icon(
                      item.isPending
                          ? Icons.edit_note_rounded
                          : (item.isSubmitted ? Icons.fact_check_rounded : Icons.visibility_rounded),
                      size: 16,
                    ),
                    label: Text(
                      item.isPending
                          ? 'Chấm điểm'
                          : (item.isSubmitted ? 'Xem bài nộp' : 'Xem yêu cầu'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isPending
                          ? const Color(0xFF0072E8)
                          : (colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                      foregroundColor: item.isPending
                          ? Colors.white
                          : (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8)),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: item.isPending
                            ? BorderSide.none
                            : BorderSide(
                                color: colors.isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
                                width: 1.2,
                              ),
                      ),
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

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Không có tuần nào khớp bộ lọc',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy chọn tab "Tất cả" để xem toàn bộ 12 tuần.',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // --- CẤU HÌNH DEADLINE HÀNG LOẠT 12 TUẦN & CHỈNH SỬA TỪNG TUẦN ---

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _showBatchDeadlineModal(BuildContext context) async {
    if (_allWeeks.isEmpty) return;

    final colors = AppColors.of(context);
    final sorted = List<WeeklyTimelineItemModel>.from(_allWeeks)
      ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));

    DateTime selectedWeek1Date = sorted.first.deadline.year > 2020
        ? sorted.first.deadline
        : DateTime.now().add(const Duration(days: 7));

    selectedWeek1Date = DateTime(
      selectedWeek1Date.year,
      selectedWeek1Date.month,
      selectedWeek1Date.day,
      23,
      59,
      59,
    );

    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final mediaQuery = MediaQuery.of(ctx);
            final previews = List.generate(sorted.length, (index) {
              final w = sorted[index];
              final date = selectedWeek1Date.add(Duration(days: index * 7));
              return MapEntry(w.weekNumber, date);
            });

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, mediaQuery.viewInsets.bottom + 20),
              constraints: BoxConstraints(
                maxHeight: mediaQuery.size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          sorted.any((w) => w.deadline.year > 2000)
                              ? Icons.auto_mode_rounded
                              : Icons.rocket_launch_rounded,
                          color: const Color(0xFF0072E8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sorted.any((w) => w.deadline.year > 2000)
                                  ? 'Dời & Đồng bộ lịch trình 12 tuần'
                                  : 'Kích hoạt lộ trình tiến độ 12 tuần',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              sorted.any((w) => w.deadline.year > 2000)
                                  ? 'Tự động dời hạn các tuần tiếp theo (+7 ngày) từ mốc Tuần 1 mới'
                                  : 'Chọn mốc Tuần 1, hệ thống sẽ tự động lũy tiến (+7 ngày) cho cả 12 tuần',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: colors.textSecondary),
                        onPressed: isSaving ? null : () => Navigator.pop(bottomSheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.subCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.subCardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mốc kết thúc Tuần 1:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(selectedWeek1Date)} (23:59:59)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () {
                                  _openBottomDatePicker(
                                    context: context,
                                    title: 'Hạn chót Tuần 1',
                                    initialDate: selectedWeek1Date,
                                    onDateSelected: (picked) {
                                      setModalState(() {
                                        selectedWeek1Date = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                          23,
                                          59,
                                          59,
                                        );
                                      });
                                    },
                                  );
                                },
                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                          label: const Text('Đổi ngày'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0072E8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Xem trước lộ trình 12 tuần:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '${sorted.length} tuần',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0072E8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.subCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.subCardBorder),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: previews.length,
                        separatorBuilder: (_, index) => Divider(height: 1, color: colors.cardBorder),
                        itemBuilder: (_, idx) {
                          final p = previews[idx];
                          final isWeek1 = p.key == 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isWeek1
                                        ? const Color(0xFF0072E8)
                                        : (colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Tuần ${p.key}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isWeek1
                                          ? Colors.white
                                          : (colors.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Hạn: ${_formatDate(p.value)} (23:59:59)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isWeek1 ? FontWeight.w800 : FontWeight.w600,
                                      color: isWeek1
                                          ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                                          : colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isWeek1)
                                  const Text(
                                    'Mốc gốc',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF0072E8), fontWeight: FontWeight.w700),
                                  )
                                else
                                  Text(
                                    '+${idx * 7} ngày',
                                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(bottomSheetContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: colors.cardBorder),
                          ),
                          child: Text(
                            'Hủy',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setModalState(() => isSaving = true);
                                  final res = await _service.updateBatchWeeklyDeadlines(
                                    weeks: sorted,
                                    week1Deadline: selectedWeek1Date,
                                  );
                                  setModalState(() => isSaving = false);

                                  if (res['success'] == true) {
                                    if (bottomSheetContext.mounted) {
                                      Navigator.pop(bottomSheetContext);
                                    }
                                    if (context.mounted) {
                                      AppToast.showSuccess(
                                        context,
                                        res['message'] ?? 'Đã cấu hình deadline 12 tuần thành công!',
                                        title: 'Cấu hình hoàn tất',
                                      );
                                      _loadTimeline();
                                    }
                                  } else {
                                    if (context.mounted) {
                                      AppToast.showError(
                                        context,
                                        res['message'] ?? 'Lỗi cập nhật',
                                        title: 'Thất bại',
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0072E8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      sorted.any((w) => w.deadline.year > 2000)
                                          ? 'Lưu & Áp dụng lịch mới'
                                          : 'Kích hoạt & Áp dụng 12 tuần',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSingleWeekDeadlinePicker(WeeklyTimelineItemModel item) async {
    final initialDate = item.deadline.year > 2020 ? item.deadline : DateTime.now();
    _openBottomDatePicker(
      context: context,
      title: 'Hạn nộp Tuần ${item.weekNumber}',
      initialDate: initialDate,
      onDateSelected: (picked) async {
        final newDeadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );

        final res = await _service.updatePlanDeadline(item.planId, newDeadline);
        if (!mounted) return;

        if (res['success'] == true) {
          AppToast.showSuccess(
            context,
            'Hạn nộp Tuần ${item.weekNumber} đã đổi sang ${_formatDate(newDeadline)} (23:59:59)',
            title: 'Cập nhật thành công',
          );
          _loadTimeline();
        } else {
          AppToast.showError(
            context,
            res['message'] ?? 'Không thể cập nhật hạn nộp',
            title: 'Thất bại',
          );
        }
      },
    );
  }

  /// Hàm hiển thị BottomPicker date hiện đại, bo góc mềm mại, chuẩn màu HUIT Blue
  void _openBottomDatePicker({
    required BuildContext context,
    required String title,
    required DateTime initialDate,
    required void Function(DateTime selectedDate) onDateSelected,
  }) {
    final colors = AppColors.of(context);
    BottomPicker.date(
      headerBuilder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: Color(0xFF0072E8), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: colors.textSecondary),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
      dateOrder: DatePickerDateOrder.dmy,
      initialDateTime: initialDate,
      minDateTime: DateTime(2020),
      maxDateTime: DateTime(2035),
      backgroundColor: colors.cardBg,
      pickerTextStyle: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      buttonBuilder: (instance, ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final picked = instance.currentValue;
                instance.dismiss();
                if (picked is DateTime) {
                  onDateSelected(picked);
                } else {
                  onDateSelected(initialDate);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0072E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'XÁC NHẬN CHỌN NGÀY',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        );
      },
    ).show(context);
  }
}
