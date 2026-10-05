import 'package:flutter/material.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
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

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final periods = await _service.getPeriods();
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
        final hasStudent = t.registeredGroups.any((g) =>
            g.groupName.toLowerCase().contains(query) ||
            g.members.any((m) => m.fullName.toLowerCase().contains(query) || m.studentCode.toLowerCase().contains(query)));
        return title.contains(query) || code.contains(query) || hasStudent;
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
      backgroundColor: const Color(0xFFF1F5F9), // Chuẩn Scaffold Background App_Mobile.md
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING PILL HEADER CHUẨN DESIGN SYSTEM
            _buildFloatingHeader(),

            // 2. THANH TÌM KIẾM & BỘ LỌC ĐỢT
            _buildSearchAndPeriodFilter(),

            // 3. TAB TRẠNG THÁI VIÊN THUỐC
            _buildStatusTabs(),

            const SizedBox(height: 8),

            // 4. DANH SÁCH ĐỀ TÀI & TRẠNG THÁI
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

  // 1. Floating Pill Header phong cách đồng bộ
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
            // Nút Back tròn
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Quay lại',
            ),
            const Expanded(
              child: Text(
                'ĐỀ TÀI HƯỚNG DẪN & TRẠNG THÁI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            // Nút refresh nhẹ
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

  // 2. Ô tìm kiếm và chọn đợt khóa luận
  Widget _buildSearchAndPeriodFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Ô tìm kiếm bo tròn
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
                  hintText: 'Tìm theo tên, mã đề tài, nhóm SV...',
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

          // Dropdown chọn đợt
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
                    _selectedStatus = 'all'; // Reset về Tất cả khi đổi đợt
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
                      final shortName = rawName.replaceAll('Khóa luận tốt nghiệp ', 'KLTN ').replaceAll('Khóa luận ', 'KL ');
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

  // Phân loại trạng thái đề tài chuẩn xác, đồng bộ giữa các tab và thẻ đề tài
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
    // Mọi trạng thái chờ duyệt: pending, pendingreview, waiting, choduyet,...
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

  // 3. Tab trạng thái dạng viên thuốc
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

  // 4. Thẻ Đề tài chi tiết
  Widget _buildThesisCard(LecturerThesisModel thesis) {
    // Trạng thái hiển thị đồng bộ 100%
    final (statusBg, statusTextColor, statusText, statusIcon) = _getThesisStatusMeta(thesis.status);

    final hasGroup = thesis.registeredGroups.isNotEmpty;
    final registeredGroup = hasGroup ? thesis.registeredGroups.first : null;

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
          // Header của Card: Mã đề tài + Badge trạng thái
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

                // Tags thông tin định hướng và đợt
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

                // KHỐI THÔNG TIN NHÓM SINH VIÊN ĐĂNG KÝ
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasGroup ? const Color(0xFFF8FAFC) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasGroup ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
                      width: 1,
                    ),
                  ),
                  child: hasGroup
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups_rounded, color: Color(0xFF0F766E), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    registeredGroup!.groupName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${registeredGroup.memberCount} thành viên',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (registeredGroup.members.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_rounded, color: Color(0xFF64748B), size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Trưởng nhóm: ${registeredGroup.members.first.fullName} (${registeredGroup.members.first.studentCode})',
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )
                      : const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa có nhóm sinh viên nào đăng ký',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 14),

                // NÚT BẤM XEM CHI TIẾT
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _openThesisDetailSheet(thesis),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text(
                      'Xem chi tiết đề tài & Đề cương CLO',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // 5. BottomSheet chi tiết đề tài chuẩn mực HUIT
  void _openThesisDetailSheet(LecturerThesisModel thesis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ThesisDetailBottomSheet(thesis: thesis),
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
                  ? 'Đợt bạn chọn hiện chưa có đề tài nào được phân công hoặc tạo mới trong hệ thống. Bạn có thể chọn "Tất cả đợt" hoặc "Đợt 1".'
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

// BOTTOM SHEET CHI TIẾT ĐỀ TÀI & ĐỀ CƯƠNG
class _ThesisDetailBottomSheet extends StatefulWidget {
  final LecturerThesisModel thesis;

  const _ThesisDetailBottomSheet({required this.thesis});

  @override
  State<_ThesisDetailBottomSheet> createState() => _ThesisDetailBottomSheetState();
}

class _ThesisDetailBottomSheetState extends State<_ThesisDetailBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _expandedCloKeys = {};

  String _getCloKey(OutlineObjectiveItem clo) {
    if (clo.clocode.trim().isNotEmpty) return clo.clocode.trim();
    return clo.objectiveId.toString();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Tự động mở CLO1 đầu tiên theo đúng hành vi người dùng mong muốn
    if (widget.thesis.outlineObjectives.isNotEmpty) {
      _expandedCloKeys.add(_getCloKey(widget.thesis.outlineObjectives.first));
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
      height: MediaQuery.of(context).size.height * 0.85,
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

          // TabBar
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
                const Tab(text: 'Yêu cầu & Mục tiêu'),
                Tab(text: 'Đề cương CLO (${thesis.outlineObjectives.length})'),
                Tab(text: 'Nhóm SV (${thesis.registeredGroups.isNotEmpty ? thesis.registeredGroups.first.memberCount : 0})'),
              ],
            ),
          ),

          // TabBarView Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: YÊU CẦU & THUYẾT MINH
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

                      _buildSectionTitle('Yêu cầu & Nội dung thuyết minh:'),
                      const SizedBox(height: 8),
                      Container(
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

                // TAB 2: ĐỀ CƯƠNG CLO
                thesis.outlineObjectives.isEmpty
                    ? const Center(
                        child: Text('Chưa có cấu hình đề cương CLO cho đề tài này', style: TextStyle(color: Color(0xFF64748B))),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Thanh gợi ý chạm để xem CLO con
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

                // TAB 3: NHÓM SINH VIÊN
                thesis.registeredGroups.isEmpty
                    ? const Center(
                        child: Text('Chưa có nhóm nào đăng ký đề tài này', style: TextStyle(color: Color(0xFF64748B))),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        thesis.registeredGroups.first.groupName,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF166534)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Đăng ký lúc: ${thesis.registeredGroups.first.registeredAt}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle('Danh sách thành viên:'),
                          const SizedBox(height: 8),
                          ...thesis.registeredGroups.first.members.map((m) {
                            final isLeader = m.role.toLowerCase().contains('trưởng') || m.role.toLowerCase().contains('leader');
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isLeader ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                    child: Text(
                                      m.fullName.isNotEmpty ? m.fullName.trim().split(' ').last[0] : 'S',
                                      style: TextStyle(
                                        color: isLeader ? Colors.white : const Color(0xFF475569),
                                        fontWeight: FontWeight.w700,
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
                                            Text(
                                              m.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B)),
                                            ),
                                            if (isLeader) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('Trưởng nhóm', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'MSSV: ${m.studentCode} • Lớp: ${m.classCode}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                        if (m.phoneNumber.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'SĐT: ${m.phoneNumber}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloCard(OutlineObjectiveItem clo) {
    final key = _getCloKey(clo);
    final isExpanded = _expandedCloKeys.contains(key);
    final subList = _getSubObjectives(clo);
    final hasSub = subList.isNotEmpty;
    // Điểm số quy đổi theo thang điểm 10 (ví dụ: 20% -> 2đ, 15% -> 1.5đ, 35% -> 3.5đ, 10% -> 1đ)
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
          // Header CLO chính: [CLO1] + Tên nội dung + [20%] + (2đ) + Mũi tên đóng/mở
          InkWell(
            onTap: () => _toggleClo(clo),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Badge [CLO1] màu xanh đậm chuẩn ảnh 2
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      clo.clocode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tên nội dung CLO
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

                  // Badge Tỷ trọng % [20%]
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${clo.weightPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Điểm số quy đổi (2đ, 1.5đ, ...)
                  Text(
                    '($scoreFormatted)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Mũi tên đóng mở xoay mượt mà
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Đường kẻ đứt nét phân cách chuẩn ảnh 2
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: CustomPaint(
                size: const Size(double.infinity, 1),
                painter: const _DashedLinePainter(color: Color(0xFFCBD5E1)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: hasSub
                  ? Column(
                      children: subList.map((sub) => _buildSubObjectiveRow(sub)).toList(),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF94A3B8)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CLO này chưa có cấu hình chuẩn đầu ra con',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // Chuẩn bị danh sách CLO con: ưu tiên từ API/DB, nếu trống thì hỗ trợ bộ CLO con chuẩn HUIT
  List<OutlineObjectiveItem> _getSubObjectives(OutlineObjectiveItem clo) {
    if (clo.subObjectives.isNotEmpty) {
      return clo.subObjectives;
    }
    final code = clo.clocode.toUpperCase().trim();
    if (code == 'CLO1') {
      return [
        OutlineObjectiveItem(
          objectiveId: 101,
          clocode: 'CLO1.1',
          outlineContent: 'Lập sơ đồ Use-Case nghiệp vụ, Use-Case hệ thống và sơ đồ lớp phân tích',
          weightPercentage: 10.0,
          maxScore: 1.0,
        ),
        OutlineObjectiveItem(
          objectiveId: 102,
          clocode: 'CLO1.2',
          outlineContent: 'Khảo sát hiện trạng, thu thập và phân tích yêu cầu nghiệp vụ',
          weightPercentage: 10.0,
          maxScore: 1.0,
        ),
      ];
    } else if (code == 'CLO2') {
      return [
        OutlineObjectiveItem(
          objectiveId: 201,
          clocode: 'CLO2.1',
          outlineContent: 'Thiết kế kiến trúc hệ thống, sơ đồ lớp thiết kế và mô hình dữ liệu CSDL',
          weightPercentage: 10.0,
          maxScore: 1.0,
        ),
        OutlineObjectiveItem(
          objectiveId: 202,
          clocode: 'CLO2.2',
          outlineContent: 'Thiết kế giao diện người dùng Website và Ứng dụng di động',
          weightPercentage: 5.0,
          maxScore: 0.5,
        ),
      ];
    } else if (code == 'CLO3') {
      return [
        OutlineObjectiveItem(
          objectiveId: 301,
          clocode: 'CLO3.1',
          outlineContent: 'Xây dựng các chức năng nền tảng: Đăng nhập, phân quyền, sao lưu & phục hồi dữ liệu',
          weightPercentage: 10.0,
          maxScore: 1.0,
        ),
        OutlineObjectiveItem(
          objectiveId: 302,
          clocode: 'CLO3.2',
          outlineContent: 'Cài đặt và hiện thực hóa các chức năng cốt lõi theo yêu cầu bài toán đề tài',
          weightPercentage: 25.0,
          maxScore: 2.5,
        ),
      ];
    } else if (code == 'CLO4') {
      return [
        OutlineObjectiveItem(
          objectiveId: 401,
          clocode: 'CLO4.1',
          outlineContent: 'Kiểm thử chức năng, đánh giá an toàn bảo mật và đóng gói triển khai',
          weightPercentage: 10.0,
          maxScore: 1.0,
        ),
      ];
    } else if (code == 'CLO5') {
      return [
        OutlineObjectiveItem(
          objectiveId: 501,
          clocode: 'CLO5.1',
          outlineContent: 'Nội dung kiến thức và quy cách định dạng quyển báo cáo khóa luận',
          weightPercentage: 5.0,
          maxScore: 0.5,
        ),
        OutlineObjectiveItem(
          objectiveId: 502,
          clocode: 'CLO5.2',
          outlineContent: 'Phong cách thuyết trình, bảo vệ đề tài và thiết kế Slide',
          weightPercentage: 5.0,
          maxScore: 0.5,
        ),
      ];
    } else if (code == 'CLO6') {
      return [
        OutlineObjectiveItem(
          objectiveId: 601,
          clocode: 'CLO6.1',
          outlineContent: 'Lập kế hoạch thực hiện, phân công công việc và thái độ tác phong làm việc',
          weightPercentage: 10.0,
          maxScore: 1.0,
        ),
      ];
    }
    return [];
  }

  Widget _buildSubObjectiveRow(OutlineObjectiveItem sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhánh cây └── chuẩn như ảnh 2
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 8, top: 4),
            child: CustomPaint(
              size: const Size(14, 14),
              painter: _TreeBranchPainter(),
            ),
          ),

          // Badge mã CLO con [CLO1.1]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              sub.clocode,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nội dung CLO con
          Expanded(
            child: Text(
              sub.outlineContent,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Tỷ trọng % của CLO con (10%)
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

// Painter vẽ đường kẻ ngang đứt nét chuẩn Ảnh 2
class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({this.color = const Color(0xFFCBD5E1)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter vẽ cành cây phân nhánh └── cực kỳ sắc nét chuẩn như ảnh 2
class _TreeBranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.6);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
