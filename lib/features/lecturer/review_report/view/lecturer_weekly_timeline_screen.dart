import 'package:flutter/material.dart';
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

class _LecturerWeeklyTimelineScreenState extends State<LecturerWeeklyTimelineScreen> {
  final WeeklyReportService _service = WeeklyReportService();

  List<WeeklyTimelineItemModel> _allWeeks = [];
  List<WeeklyTimelineItemModel> _filteredWeeks = [];
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'not_submitted'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
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
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    List<WeeklyTimelineItemModel> list = List.from(_allWeeks);
    if (_selectedFilter == 'pending') {
      list = list.where((w) => w.isPending).toList();
    } else if (_selectedFilter == 'approved') {
      list = list.where((w) => w.isApproved).toList();
    } else if (_selectedFilter == 'not_submitted') {
      list = list.where((w) => w.isNotSubmitted || w.isOverdue).toList();
    }
    _filteredWeeks = list;
  }

  int get _pendingCount => _allWeeks.where((w) => w.isPending).length;
  int get _approvedCount => _allWeeks.where((w) => w.isApproved).length;
  int get _notSubmittedCount => _allWeeks.where((w) => w.isNotSubmitted || w.isOverdue).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Chuẩn Scaffold App_Mobile.md
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING PILL HEADER
            _buildFloatingHeader(),

            // 2. THẺ TÓM TẮT ĐỀ TÀI & SINH VIÊN ĐẠI DIỆN NỘP (CỐ ĐỊNH NHÓM TRƯỞNG)
            _buildThesisSummaryCard(),

            // 3. TAB LỌC TRẠNG THÁI TUẦN
            _buildFilterTabs(),

            const SizedBox(height: 6),

            // 4. DANH SÁCH 12 TUẦN TIMELINE
            Expanded(
              child: _isLoading
                  ? const Center(child: HuitLoading(size: 46, message: 'Đang tải lộ trình 12 tuần...'))
                  : _filteredWeeks.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadTimeline,
                          color: const Color(0xFF0F766E),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _filteredWeeks.length,
                            itemBuilder: (context, index) {
                              final item = _filteredWeeks[index];
                              final isLast = index == _filteredWeeks.length - 1;
                              return _buildTimelineItem(item, isLast);
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                'LỘ TRÌNH TIẾN ĐỘ 12 TUẦN',
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
  Widget _buildThesisSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                height: 1.25,
              ),
            ),

            const SizedBox(height: 10),

            // BOX NHÓM TRƯỞNG CỐ ĐỊNH ĐẠI DIỆN NỘP BÁO CÁO
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Đại diện nộp báo cáo:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '(CỐ ĐỊNH NHÓM TRƯỞNG)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.thesis.leaderName} • MSSV: ${widget.thesis.leaderCode}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_approvedCount/12 tuần đạt',
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

  // 3. Tab lọc trạng thái tuần
  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildTabChip('all', 'Tất cả (${_allWeeks.length})'),
            const SizedBox(width: 8),
            _buildTabChip('pending', 'Chờ duyệt ($_pendingCount)', badgeColor: const Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            _buildTabChip('approved', 'Đã duyệt ($_approvedCount)', badgeColor: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _buildTabChip('not_submitted', 'Chưa nộp ($_notSubmittedCount)'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String key, String label, {Color? badgeColor}) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = key;
          _applyFilter();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F766E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // 4. Timeline item component
  Widget _buildTimelineItem(WeeklyTimelineItemModel item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bên trái: Vòng tròn tuần + Đường line nối
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.statusBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: item.statusColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${item.weekNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: item.statusColor,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      color: const Color(0xFFCBD5E1),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Bên phải: Thẻ nội dung tuần
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: item.isPending
                    ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
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
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Tiêu đề Tuần + Badge trạng thái
                        Row(
                          children: [
                            Text(
                              'TUẦN ${item.weekNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F766E),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.statusBgColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(item.statusIcon, color: item.statusColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.statusDisplayText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: item.statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Tên nhiệm vụ tuần
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Hạn chót
                        Row(
                          children: [
                            const Icon(Icons.event_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              'Hạn nộp: ${item.formattedDeadline}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // NỘI DUNG NỘP BÁO CÁO (NẾU ĐÃ NỘP)
                        if (item.isSubmitted) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dòng người đại diện nộp CỐ ĐỊNH NHÓM TRƯỞNG
                                Row(
                                  children: [
                                    const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'Người nộp: ',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          children: [
                                            TextSpan(
                                              text: item.submitterName ?? widget.thesis.leaderName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const TextSpan(
                                              text: ' (Nhóm trưởng)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F766E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (item.formattedSubmittedAt != null)
                                      Text(
                                        item.formattedSubmittedAt!,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                      ),
                                  ],
                                ),
                                if (item.content != null && item.content!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.content!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF475569),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // NẾU ĐÃ CÓ ĐÁNH GIÁ CỦA GV
                          if (item.supervisorScore != null || (item.supervisorFeedback != null && item.supervisorFeedback!.isNotEmpty)) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.rate_review_outlined, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  if (item.supervisorScore != null)
                                    Text(
                                      'Điểm: ${item.supervisorScore!.toStringAsFixed(1)}/10  •  ',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      item.supervisorFeedback ?? 'Đã nhận xét',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          // CHƯA NỘP
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Chờ nhóm trưởng nộp báo cáo tiến độ tuần này.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // NÚT HÀNH ĐỘNG
                        Align(
                          alignment: Alignment.centerRight,
                          child: item.isPending
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_note_rounded, color: Colors.white, size: 15),
                                      SizedBox(width: 4),
                                      Text(
                                        'Duyệt báo cáo ngay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.isSubmitted ? 'Xem chi tiết & nhận xét' : 'Xem yêu cầu tuần',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0F766E)),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
            const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'Không có tuần nào khớp bộ lọc',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hãy chọn tab "Tất cả" để xem toàn bộ 12 tuần.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
