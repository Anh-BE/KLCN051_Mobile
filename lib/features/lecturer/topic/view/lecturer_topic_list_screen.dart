import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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

  /// Khởi tạo dữ liệu từ CSDL thật: Tải dữ liệu ngay lập tức, tự động chọn đợt có đề tài hoặc "Tất cả đợt"
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final periods = await _service.getPeriods();

    // Tải toàn bộ đề tài của giảng viên trước (periodId = null) để luôn có dữ liệu hiển thị từ CSDL
    final data = await _service.getTheses(
      periodId: null,
      statusFilter: 'all',
      searchQuery: null,
    );

    // Nếu đợt mới nhất có đề tài thì chọn đợt mới nhất; nếu đợt mới nhất chưa có đề tài thì mặc định "Tất cả đợt" (null) để người dùng thấy ngay danh sách đề tài
    int? initialPeriodId;
    if (periods.isNotEmpty) {
      final latestId = periods.first['periodId'] as int?;
      if (latestId != null && data.any((t) => t.periodId == latestId)) {
        initialPeriodId = latestId;
      }
    }

    if (mounted) {
      setState(() {
        _periods = periods;
        _selectedPeriodId = initialPeriodId;
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

    // Lọc theo đợt nếu người dùng đang chọn 1 đợt cụ thể
    if (_selectedPeriodId != null) {
      filtered = filtered.where((t) => t.periodId == _selectedPeriodId).toList();
    }

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

                // 2. FORM BỘ LỌC CHUẨN UI/UX (TÌM KIẾM, ĐỢT & TRẠNG THÁI)
                _buildFilterForm(colors),

                const SizedBox(height: 4),

                // 3. DANH SÁCH ĐỀ TÀI & TRẠNG THÁI (Chỉ chứa đề tài, không hiển thị nhóm)
                Expanded(
                  child: _isLoading
                      ? const Center(child: HuitLoading(size: 48, message: 'Đang tải danh sách đề tài...'))
                      : _theses.isEmpty
                          ? _buildEmptyState(colors)
                          : RefreshIndicator(
                              onRefresh: _refreshList,
                              color: const Color(0xFF0072E8),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _theses.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  return _buildThesisCard(_theses[index], colors);
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

  // 1. Floating Pill Header (Căn giữa tiêu đề, đã xóa icon load theo yêu cầu)
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
                'ĐỀ TÀI & TRẠNG THÁI ĐỀ XUẤT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            // Cân đối với nút back bên trái để tiêu đề nằm chính giữa (đã xóa icon load theo yêu cầu)
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // 2. Form bộ lọc chuẩn UI/UX: Ô tìm kiếm 100% full width + 2 Dropdown lọc (Đợt & Trạng thái) cân đối
  Widget _buildFilterForm(AppColors colors) {
    final list = _allTheses;
    final approvedCount = list.where((t) => _isStatusMatch(t.status, 'Approved')).length;
    final pendingCount = list.where((t) => _isStatusMatch(t.status, 'Pending')).length;
    final rejectedCount = list.where((t) => _isStatusMatch(t.status, 'Rejected')).length;
    final isFiltered = _searchController.text.trim().isNotEmpty ||
        _selectedPeriodId != null ||
        _selectedStatus != 'all';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ô tìm kiếm toàn diện 100% bề ngang (không bị Dropdown chèn ép)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã đề tài...',
                hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0072E8), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // 2. Hai ô Form lọc chuẩn: Đợt khóa luận & Trạng thái đề tài
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Dropdown 1: Đợt khóa luận
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedPeriodId != null
                          ? const Color(0xFF0072E8)
                          : colors.cardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedPeriodId,
                      isExpanded: true,
                      dropdownColor: colors.cardBg,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colors.textSecondary),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: colors.textPrimary),
                      onChanged: (val) {
                        setState(() {
                          _selectedPeriodId = val;
                          _selectedStatus = 'all';
                        });
                        _refreshList();
                      },
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Row(
                            children: [
                              const Icon(Icons.event_note_rounded, size: 16, color: Color(0xFF0072E8)),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text('Tất cả đợt', maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        if (_periods.isNotEmpty)
                          ..._periods.where((p) => p['periodId'] != null).map((p) {
                            final rawName = (p['periodName'] ?? 'Đợt khóa luận').toString();
                            final shortName = rawName
                                .replaceAll('Khóa luận tốt nghiệp ', 'KLTN ')
                                .replaceAll('Khóa luận ', 'KL ');
                            return DropdownMenuItem<int?>(
                              value: p['periodId'] as int,
                              child: Row(
                                children: [
                                  const Icon(Icons.event_note_rounded, size: 16, color: Color(0xFF0072E8)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(shortName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Dropdown 2: Trạng thái đề tài
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedStatus != 'all'
                          ? const Color(0xFF0072E8)
                          : colors.cardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      dropdownColor: colors.cardBg,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colors.textSecondary),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: colors.textPrimary),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _applyFilter();
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả (${list.length})', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'Approved',
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text('Đã duyệt ($approvedCount)', maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text('Chờ duyệt ($pendingCount)', maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Rejected',
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Flexible(
                                child: Text('Từ chối ($rejectedCount)', maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Dòng thống kê số lượng đề tài & Nút đặt lại bộ lọc
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_theses.length} đề tài',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              if (isFiltered)
                InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _selectedPeriodId = null;
                      _selectedStatus = 'all';
                    });
                    _refreshList();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFF0072E8)),
                        const SizedBox(width: 4),
                        Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0072E8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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

  // 3. Thẻ Đề tài chi tiết: CHỈ CHỨA ĐỀ TÀI, BỎ MỤC NHÓM ĐĂNG KÝ
  Widget _buildThesisCard(LecturerThesisModel thesis, AppColors colors) {
    final (statusBg, statusTextColor, statusText, statusIcon) = _getThesisStatusMeta(thesis.status);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header của Card: Mã đề tài + Tên đợt + Badge trạng thái
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider, width: 1.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    thesis.periodCode.isNotEmpty ? thesis.periodCode : 'DT${thesis.thesisId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0072E8),
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
                if (statusText == 'ĐÃ DUYỆT') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: thesis.hasGroup
                          ? (colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                          : (colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: thesis.hasGroup
                            ? (colors.isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE))
                            : (colors.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          thesis.hasGroup ? Icons.groups_rounded : Icons.group_off_outlined,
                          size: 12,
                          color: thesis.hasGroup
                              ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          thesis.hasGroup ? 'Có nhóm' : 'Chưa có nhóm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: thesis.hasGroup
                                ? (colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8))
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
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
                      textColor: const Color(0xFF0072E8),
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

                // NÚT XEM CHI TIẾT ĐỀ TÀI: Mở 3 mục (Thông tin đề tài, Bảng CLO, Bảng báo cáo tiến độ tuần)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openThesisDetailSheet(thesis),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text(
                      'Xem chi tiết đề tài',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0072E8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      shadowColor: const Color(0xFF0072E8).withValues(alpha: 0.28),
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

  Widget _buildEmptyState(AppColors colors) {
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
                color: colors.cardBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.folder_off_outlined, color: Color(0xFF94A3B8), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              hasPeriod ? 'Đợt này chưa có đề tài' : 'Không tìm thấy đề tài nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              hasPeriod
                  ? 'Đợt bạn chọn hiện chưa có đề tài nào được phân công hoặc tạo mới. Bạn có thể chọn "Tất cả đợt" bằng bộ lọc ở trên.'
                  : 'Vui lòng thử thay đổi từ khóa tìm kiếm hoặc bộ lọc trạng thái.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
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
                  backgroundColor: const Color(0xFF0072E8),
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
// 3. BẢNG BÁO CÁO TIẾN ĐỘ TUẦN (CHỈ HIỂN THỊ NỘI DUNG THÔNG TIN KẾ HOẠCH CÁC TUẦN)
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
  final LecturerTopicService _service = LecturerTopicService();

  List<Map<String, dynamic>> _weeklyPlans = [];
  bool _isLoadingPlans = true;

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
    _loadWeeklyPlans();
  }

  /// Tải nội dung kế hoạch các tuần của đề tài từ CSDL thật
  Future<void> _loadWeeklyPlans() async {
    setState(() => _isLoadingPlans = true);
    final data = await _service.getThesisWeeklyPlans(widget.thesis.thesisId);
    if (mounted) {
      setState(() {
        _weeklyPlans = data;
        _isLoadingPlans = false;
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
    final colors = AppColors.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                color: colors.divider,
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0072E8)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        thesis.thesisTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // TabBar: ĐÚNG 3 MỤC THEO YÊU CẦU
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0072E8),
              unselectedLabelColor: colors.textSecondary,
              indicatorColor: const Color(0xFF0072E8),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
                      _buildSectionTitle('Định hướng nghiên cứu:', colors),
                      const SizedBox(height: 4),
                      Text(thesis.thesisType, style: TextStyle(fontSize: 14, color: colors.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 18),

                      _buildSectionTitle('Đợt khóa luận:', colors),
                      const SizedBox(height: 4),
                      Text(thesis.periodName, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
                      const SizedBox(height: 18),

                      _buildSectionTitle('Giảng viên hướng dẫn:', colors),
                      const SizedBox(height: 4),
                      Text(
                        thesis.gvhd.isNotEmpty ? thesis.gvhd : 'Giảng viên đề xuất',
                        style: TextStyle(fontSize: 14, color: colors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 18),

                      _buildSectionTitle('Yêu cầu & Nội dung thuyết minh:', colors),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.subCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.subCardBorder),
                        ),
                        child: Text(
                          thesis.requirements.isNotEmpty ? thesis.requirements : 'Chưa có yêu cầu chi tiết.',
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: colors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 18),

                      _buildSectionTitle('Nhóm sinh viên thực hiện:', colors),
                      const SizedBox(height: 8),
                      _buildGroupDetailBox(thesis, colors),
                    ],
                  ),
                ),

                // TAB 2: BẢNG CLO (CHUẨN ĐẦU RA)
                thesis.outlineObjectives.isEmpty
                    ? Center(
                        child: Text('Chưa có cấu hình đề cương CLO cho đề tài này', style: TextStyle(color: colors.textSecondary)),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: colors.isDark ? const Color(0xFF143022) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.isDark ? const Color(0xFF1B4D36) : const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Chạm vào từng CLO để xem danh sách chuẩn đầu ra con (CLO con)',
                                    style: TextStyle(fontSize: 12, color: colors.isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...thesis.outlineObjectives.map((clo) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCloCard(clo, colors),
                              )),
                        ],
                      ),

                // TAB 3: BẢNG BÁO CÁO TIẾN ĐỘ TUẦN (CHỈ HIỂN THỊ NỘI DUNG THÔNG TIN)
                _buildWeeklyReportTableTab(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: BẢNG BÁO CÁO TIẾN ĐỘ TUẦN - CHỈ HIỂN THỊ NỘI DUNG THÔNG TIN KẾ HOẠCH
  Widget _buildWeeklyReportTableTab(AppColors colors) {
    if (_isLoadingPlans) {
      return const Center(
        child: HuitLoading(size: 44, message: 'Đang tải bảng báo cáo tiến độ tuần...'),
      );
    }

    if (_weeklyPlans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.subCardBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 44),
              ),
              const SizedBox(height: 14),
              Text(
                'Chưa có kế hoạch nội dung tuần',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Đề tài chưa được thiết lập danh mục nội dung các tuần trong hệ thống.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Thẻ giới thiệu trang nhã
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.subCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.subCardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0072E8), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KẾ HOẠCH NỘI DUNG CÁC TUẦN',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lộ trình ${_weeklyPlans.length} tuần do Giảng viên xây dựng cho đề tài',
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildSectionTitle('NỘI DUNG CÔNG VIỆC THEO TUẦN:', colors),
        const SizedBox(height: 10),

        // Danh sách các tuần: CHỈ HIỂN THỊ NỘI DUNG THÔNG TIN
        ..._weeklyPlans.map((plan) {
          final weekNum = plan['weekNumber'] ?? plan['WeekNumber'] ?? 0;
          final title = (plan['title'] ?? plan['Title'] ?? '').toString();
          final reqs = (plan['detailedRequirements'] ?? plan['DetailedRequirements'] ?? '').toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.subCardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02),
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Tuần ${weekNum.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0072E8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title.isNotEmpty ? title : 'Nội dung thực hiện Tuần $weekNum',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    height: 1.35,
                  ),
                ),
                if (reqs.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.subCardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.subCardBorder),
                    ),
                    child: Text(
                      reqs,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCloCard(OutlineObjectiveItem clo, AppColors colors) {
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
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? const Color(0xFF2563EB).withValues(alpha: 0.35) : colors.subCardBorder,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? const Color(0xFF2563EB).withValues(alpha: 0.05) : Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02),
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
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
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
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isExpanded && hasSub) ...[
            Container(
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(top: BorderSide(color: colors.subCardBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Danh sách chuẩn đầu ra chi tiết (CLO con):',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  ...subList.map((sub) => _buildSubCloItem(sub, colors)),
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

  Widget _buildSubCloItem(OutlineObjectiveItem sub, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sub.clocode.isNotEmpty ? sub.clocode : '•',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Text(
              sub.outlineContent,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textPrimary,
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

  Widget _buildGroupDetailBox(LecturerThesisModel thesis, AppColors colors) {
    if (!thesis.hasGroup) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.subCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.subCardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group_off_outlined, color: Color(0xFF94A3B8), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có nhóm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đề tài này hiện chưa có nhóm sinh viên nào đăng ký.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final group = thesis.registeredGroups.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: Color(0xFF0072E8), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tên nhóm:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                    ),
                    Text(
                      group.groupName.isNotEmpty ? group.groupName : 'Nhóm sinh viên thực hiện',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Có nhóm',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0072E8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 10),
          const Text(
            'Thành viên nhóm:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          if (group.members.isNotEmpty)
            ...group.members.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF0072E8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.fullName.isNotEmpty ? m.fullName : (m.studentCode.isNotEmpty ? m.studentCode : 'Sinh viên'),
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: colors.textPrimary),
                        ),
                      ),
                      if (m.role.isNotEmpty)
                        Text(
                          m.role,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                    ],
                  ),
                ))
          else
            Text(
              'Đã có nhóm sinh viên đăng ký.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, [AppColors? colors]) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors?.sectionTitle ?? const Color(0xFF64748B),
      ),
    );
  }
}
