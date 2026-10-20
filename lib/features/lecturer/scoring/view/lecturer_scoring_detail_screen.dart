import 'package:flutter/material.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/scoring_service.dart';
import '../model/scoring_model.dart';

class LecturerScoringDetailScreen extends StatefulWidget {
  final UserModel user;
  final ScoringThesisModel thesis;
  final ScoringStudentModel initialStudent;
  final String evaluationType; // 'Supervisor' | 'Reviewer'

  const LecturerScoringDetailScreen({
    super.key,
    required this.user,
    required this.thesis,
    required this.initialStudent,
    required this.evaluationType,
  });

  @override
  State<LecturerScoringDetailScreen> createState() => _LecturerScoringDetailScreenState();
}

class _LecturerScoringDetailScreenState extends State<LecturerScoringDetailScreen> {
  final ScoringService _service = ScoringService();

  late ScoringStudentModel _activeStudent;
  List<ObjectiveScoreModel> _objectives = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEligibleForDefense = true;

  // Controllers lưu điểm & nhận xét theo objectiveId
  final Map<int, TextEditingController> _scoreControllers = {};
  final Map<int, TextEditingController> _commentControllers = {};
  final TextEditingController _generalCommentController = TextEditingController();

  // Cache điểm của các sinh viên trong nhóm khi chuyển tab
  final Map<int, List<ObjectiveScoreModel>> _cachedObjectivesByStudent = {};

  @override
  void initState() {
    super.initState();
    _activeStudent = widget.initialStudent;
    _loadObjectivesForStudent(_activeStudent);
  }

  @override
  void dispose() {
    _disposeControllers();
    _generalCommentController.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    for (var c in _scoreControllers.values) {
      c.dispose();
    }
    _scoreControllers.clear();
    for (var c in _commentControllers.values) {
      c.dispose();
    }
    _commentControllers.clear();
  }

