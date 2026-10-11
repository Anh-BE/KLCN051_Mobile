import 'package:flutter/material.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../../review_report/logic/weekly_report_service.dart';
import '../../review_report/model/weekly_report_model.dart';
import '../logic/lecturer_topic_service.dart';
import '../model/lecturer_thesis_model.dart';

class LecturerTopicListScreen extends StatefulWidget {
  final UserModel user;

  const LecturerTopicListScreen({super.key, required this.user});

  @override
  State<LecturerTopicListScreen> createState() => _LecturerTopicListScreenState();
}

class _LecturerTopicListScreenState extends State<LecturerTopicListScreen> {
  final LecturerTopicService _service = LecturerTopicService();
  final TextEditingController _searchController = TextEditingController();

  List<LecturerThesisModel> _allTheses = [];
  List<LecturerThesisModel> _theses = [];
  List<Map<String, dynamic>> _periods = [];
  int? _selectedPeriodId;
  String _selectedStatus = 'all'; // 'all', 'Approved', 'Pending', 'Rejected'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Khởi tạo dữ liệu từ CSDL thật: Mặc định chọn ngay ĐỢT MỚI NHẤT
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final periods = await _service.getPeriods();

    // Mặc định chọn ĐỢT MỚI NHẤT (index 0 vì đã sắp xếp giảm dần theo PeriodId)
    if (periods.isNotEmpty && _selectedPeriodId == null) {
      _selectedPeriodId = periods.first['periodId'] as int?;
    }

    final data = await _service.getTheses(
      periodId: _selectedPeriodId,
      statusFilter: 'all',
      searchQuery: null,
    );

    if (mounted) {
      setState(() {
        _periods = periods;
        _allTheses = data;
        _applyFilterInternal();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshList() async {
    final data = await _service.getTheses(
      periodId: _selectedPeriodId,
      statusFilter: 'all',
      searchQuery: null,
    );
    if (mounted) {
      setState(() {
        _allTheses = data;
        _applyFilterInternal();
      });
    }
  }

  void _applyFilterInternal() {
    List<LecturerThesisModel> filtered = List.from(_allTheses);

    // Lọc theo status tab
    if (_selectedStatus != 'all') {
      filtered = filtered.where((t) => _isStatusMatch(t.status, _selectedStatus)).toList();
    }

    // Lọc theo search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        final title = t.thesisTitle.toLowerCase();
        final code = t.periodCode.toLowerCase();
        final type = t.thesisType.toLowerCase();
        return title.contains(query) || code.contains(query) || type.contains(query);
      }).toList();
    }

    _theses = filtered;
  }

