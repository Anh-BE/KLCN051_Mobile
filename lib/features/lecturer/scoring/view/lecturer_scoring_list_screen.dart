import 'package:flutter/material.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/scoring_service.dart';
import '../model/scoring_model.dart';
import 'lecturer_scoring_detail_screen.dart';

class LecturerScoringListScreen extends StatefulWidget {
  final UserModel user;

  const LecturerScoringListScreen({super.key, required this.user});

  @override
  State<LecturerScoringListScreen> createState() => _LecturerScoringListScreenState();
}

class _LecturerScoringListScreenState extends State<LecturerScoringListScreen> {
  final ScoringService _service = ScoringService();
  final TextEditingController _searchController = TextEditingController();

  String _currentType = 'Reviewer'; // 'Reviewer' (Phản biện) | 'Supervisor' (Hướng dẫn)
  List<ScoringThesisModel> _theses = [];
  List<ScoringThesisModel> _filteredTheses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _service.getThesesForScoring(_currentType);
    if (mounted) {
      setState(() {
        _theses = list;
        _applySearch(_searchController.text);
        _isLoading = false;
      });
    }
  }

  void _switchType(String type) {
    if (_currentType != type) {
      setState(() {
        _currentType = type;
      });
      _loadData();
    }
  }

  void _applySearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredTheses = List.from(_theses);
      } else {
        _filteredTheses = _theses.where((t) {
          final titleMatch = t.thesisTitle.toLowerCase().contains(q);
          final groupMatch = t.groupName.toLowerCase().contains(q);
          final studentMatch = t.students.any((s) => s.studentName.toLowerCase().contains(q));
          return titleMatch || groupMatch || studentMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isReviewer = _currentType == 'Reviewer';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING HEADER
            _buildFloatingHeader(),

            // 2. SEGMENTED TABS: PHẢN BIỆN vs HƯỚNG DẪN
            _buildSegmentedTabs(),

            // 3. SEARCH BAR
            _buildSearchBar(),

            // 4. DANH SÁCH ĐỀ TÀI CẦN CHẤM
            Expanded(
              child: _isLoading
                  ? Center(
                      child: HuitLoading(
                        size: 48,
                        message: isReviewer
                            ? 'Đang tải danh sách đề tài phản biện...'
                            : 'Đang tải danh sách đề tài hướng dẫn...',
                      ),
                    )
                  : _filteredTheses.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
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
              color: const Color(0xFF0D9488).withOpacity(0.3),
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
            ),
            const Expanded(
              child: Text(
                'Nhập điểm được phân công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              onPressed: _loadData,
              tooltip: 'Làm mới',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabItem(
                label: 'Chấm Phản biện',
                icon: Icons.rate_review_rounded,
                isActive: _currentType == 'Reviewer',
                onTap: () => _switchType('Reviewer'),
              ),
            ),
            Expanded(
              child: _buildTabItem(
                label: 'Chấm Hướng dẫn',
                icon: Icons.school_rounded,
                isActive: _currentType == 'Supervisor',
                onTap: () => _switchType('Supervisor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? const Color(0xFF0F766E) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _applySearch,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: 'Tìm theo tên đề tài, nhóm, sinh viên...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      _applySearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildThesisCard(ScoringThesisModel thesis) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header thẻ đề tài: Nhóm + Tên đề tài
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.group_rounded, color: Color(0xFF1D4ED8), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            thesis.groupName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${thesis.students.length} sinh viên',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  thesis.thesisTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Danh sách các sinh viên trong nhóm
          if (thesis.students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có sinh viên nào trong nhóm này.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: thesis.students.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF8FAFC)),
              itemBuilder: (context, index) {
                final student = thesis.students[index];
                final isGraded = student.totalScore > 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: isGraded
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        child: Icon(
                          Icons.person,
                          size: 19,
                          color: isGraded ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.studentName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            isGraded
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Đã chấm: ${student.totalScore.toStringAsFixed(1)}đ',
                                          style: const TextStyle(
                                            color: Color(0xFF16A34A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Chưa chấm',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      // Nút Chấm điểm / Sửa điểm
                      ElevatedButton(
                        onPressed: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LecturerScoringDetailScreen(
                                user: widget.user,
                                thesis: thesis,
                                student: student,
                                evaluationType: _currentType,
                              ),
                            ),
                          );
                          if (updated == true) {
                            _loadData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGraded ? const Color(0xFFF0FDF4) : const Color(0xFF0F766E),
                          foregroundColor: isGraded ? const Color(0xFF16A34A) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isGraded ? const Color(0xFFBBF7D0) : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGraded ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isGraded ? 'Sửa điểm' : 'Nhập điểm',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isReviewer = _currentType == 'Reviewer';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReviewer ? Icons.rate_review_outlined : Icons.school_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              isReviewer
                  ? 'Chưa có đề tài phân công phản biện'
                  : 'Chưa có đề tài hướng dẫn được duyệt',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isReviewer
                  ? 'Khi Bộ môn / Khoa phân công Thầy/Cô làm Giảng viên phản biện, danh sách đề tài sẽ xuất hiện tại đây.'
                  : 'Các đề tài do Thầy/Cô hướng dẫn đã được duyệt và có nhóm sinh viên sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