  Future<void> _loadObjectivesForStudent(ScoringStudentModel student) async {
    setState(() => _isLoading = true);

    // Kiểm tra cache trước
    if (_cachedObjectivesByStudent.containsKey(student.studentId)) {
      _applyLoadedObjectives(_cachedObjectivesByStudent[student.studentId]!);
      setState(() => _isLoading = false);
      return;
    }

    final data = await _service.getObjectivesForScoring(
      thesisId: widget.thesis.thesisId,
      studentId: student.studentId,
      evaluationType: widget.evaluationType,
    );

    _cachedObjectivesByStudent[student.studentId] = data;
    _applyLoadedObjectives(data);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _applyLoadedObjectives(List<ObjectiveScoreModel> list) {
    _disposeControllers();
    _objectives = list;

    for (var obj in _objectives) {
      _scoreControllers[obj.objectiveId] = TextEditingController(
        text: obj.score > 0
            ? (obj.score % 1 == 0 ? obj.score.toInt().toString() : obj.score.toStringAsFixed(2))
            : '0',
      );
      _commentControllers[obj.objectiveId] = TextEditingController(
        text: obj.comments,
      );
    }

    // Tự động suy ra điều kiện bảo vệ dựa trên điểm
    _isEligibleForDefense = _calculatedTotalScore >= 5.0;
  }

  void _switchStudent(ScoringStudentModel student) {
    if (_activeStudent.studentId == student.studentId) return;

    // Lưu các comment của sinh viên hiện tại vào cache
    _syncCurrentFormToCache();

    setState(() {
      _activeStudent = student;
    });

    _loadObjectivesForStudent(student);
  }

  void _syncCurrentFormToCache() {
    for (var obj in _objectives) {
      obj.comments = _commentControllers[obj.objectiveId]?.text.trim() ?? '';
    }
    _cachedObjectivesByStudent[_activeStudent.studentId] = _objectives;
  }

  double get _calculatedTotalScore {
    final sum = _objectives.fold(0.0, (acc, o) => acc + o.score);
    return double.parse(sum.toStringAsFixed(2));
  }

  double get _totalMaxScore {
    final max = _objectives.fold(0.0, (acc, o) => acc + o.maxScore);
    return max > 0 ? double.parse(max.toStringAsFixed(2)) : 10.0;
  }

  String get _currentRank {
    final score = _calculatedTotalScore;
    if (score >= 9.0) return 'Xuất sắc';
    if (score >= 8.0) return 'Giỏi';
    if (score >= 6.5) return 'Khá';
    if (score >= 5.0) return 'Trung bình';
    return 'Yếu';
  }

  Color get _currentRankColor {
    final score = _calculatedTotalScore;
    if (score >= 9.0) return const Color(0xFF16A34A);
    if (score >= 8.0) return const Color(0xFF0D9488);
    if (score >= 6.5) return const Color(0xFF2563EB);
    if (score >= 5.0) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  void _onScoreChanged(ObjectiveScoreModel obj, double newScore) {
    setState(() {
      double clamped = newScore.clamp(0.0, obj.maxScore);
      obj.score = double.parse(clamped.toStringAsFixed(2));
      _scoreControllers[obj.objectiveId]?.text = obj.score % 1 == 0
          ? obj.score.toInt().toString()
          : obj.score.toStringAsFixed(2);

      _isEligibleForDefense = _calculatedTotalScore >= 5.0;
    });
  }

  // --- TIỆN ÍCH 1: SINH ĐIỂM NGẪU NHIÊN TEST ---
  void _randomizeScores() {
    setState(() {
      for (var obj in _objectives) {
        final max = obj.maxScore;
        final min = max * 0.70; // 70% - 100%
        final steps = ((max - min) / 0.05).floor();
        final randomStep = (DateTime.now().microsecondsSinceEpoch % (steps + 1));
        final generated = min + (randomStep * 0.05);
        final clamped = double.parse(generated.clamp(0.0, max).toStringAsFixed(2));

        obj.score = clamped;
        _scoreControllers[obj.objectiveId]?.text = clamped % 1 == 0
            ? clamped.toInt().toString()
            : clamped.toStringAsFixed(2);
      }
      _isEligibleForDefense = _calculatedTotalScore >= 5.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        content: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Đã tạo ngẫu nhiên điểm hợp lệ cho sinh viên này!'),
          ],
        ),
      ),
    );
  }