  void _applyFilter() {
    setState(() {
      _applyFilterInternal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING PILL HEADER
            _buildFloatingHeader(),

            // 2. THANH TÌM KIẾM & BỘ LỌC ĐỢT (Mặc định đợt mới nhất)
            _buildSearchAndPeriodFilter(),

            // 3. TAB TRẠNG THÁI (Tất cả, Đã duyệt, Chờ duyệt, Từ chối)
            _buildStatusTabs(),

            const SizedBox(height: 8),

            // 4. DANH SÁCH ĐỀ TÀI & TRẠNG THÁI (Chỉ chứa đề tài, không hiển thị nhóm)
            Expanded(
              child: _isLoading
                  ? const Center(child: HuitLoading(size: 48, message: 'Đang tải danh sách đề tài...'))
                  : _theses.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshList,
                          color: const Color(0xFF0F766E),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _theses.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              return _buildThesisCard(_theses[index]);
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
                'ĐỀ TÀI & TRẠNG THÁI ĐỀ XUẤT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              onPressed: () {
                _loadInitialData();
              },
              tooltip: 'Làm mới',
            ),
          ],
        ),
      ),
    );
  }

  // 2. Ô tìm kiếm và chọn đợt khóa luận (mặc định đợt mới nhất, có thể chọn bất kỳ lúc nào)
  Widget _buildSearchAndPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Ô tìm kiếm
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilter(),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, mã đề tài...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter();
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

          // Dropdown phân loại đợt (có thể ấn chọn bất cứ lúc nào)
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedPeriodId,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0D9488)),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                onChanged: (val) {
                  setState(() {
                    _selectedPeriodId = val;
                    _selectedStatus = 'all';
                  });
                  _refreshList();
                },
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả đợt'),
                  ),
                  if (_periods.isNotEmpty)
                    ..._periods
                        .where((p) => p['periodId'] != null)
                        .map((p) {
                      final rawName = (p['periodName'] ?? 'Đợt khóa luận').toString();
                      final shortName = rawName
                          .replaceAll('Khóa luận tốt nghiệp ', 'KLTN ')
                          .replaceAll('Khóa luận ', 'KL ');
                      return DropdownMenuItem<int?>(
                        value: p['periodId'] as int,
                        child: Text(
                          shortName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String, IconData) _getThesisStatusMeta(String rawStatus) {
    final st = rawStatus.toLowerCase().trim();
    if (st == 'approved' || st == 'daduyet' || st == 'da_duyet' || st == 'active') {
      return (
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
        'ĐÃ DUYỆT',
        Icons.check_circle_rounded,
      );
    }
    if (st.contains('reject') || st.contains('revision') || st.contains('tuchoi') || st.contains('tu_choi') || st.contains('cancel') || st.contains('khongduyet')) {
      return (
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
        'TỪ CHỐI',
        Icons.cancel_rounded,
      );
    }
    return (
      const Color(0xFFFEF3C7),
      const Color(0xFF92400E),
      'CHỜ DUYỆT',
      Icons.timelapse_rounded,
    );
  }

  bool _isStatusMatch(String rawStatus, String filterKey) {
    if (filterKey == 'all') return true;
    final meta = _getThesisStatusMeta(rawStatus);
    if (filterKey == 'Approved') return meta.$3 == 'ĐÃ DUYỆT';
    if (filterKey == 'Pending') return meta.$3 == 'CHỜ DUYỆT';
    if (filterKey == 'Rejected') return meta.$3 == 'TỪ CHỐI';
    return true;
  }

  // 3. Tab trạng thái: Tất cả, Đã duyệt, Chờ duyệt, Từ chối
  Widget _buildStatusTabs() {
    final list = _allTheses;
    final approvedCount = list.where((t) => _isStatusMatch(t.status, 'Approved')).length;
    final pendingCount = list.where((t) => _isStatusMatch(t.status, 'Pending')).length;
    final rejectedCount = list.where((t) => _isStatusMatch(t.status, 'Rejected')).length;

    final statusList = [
      {'key': 'all', 'label': 'Tất cả (${list.length})'},
      {'key': 'Approved', 'label': 'Đã duyệt ($approvedCount)', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF10B981)},
      {'key': 'Pending', 'label': 'Chờ duyệt ($pendingCount)', 'icon': Icons.schedule_rounded, 'color': const Color(0xFFF59E0B)},
      {'key': 'Rejected', 'label': 'Từ chối ($rejectedCount)', 'icon': Icons.cancel_rounded, 'color': const Color(0xFFEF4444)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: statusList.map((item) {
          final isSelected = _selectedStatus == item['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedStatus = item['key'] as String);
                _applyFilter();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F766E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
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
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item['icon'] != null) ...[
                      Icon(
                        item['icon'] as IconData,
                        size: 15,
                        color: isSelected ? Colors.white : (item['color'] as Color),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. Thẻ Đề tài chi tiết: CHỈ CHỨA ĐỀ TÀI, BỎ MỤC NHÓM ĐĂNG KÝ
  Widget _buildThesisCard(LecturerThesisModel thesis) {
    final (statusBg, statusTextColor, statusText, statusIcon) = _getThesisStatusMeta(thesis.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header của Card: Mã đề tài + Tên đợt + Badge trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    thesis.periodCode.isNotEmpty ? thesis.periodCode : 'DT${thesis.thesisId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thesis.periodName,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Badge trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusTextColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nội dung chính của Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên đề tài
                Text(
                  thesis.thesisTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),

                // Tags định hướng và CLO
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPillTag(
                      label: thesis.thesisType,
                      icon: Icons.lightbulb_outline_rounded,
                      bgColor: const Color(0xFFEFF6FF),
                      textColor: const Color(0xFF1D4ED8),
                    ),
                    if (thesis.outlineObjectives.isNotEmpty)
                      _buildPillTag(
                        label: '${thesis.outlineObjectives.length} CLO Chuẩn đầu ra',
                        icon: Icons.checklist_rounded,
                        bgColor: const Color(0xFFF0FDF4),
                        textColor: const Color(0xFF15803D),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // NÚT XEM CHI TIẾT ĐỀ TÀI: Mở 3 mục (Thông tin đề tài, Bảng CLO, Báo cáo tiến độ tuần)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openThesisDetailSheet(thesis),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text(
                      'Xem chi tiết đề tài',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildPillTag({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }

  // BottomSheet chi tiết đề tài: Đúng 3 mục (Thông tin đề tài, Bảng CLO, Bảng báo cáo tiến độ tuần)
  void _openThesisDetailSheet(LecturerThesisModel thesis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ThesisDetailBottomSheet(
        thesis: thesis,
        user: widget.user,
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasPeriod = _selectedPeriodId != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.folder_off_outlined, color: Color(0xFF94A3B8), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              hasPeriod ? 'Đợt này chưa có đề tài' : 'Không tìm thấy đề tài nào',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              hasPeriod
                  ? 'Đợt bạn chọn hiện chưa có đề tài nào được phân công hoặc tạo mới. Bạn có thể chọn "Tất cả đợt" bằng bộ lọc ở trên.'
                  : 'Vui lòng thử thay đổi từ khóa tìm kiếm hoặc bộ lọc trạng thái.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            if (hasPeriod) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPeriodId = null;
                    _selectedStatus = 'all';
                  });
                  _refreshList();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Xem tất cả các đợt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// BOTTOM SHEET CHI TIẾT ĐỀ TÀI: ĐÚNG 3 MỤC
// 1. THÔNG TIN ĐỀ TÀI
// 2. BẢNG CLO
// 3. BẢNG BÁO CÁO TIẾN ĐỘ TUẦN
class _ThesisDetailBottomSheet extends StatefulWidget {
  final LecturerThesisModel thesis;
  final UserModel user;

  const _ThesisDetailBottomSheet({
    required this.thesis,
    required this.user,
  });

  @override
  State<_ThesisDetailBottomSheet> createState() => _ThesisDetailBottomSheetState();
}

class _ThesisDetailBottomSheetState extends State<_ThesisDetailBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedCloKeys = {};
  List<WeeklyTimelineItemModel> _weeklyTimeline = [];
  bool _isLoadingTimeline = true;

  String _getCloKey(OutlineObjectiveItem clo) {
    if (clo.clocode.trim().isNotEmpty) return clo.clocode.trim();
    return clo.objectiveId.toString();
  }

  @override
  void initState() {
    super.initState();
    // ĐÚNG 3 TAB: THÔNG TIN ĐỀ TÀI, BẢNG CLO, BẢNG BÁO CÁO TIẾN ĐỘ TUẦN
    _tabController = TabController(length: 3, vsync: this);
    if (widget.thesis.outlineObjectives.isNotEmpty) {
      _expandedCloKeys.add(_getCloKey(widget.thesis.outlineObjectives.first));
    }
    _loadWeeklyTimeline();
  }

  /// Tải bảng báo cáo tiến độ tuần từ CSDL thật
  Future<void> _loadWeeklyTimeline() async {
    setState(() => _isLoadingTimeline = true);
    final data = await WeeklyReportService().getThesisTimeline(widget.thesis.thesisId);
    if (mounted) {
      setState(() {
        _weeklyTimeline = data;
        _isLoadingTimeline = false;
      });
    }
  }

  void _toggleClo(OutlineObjectiveItem clo) {
    final key = _getCloKey(clo);
    setState(() {
      if (_expandedCloKeys.contains(key)) {
        _expandedCloKeys.remove(key);
      } else {
        _expandedCloKeys.add(key);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thesis = widget.thesis;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thesis.periodCode.isNotEmpty ? thesis.periodCode : 'DT${thesis.thesisId}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        thesis.thesisTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // TabBar: ĐÚNG 3 MỤC THEO YÊU CẦU
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0F766E),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0F766E),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                const Tab(text: 'Thông tin đề tài'),
                Tab(text: 'Bảng CLO (${thesis.outlineObjectives.length})'),
                const Tab(text: 'Bảng báo cáo tiến độ tuần'),
              ],
            ),
          ),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: THÔNG TIN ĐỀ TÀI
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Định hướng nghiên cứu:'),
                      const SizedBox(height: 4),
                      Text(thesis.thesisType, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 18),

                      _buildSectionTitle('Đợt khóa luận:'),
                      const SizedBox(height: 4),
                      Text(thesis.periodName, style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                      const SizedBox(height: 18),

                      _buildSectionTitle('Giảng viên hướng dẫn:'),
                      const SizedBox(height: 4),
                      Text(
                        thesis.gvhd.isNotEmpty ? thesis.gvhd : 'Giảng viên đề xuất',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 18),

                      _buildSectionTitle('Yêu cầu & Nội dung thuyết minh:'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          thesis.requirements.isNotEmpty ? thesis.requirements : 'Chưa có yêu cầu chi tiết.',
                          style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 2: BẢNG CLO (CHUẨN ĐẦU RA)
                thesis.outlineObjectives.isEmpty
                    ? const Center(
                        child: Text('Chưa có cấu hình đề cương CLO cho đề tài này', style: TextStyle(color: Color(0xFF64748B))),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Chạm vào từng CLO để xem danh sách chuẩn đầu ra con (CLO con)',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...thesis.outlineObjectives.map((clo) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCloCard(clo),
                              )),
                        ],
                      ),

                // TAB 3: BẢNG BÁO CÁO TIẾN ĐỘ TUẦN
                _buildWeeklyReportTableTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: BẢNG BÁO CÁO TIẾN ĐỘ TUẦN
  Widget _buildWeeklyReportTableTab() {
    if (_isLoadingTimeline) {
      return const Center(
        child: HuitLoading(size: 44, message: 'Đang tải bảng báo cáo tiến độ tuần...'),
      );
    }

    if (_weeklyTimeline.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 44),
              ),
              const SizedBox(height: 14),
              const Text(
                'Chưa có dữ liệu tiến độ tuần',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Đề tài chưa được khởi tạo kế hoạch 12 tuần trong hệ thống hoặc chưa bắt đầu đợt thực hiện.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    final totalWeeks = _weeklyTimeline.length;
    final approvedCount = _weeklyTimeline.where((w) => w.isApproved).length;
    final submittedCount = _weeklyTimeline.where((w) => w.isSubmitted).length;
    final percent = totalWeeks > 0 ? (approvedCount / totalWeeks * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Card tóm tắt tiến độ tổng quát
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF115E59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TIẾN ĐỘ THỰC HIỆN ĐỀ TÀI',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percent.toStringAsFixed(1)}% Hoàn thành',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (percent / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildProgressMiniStat('Tổng tuần', '$totalWeeks tuần'),
                  _buildProgressMiniStat('Đã nộp', '$submittedCount/$totalWeeks'),
                  _buildProgressMiniStat('Đã đạt', '$approvedCount/$totalWeeks'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildSectionTitle('BẢNG DANH SÁCH BÁO CÁO CÁC TUẦN:'),
        const SizedBox(height: 10),

        // Danh sách các dòng báo cáo tuần
        ..._weeklyTimeline.map((item) => _buildWeekRowItem(item)),
      ],
    );
  }

  Widget _buildProgressMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10.5)),
      ],
    );
  }

  Widget _buildWeekRowItem(WeeklyTimelineItemModel item) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (item.isApproved) {
      badgeBg = const Color(0xFFD1FAE5);
      badgeText = const Color(0xFF065F46);
      badgeLabel = item.supervisorScore != null ? 'ĐẠT (${item.supervisorScore}đ)' : 'ĐÃ ĐẠT';
      badgeIcon = Icons.check_circle_rounded;
    } else if (item.isPending) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFF92400E);
      badgeLabel = 'CHỜ DUYỆT';
      badgeIcon = Icons.hourglass_top_rounded;
    } else if (item.isOverdue) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFF991B1B);
      badgeLabel = 'QUÁ HẠN';
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      badgeBg = const Color(0xFFF1F5F9);
      badgeText = const Color(0xFF64748B);
      badgeLabel = 'CHƯA NỘP';
      badgeIcon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tuần ${item.weekNumber.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.formattedDeadline.isNotEmpty ? 'Hạn: ${item.formattedDeadline}' : '',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: badgeText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          if (item.detailedRequirements.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.detailedRequirements,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
            ),
          ],
          if (item.supervisorFeedback != null && item.supervisorFeedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Nhận xét GV: ${item.supervisorFeedback}',
                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF0F766E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCloCard(OutlineObjectiveItem clo) {
    final key = _getCloKey(clo);
    final isExpanded = _expandedCloKeys.contains(key);
    final subList = _getSubObjectives(clo);
    final hasSub = subList.isNotEmpty;
    final double score = (clo.maxScore > 0 && clo.maxScore < 10.0)
        ? clo.maxScore
        : (clo.weightPercentage / 10);
    final String scoreFormatted = score % 1 == 0 ? '${score.toInt()}đ' : '${score.toStringAsFixed(1)}đ';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? const Color(0xFF2563EB).withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? const Color(0xFF2563EB).withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleClo(clo),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      clo.clocode.isNotEmpty ? clo.clocode : 'CLO',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      clo.outlineContent,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${clo.weightPercentage.toStringAsFixed(0)}% ($scoreFormatted)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),

                  if (hasSub) ...[
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF64748B),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isExpanded && hasSub) ...[
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Danh sách chuẩn đầu ra chi tiết (CLO con):',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  ...subList.map((sub) => _buildSubCloItem(sub)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<OutlineObjectiveItem> _getSubObjectives(OutlineObjectiveItem clo) {
    if (clo.subObjectives.isNotEmpty) return clo.subObjectives;
    return [];
  }

  Widget _buildSubCloItem(OutlineObjectiveItem sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sub.clocode.isNotEmpty ? sub.clocode : '•',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Text(
              sub.outlineContent,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),

          Text(
            '${sub.weightPercentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
      ),
    );
  }
}
