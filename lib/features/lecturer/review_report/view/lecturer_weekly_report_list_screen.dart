import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _periods = [];
  int? _selectedPeriodId;
  String _selectedGroupFilter = 'all'; // 'all', 'has_group', 'no_group'
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

    // Mặc định chọn ĐỢT MỚI NHẤT (index 0)
    if (periods.isNotEmpty && _selectedPeriodId == null) {
      _selectedPeriodId = periods.first['periodId'] as int?;
    }

    final data = await _service.getApprovedTheses(
      periodId: _selectedPeriodId,
      groupFilter: 'all',
      searchQuery: null,
    );

    if (mounted) {
      setState(() {
        _periods = periods;
        _allApprovedTheses = data;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    final data = await _service.getApprovedTheses(
      periodId: _selectedPeriodId,
      groupFilter: 'all',
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
    List<LecturerThesisModel> list = List.from(_allApprovedTheses);

    // Phân loại: 2 trạng thái 'Đã có nhóm' và 'Chưa có nhóm' (kèm Tất cả)
    if (_selectedGroupFilter == 'has_group') {
      list = list.where((t) => t.hasGroup).toList();
    } else if (_selectedGroupFilter == 'no_group') {
      list = list.where((t) => !t.hasGroup).toList();
    }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING PILL HEADER
            _buildFloatingHeader(),

            // 2. THANH TÌM KIẾM & BỘ LỌC ĐỢT (Mặc định đợt mới nhất)
            _buildSearchAndPeriodFilter(),

            // 3. TAB PHÂN LOẠI: TẤT CẢ | ĐÃ CÓ NHÓM | CHƯA CÓ NHÓM
            _buildGroupFilterTabs(),

            const SizedBox(height: 6),

            // 4. DANH SÁCH ĐỀ TÀI ĐÃ DUYỆT & KẾ HOẠCH TIẾN ĐỘ TUẦN
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
                'BÁO CÁO TUẦN & PHẢN HỒI TIẾN ĐỘ',
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

  // 2. Ô tìm kiếm và chọn đợt (Mặc định đợt mới nhất, có thể đổi bất cứ lúc nào)
  Widget _buildSearchAndPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Search box
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
                onChanged: (_) {
                  setState(() => _applyFilters());
                },
                decoration: InputDecoration(
                  hintText: 'Tìm đề tài đã duyệt, nhóm SV...',
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
          ),
          const SizedBox(width: 10),

          // Dropdown chọn đợt (phân loại đợt bất cứ lúc nào)
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
                    _selectedGroupFilter = 'all';
                  });
                  _refresh();
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

  // 3. Tab phân loại: 2 trạng thái 'Đã có nhóm' và 'Chưa có nhóm' trong đợt đó
  Widget _buildGroupFilterTabs() {
    final hasGroupCount = _allApprovedTheses.where((t) => t.hasGroup).length;
    final noGroupCount = _allApprovedTheses.where((t) => !t.hasGroup).length;

    final filterList = [
      {
        'key': 'all',
        'label': 'Tất cả (${_allApprovedTheses.length})',
      },
      {
        'key': 'has_group',
        'label': 'Đã có nhóm ($hasGroupCount)',
        'icon': Icons.group_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'key': 'no_group',
        'label': 'Chưa có nhóm ($noGroupCount)',
        'icon': Icons.group_off_rounded,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filterList.map((item) {
          final isSelected = _selectedGroupFilter == item['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedGroupFilter = item['key'] as String);
                _applyFilters();
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

  // 4. Thẻ Đề tài đã duyệt & Mục kế hoạch - chấm tiến độ tuần riêng ở ngoài
  Widget _buildThesisCard(LecturerThesisModel thesis) {
    final hasGroup = thesis.hasGroup;
    final group = hasGroup ? thesis.registeredGroups.first : null;
    final leader = (group != null && group.members.isNotEmpty) ? group.members.first : null;

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
          // Header Card: Mã đề tài + Tên đợt + Badge phân loại nhóm
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
                // Badge Đã có nhóm / Chưa có nhóm
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasGroup ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasGroup ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: hasGroup ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasGroup ? 'ĐÃ CÓ NHÓM (${group!.memberCount} SV)' : 'CHƯA CÓ NHÓM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: hasGroup ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nội dung chính
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
                const SizedBox(height: 12),

                // TRƯỜNG HỢP 1: ĐỀ TÀI ĐÃ CÓ NHÓM
                if (hasGroup) ...[
                  // Khung thông tin nhóm & Trưởng nhóm
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.group_rounded, color: Color(0xFF0F766E), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                group!.groupName,
                                style: const TextStyle(
                                  fontSize: 13,
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
                                '${group.memberCount} thành viên',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                              ),
                            ),
                          ],
                        ),
                        if (leader != null) ...[
                          const Divider(height: 14, color: Color(0xFFE2E8F0)),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 15),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Trưởng nhóm: ${leader.fullName} (${leader.studentCode})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (leader.phoneNumber.isNotEmpty)
                                Text(
                                  leader.phoneNumber,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // MỤC KẾ HOẠCH VÀ TIẾN ĐỘ TUẦN NẰM RIÊNG Ở NGOÀI
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kế hoạch & Báo cáo tiến độ tuần',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Lộ trình 12 tuần • Nhóm trưởng nộp báo cáo',
                                style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: const Text(
                            '12 tuần',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // NÚT MỞ MÀN HÌNH KẾ HOẠCH & CHẤM TIẾN ĐỘ TUẦN
                  SizedBox(
                    width: double.infinity,
                    height: 44,
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
                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                      label: const Text(
                        'Kế hoạch & Chấm tiến độ tuần',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ] else ...[
                  // TRƯỜNG HỢP 2: ĐỀ TÀI CHƯA CÓ NHÓM
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chưa có nhóm sinh viên đăng ký',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Đề tài đang mở trong đợt này. Khi có nhóm sinh viên đăng ký và được chấp thuận, kế hoạch và phản hồi tiến độ tuần sẽ xuất hiện.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
              child: const Icon(Icons.assignment_late_outlined, color: Color(0xFF94A3B8), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              hasPeriod ? 'Đợt này chưa có đề tài đã duyệt' : 'Không có đề tài nào thỏa mãn',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              hasPeriod
                  ? 'Trong đợt bạn chọn chưa có đề tài nào ở trạng thái "Đã duyệt". Hãy chọn "Tất cả đợt" hoặc chọn đợt khác.'
                  : 'Vui lòng kiểm tra lại từ khóa tìm kiếm hoặc đổi bộ lọc phân loại.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            if (hasPeriod) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPeriodId = null;
                    _selectedGroupFilter = 'all';
                  });
                  _refresh();
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