  // --- TIỆN ÍCH 2: SAO CHÉP ĐIỂM CHO THÀNH VIÊN KHÁC TRONG NHÓM ---
  void _showCopyScoresDialog() {
    final otherStudents = widget.thesis.students
        .where((s) => s.studentId != _activeStudent.studentId)
        .toList();

    if (otherStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đề tài này chỉ có 1 sinh viên, không thể sao chép!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Color(0xFF0F766E)),
            const SizedBox(width: 8),
            const Text(
              'Sao chép điểm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Áp dụng toàn bộ điểm CLO (${_calculatedTotalScore.toStringAsFixed(2)}đ) của "${_activeStudent.studentName}" cho các bạn cùng nhóm:',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            ...otherStudents.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      if (s.isLeader)
                        const Text(
                          'Trưởng nhóm',
                          style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeCopyScoresToAll(otherStudents);
            },
            child: const Text('Sao chép tất cả', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _executeCopyScoresToAll(List<ScoringStudentModel> targets) {
    for (var target in targets) {
      final copied = _objectives.map((o) => o.copy()).toList();
      _cachedObjectivesByStudent[target.studentId] = copied;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text('Đã sao chép điểm thành công cho ${targets.length} thành viên cùng nhóm!'),
      ),
    );
  }

  // --- LƯU ĐIỂM LÊN SERVER ---
  Future<void> _handleSave() async {
    for (var obj in _objectives) {
      obj.comments = _commentControllers[obj.objectiveId]?.text.trim() ?? '';
    }

    setState(() => _isSaving = true);

    final success = await _service.saveScores(
      thesisId: widget.thesis.thesisId,
      studentId: _activeStudent.studentId,
      evaluationType: widget.evaluationType,
      objectives: _objectives,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // Cập nhật lại trạng thái local của student
        final updatedStudent = _activeStudent.copyWith(
          isGraded: true,
          totalScore: _calculatedTotalScore,
        );
        setState(() {
          _activeStudent = updatedStudent;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã lưu thành công điểm ${_calculatedTotalScore.toStringAsFixed(2)}đ ($_currentRank) cho ${_activeStudent.studentName}!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Lỗi lưu điểm. Vui lòng kiểm tra lại kết nối mạng!'),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = widget.evaluationType == 'Supervisor';
    final roleTitle = isSupervisor ? 'Chấm điểm Hướng dẫn (GVHD)' : 'Chấm điểm Phản biện (GVPB)';
    final primaryGradient = isSupervisor
        ? const [Color(0xFF005BAC), Color(0xFF0284C7)]
        : const [Color(0xFFC2410C), Color(0xFFEA580C)];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING HEADER
            _buildFloatingHeader(roleTitle, primaryGradient),

            // 2. HORIZONTAL MEMBER TABS: Chuyển đổi sinh viên trong nhóm
            _buildMemberSelectorTabs(),

            // 3. THANH CÔNG CỤ TIỆN ÍCH (Sinh điểm mẫu / Sao chép điểm)
            _buildQuickActionToolbar(),

            // 4. DANH SÁCH TIÊU CHÍ CHUẨN ĐẦU RA (CLO)
            Expanded(
              child: _isLoading
                  ? const Center(child: HuitLoading(size: 44, message: 'Đang tải tiêu chí đề cương CLO...'))
                  : _objectives.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
                          itemCount: _objectives.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildObjectiveCard(_objectives[index], index + 1);
                          },
                        ),
            ),
          ],
        ),
      ),
      // 5. BOTTOM BAR CỐ ĐỊNH: TỔNG ĐIỂM + XẾP LOẠI + NÚT LƯU
      bottomSheet: _isLoading || _objectives.isEmpty ? null : _buildBottomScoreBar(),
    );
  }

  Widget _buildFloatingHeader(String title, List<Color> gradientColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context, true),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${widget.thesis.thesisCode} - ${widget.thesis.groupName}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48), // Cân đối nút back
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelectorTabs() {
    final students = widget.thesis.students;
    if (students.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: students.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final student = students[index];
          final isSelected = student.studentId == _activeStudent.studentId;

          return GestureDetector(
            onTap: () => _switchStudent(student),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF005BAC) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF005BAC) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF005BAC).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : (student.isGraded ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                    child: Icon(
                      student.isLeader ? Icons.star_rounded : Icons.person_rounded,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (student.isGraded ? const Color(0xFF16A34A) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            student.studentName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          if (student.isLeader) ...[
                            const SizedBox(width: 3),
                            Text(
                              '*',
                              style: TextStyle(
                                color: isSelected ? Colors.yellowAccent : const Color(0xFFE11D48),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        student.isGraded
                            ? 'Điểm: ${student.totalScore.toStringAsFixed(1)}đ (${student.rank})'
                            : 'Chưa có điểm',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withOpacity(0.85)
                              : (student.isGraded ? const Color(0xFF16A34A) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Nút Điểm ngẫu nhiên (Test demo)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD97706),
              side: const BorderSide(color: Color(0xFFFDE68A)),
              backgroundColor: const Color(0xFFFEF3C7).withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 15),
            label: const Text('Điểm mẫu (Test)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _objectives.isEmpty ? null : _randomizeScores,
          ),
          const SizedBox(width: 8),

          // Nút Sao chép điểm cho bạn cùng nhóm
          if (widget.thesis.students.length > 1)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF99F6E4)),
                backgroundColor: const Color(0xFFCCFBF1).withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Sao chép cả nhóm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: _objectives.isEmpty ? null : _showCopyScoresDialog,
            ),
          const Spacer(),

          // Thông báo số lượng tiêu chí CLO
          Text(
            '${_objectives.length} tiêu chí CLO',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveCard(ObjectiveScoreModel obj, int index) {
    final scoreCtrl = _scoreControllers[obj.objectiveId];
    final commentCtrl = _commentControllers[obj.objectiveId];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Mã CLO + Tên Tiêu chí + Điểm Tối đa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  obj.clocode.isNotEmpty ? obj.clocode : 'CLO$index',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  obj.outlineContent,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Tối đa: ${obj.maxScore.toStringAsFixed(1)}đ',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dòng 2: Bộ điều khiển điểm (Quick Buttons + Stepper + Input)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Các chip chọn nhanh: 0đ, 50%, 75%, Max
                Wrap(
                  spacing: 4,
                  children: [
                    _buildQuickScoreChip('0đ', 0.0, obj),
                    _buildQuickScoreChip('50%', obj.maxScore * 0.5, obj),
                    _buildQuickScoreChip('80%', obj.maxScore * 0.8, obj),
                    _buildQuickScoreChip('Max', obj.maxScore, obj),
                  ],
                ),
                const Spacer(),

                // Nút giảm 0.25
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: obj.score <= 0 ? null : () => _onScoreChanged(obj, obj.score - 0.25),
                ),
                const SizedBox(width: 6),

                // Ô nhập điểm
                Container(
                  width: 54,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    controller: scoreCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF005BAC),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      _onScoreChanged(obj, parsed);
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // Nút tăng 0.25
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: obj.score >= obj.maxScore ? null : () => _onScoreChanged(obj, obj.score + 0.25),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Dòng 3: Ô nhận xét của tiêu chí
          TextField(
            controller: commentCtrl,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
            decoration: InputDecoration(
              hintText: 'Nhận xét tiêu chí này (tùy chọn)...',
              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.comment_outlined, size: 15, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF005BAC)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickScoreChip(String label, double value, ObjectiveScoreModel obj) {
    final roundedVal = double.parse(value.toStringAsFixed(2));
    final isCurrent = (obj.score - roundedVal).abs() < 0.01;

    return InkWell(
      onTap: () => _onScoreChanged(obj, roundedVal),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF005BAC) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? const Color(0xFF005BAC) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isCurrent ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomScoreBar() {
    final total = _calculatedTotalScore;
    final max = _totalMaxScore;
    final rank = _currentRank;
    final rankColor = _currentRankColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dòng xác nhận Đủ điều kiện bảo vệ (Dành cho GVHD / GVPB)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _isEligibleForDefense ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isEligibleForDefense ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEligibleForDefense ? Icons.verified_rounded : Icons.cancel_rounded,
                    size: 16,
                    color: _isEligibleForDefense ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isEligibleForDefense
                          ? 'Đủ điều kiện nộp phản biện & ra bảo vệ (>= 5.0đ)'
                          : 'Chưa đủ điều kiện bảo vệ (< 5.0đ)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _isEligibleForDefense ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _isEligibleForDefense,
                      activeColor: const Color(0xFF16A34A),
                      onChanged: (val) {
                        setState(() {
                          _isEligibleForDefense = val;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            // Dòng thông tin Tổng điểm & Xếp loại
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG ĐIỂM CHẤM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          total.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: rankColor,
                          ),
                        ),
                        Text(
                          ' / ${max.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: rankColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    rank,
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),

                // Nút Lưu Điểm
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005BAC),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'Lưu điểm',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 56, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            const Text(
              'Đề tài chưa có đề cương CLO',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vui lòng cập nhật đề cương chuẩn đầu ra của đề tài trên Web trước khi thực hiện chấm điểm.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
