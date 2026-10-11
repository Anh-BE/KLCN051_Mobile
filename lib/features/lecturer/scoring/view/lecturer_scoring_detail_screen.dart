import 'package:flutter/material.dart';
import '../../../../core/widgets/huit_loading.dart';
import '../../../auth/model/user_model.dart';
import '../logic/scoring_service.dart';
import '../model/scoring_model.dart';

class LecturerScoringDetailScreen extends StatefulWidget {
  final UserModel user;
  final ScoringThesisModel thesis;
  final ScoringStudentModel student;
  final String evaluationType; // 'Reviewer' | 'Supervisor'

  const LecturerScoringDetailScreen({
    super.key,
    required this.user,
    required this.thesis,
    required this.student,
    required this.evaluationType,
  });

  @override
  State<LecturerScoringDetailScreen> createState() => _LecturerScoringDetailScreenState();
}

class _LecturerScoringDetailScreenState extends State<LecturerScoringDetailScreen> {
  final ScoringService _service = ScoringService();

  List<ObjectiveScoreModel> _objectives = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<int, TextEditingController> _commentControllers = {};
  final Map<int, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    _loadObjectives();
  }

  @override
  void dispose() {
    for (var c in _commentControllers.values) {
      c.dispose();
    }
    for (var c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadObjectives() async {
    setState(() => _isLoading = true);
    final data = await _service.getObjectivesForScoring(
      thesisId: widget.thesis.thesisId,
      studentId: widget.student.studentId,
      evaluationType: widget.evaluationType,
    );

    for (var obj in data) {
      _scoreControllers[obj.objectiveId] = TextEditingController(
        text: obj.score > 0 ? obj.score.toStringAsFixed(1) : '0',
      );
      _commentControllers[obj.objectiveId] = TextEditingController(
        text: obj.comments,
      );
    }

    if (mounted) {
      setState(() {
        _objectives = data;
        _isLoading = false;
      });
    }
  }

  double get _calculatedTotalScore {
    return _objectives.fold(0.0, (sum, o) => sum + o.score);
  }

  double get _totalMaxScore {
    final max = _objectives.fold(0.0, (sum, o) => sum + o.maxScore);
    return max > 0 ? max : 10.0;
  }

  void _onScoreChanged(ObjectiveScoreModel obj, double newScore) {
    setState(() {
      double clamped = newScore.clamp(0.0, obj.maxScore);
      obj.score = double.parse(clamped.toStringAsFixed(2));
      _scoreControllers[obj.objectiveId]?.text = obj.score % 1 == 0
          ? obj.score.toInt().toString()
          : obj.score.toStringAsFixed(1);
    });
  }

  Future<void> _handleSave() async {
    // Lưu các comment vào model
    for (var obj in _objectives) {
      obj.comments = _commentControllers[obj.objectiveId]?.text.trim() ?? '';
    }

    setState(() => _isSaving = true);

    final success = await _service.saveScores(
      thesisId: widget.thesis.thesisId,
      studentId: widget.student.studentId,
      evaluationType: widget.evaluationType,
      objectives: _objectives,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
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
                    'Đã lưu kết quả chấm điểm (${_calculatedTotalScore.toStringAsFixed(1)}đ) cho ${widget.student.studentName}!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.pop(context, true); // Trả về true để màn hình danh sách tự refresh
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
                Text('Lỗi lưu điểm. Vui lòng kiểm tra lại kết nối!'),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReviewer = widget.evaluationType == 'Reviewer';
    final roleLabel = isReviewer ? 'Chấm điểm Phản biện' : 'Chấm điểm Hướng dẫn';
    final roleColor = isReviewer ? const Color(0xFFEA580C) : const Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING HEADER
            _buildFloatingHeader(roleLabel),

            // 2. BANNER THÔNG TIN SINH VIÊN & ĐỀ TÀI
            _buildStudentBanner(roleLabel, roleColor),

            // 3. DANH SÁCH CÁC TIÊU CHÍ CHUẨN ĐẦU RA (CLO)
            Expanded(
              child: _isLoading
                  ? const Center(child: HuitLoading(size: 44, message: 'Đang tải tiêu chí đề cương...'))
                  : _objectives.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
      // 4. BOTTOM BAR: TỔNG ĐIỂM REALTIME & NÚT LƯU
      bottomSheet: _isLoading || _objectives.isEmpty ? null : _buildBottomScoreBar(),
    );
  }

  Widget _buildFloatingHeader(String title) {
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
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 48), // Cân đối với nút back
          ],
        ),
      ),
    );
  }

  Widget _buildStudentBanner(String roleLabel, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Icon(Icons.person, color: roleColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nhóm: ${widget.thesis.groupName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.evaluationType == 'Reviewer' ? 'GVPB' : 'GVHD',
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.thesis.thesisTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
          // Tiêu đề tiêu chí & Điểm tối đa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  obj.outlineContent,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  'Tối đa: ${obj.maxScore.toStringAsFixed(1)}đ',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bộ điều khiển điểm: Stepper / Slider / Textbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Text(
                  'Điểm chấm:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const Spacer(),
                // Nút giảm 0.25
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: obj.score <= 0 ? null : () => _onScoreChanged(obj, obj.score - 0.25),
                ),
                const SizedBox(width: 8),
                // Ô nhập / hiển thị điểm
                Container(
                  width: 58,
                  height: 36,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F766E),
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
                const SizedBox(width: 8),
                // Nút tăng 0.25
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: obj.score >= obj.maxScore ? null : () => _onScoreChanged(obj, obj.score + 0.25),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Ô nhận xét
          TextField(
            controller: commentCtrl,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            decoration: InputDecoration(
              hintText: 'Nhận xét tiêu chí này (tùy chọn)...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                borderSide: const BorderSide(color: Color(0xFF0D9488)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomScoreBar() {
    final total = _calculatedTotalScore;
    final max = _totalMaxScore;
    final isPass = total >= 5.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
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
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: total.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                      TextSpan(
                        text: ' / ${max.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'LƯU ĐIỂM',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Đề tài chưa có chuẩn đầu ra (CLO)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đề tài này chưa thiết lập đề cương chi tiết để chấm điểm.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
