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

  // Mặc định ưu tiên vai trò Hướng dẫn (Supervisor)
  String _currentType = 'Supervisor'; // 'Supervisor' (Hướng dẫn) | 'Reviewer' (Phản biện)
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
          final codeMatch = t.thesisCode.toLowerCase().contains(q);
          final groupMatch = t.groupName.toLowerCase().contains(q);
          final studentMatch = t.students.any((s) =>
              s.studentName.toLowerCase().contains(q) ||
              s.studentCode.toLowerCase().contains(q));
          return titleMatch || codeMatch || groupMatch || studentMatch;
        }).toList();
      }
    });
  }

  void _openScoringDetail(ScoringThesisModel thesis, ScoringStudentModel student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerScoringDetailScreen(
          user: widget.user,
          thesis: thesis,
          initialStudent: student,
          evaluationType: _currentType,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = _currentType == 'Supervisor';
    final completedCount = _theses.where((t) => t.isCompleted).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING HEADER
            _buildFloatingHeader(),

            // 2. SEGMENTED TABS: HƯỚNG DẪN vs PHẢN BIỆN
            _buildSegmentedTabs(),

            // 3. STATS BAR & SEARCH BAR
            _buildSearchAndStatsBar(completedCount),

            // 4. DANH SÁCH ĐỀ TÀI CẦN CHẤM
            Expanded(
              child: _isLoading
                  ? Center(
                      child: HuitLoading(
                        size: 48,
                        message: isSupervisor
                            ? 'Đang tải danh sách đề tài hướng dẫn...'
                            : 'Đang tải danh sách đề tài phản biện...',
                      ),
                    )
                  : _filteredTheses.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF005BAC),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF004B87), Color(0xFF0284C7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF004B87).withOpacity(0.3),
              blurRadius: 10,
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
                'Nhập điểm phân công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
                label: 'Chấm Hướng dẫn (GVHD)',
                icon: Icons.school_rounded,
                isActive: _currentType == 'Supervisor',
                onTap: () => _switchType('Supervisor'),
              ),
            ),
            Expanded(
              child: _buildTabItem(
                label: 'Chấm Phản biện (GVPB)',
                icon: Icons.rate_review_rounded,
                isActive: _currentType == 'Reviewer',
                onTap: () => _switchType('Reviewer'),
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
              size: 16,
              color: isActive ? const Color(0xFF005BAC) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? const Color(0xFF005BAC) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndStatsBar(int completedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          // Ô Tìm kiếm
          Container(
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
                hintText: 'Tìm kiếm theo tên đề tài, mã, sinh viên, MSSV...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
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
          const SizedBox(height: 6),

          // Dòng thống kê ngắn
          Row(
            children: [
              Text(
                'Tổng số: ${_theses.length} đề tài',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: completedCount == _theses.length && _theses.isNotEmpty
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hoàn thành: $completedCount/${_theses.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: completedCount == _theses.length && _theses.isNotEmpty
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThesisCard(ScoringThesisModel thesis) {
    final isAllGraded = thesis.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAllGraded ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isAllGraded ? 1.5 : 1,
        ),
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
          // Header thẻ đề tài: Mã đề tài + Nhóm + Tiến độ chấm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge Mã đề tài
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004B87).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF004B87).withOpacity(0.2)),
                      ),
                      child: Text(
                        thesis.thesisCode,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF004B87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge Nhóm sinh viên
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.group_rounded, color: Color(0xFF475569), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            thesis.groupName,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Tag Tiến độ chấm
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAllGraded
                            ? const Color(0xFFDCFCE7)
                            : (thesis.gradedCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isAllGraded
                            ? 'Đã chấm đủ (${thesis.gradedCount}/${thesis.totalStudents})'
                            : (thesis.gradedCount > 0
                                ? 'Đang chấm (${thesis.gradedCount}/${thesis.totalStudents})'
                                : 'Chưa chấm (${thesis.totalStudents} SV)'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAllGraded
                              ? const Color(0xFF16A34A)
                              : (thesis.gradedCount > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tên đề tài
                Text(
                  thesis.thesisTitle,
                  style: const TextStyle(
                    fontSize: 14.5,
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
                final isGraded = student.isGraded;

                return InkWell(
                  onTap: () => _openScoringDetail(thesis, student),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: isGraded
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                          child: Icon(
                            student.isLeader ? Icons.star_rounded : Icons.person_rounded,
                            size: 19,
                            color: isGraded ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    student.studentName,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (student.isLeader) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE4E6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Trưởng nhóm',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (student.studentCode.isNotEmpty)
                                Text(
                                  'MSSV: ${student.studentCode}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Cột Điểm & Nút Hành Động
                        if (isGraded)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${student.totalScore.toStringAsFixed(1)}đ',
                                  style: const TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                student.rank,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005BAC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () => _openScoringDetail(thesis, student),
                            child: const Text(
                              'Chấm điểm',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSupervisor = _currentType == 'Supervisor';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSupervisor ? Icons.school_outlined : Icons.rate_review_outlined,
              size: 64,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              isSupervisor
                  ? 'Không có đề tài hướng dẫn cần chấm điểm'
                  : 'Không có đề tài phản biện cần chấm điểm',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Các đề tài được phân công chấm điểm theo đợt khóa luận sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
