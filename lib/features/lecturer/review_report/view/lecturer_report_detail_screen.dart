import 'package:flutter/material.dart';
import '../../../auth/model/user_model.dart';
import '../logic/weekly_report_service.dart';
import '../model/weekly_report_model.dart';

class LecturerReportDetailScreen extends StatefulWidget {
  final WeeklyTimelineItemModel timelineItem;
  final LecturerThesisProgressModel thesis;
  final UserModel user;

  const LecturerReportDetailScreen({
    super.key,
    required this.timelineItem,
    required this.thesis,
    required this.user,
  });

  @override
  State<LecturerReportDetailScreen> createState() => _LecturerReportDetailScreenState();
}

class _LecturerReportDetailScreenState extends State<LecturerReportDetailScreen> {
  final WeeklyReportService _service = WeeklyReportService();

  late TextEditingController _feedbackController;
  late TextEditingController _scoreController;
  late bool _isPassed;
  double _currentScore = 8.5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isPassed = widget.timelineItem.isPassed ?? true;
    _currentScore = widget.timelineItem.supervisorScore ?? 8.5;

    _scoreController = TextEditingController(
      text: widget.timelineItem.supervisorScore != null
          ? widget.timelineItem.supervisorScore!.toStringAsFixed(1)
          : '8.5',
    );

    _feedbackController = TextEditingController(
      text: widget.timelineItem.supervisorFeedback ?? '',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    // Nếu chưa nộp báo cáo
    if (!widget.timelineItem.isSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhóm chưa nộp báo cáo tuần này. Không thể gửi đánh giá.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final score = double.tryParse(_scoreController.text.trim()) ?? _currentScore;
    if (score < 0 || score > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điểm số phải nằm trong khoảng từ 0 đến 10.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nhận xét/phản hồi cho sinh viên.'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final req = FeedbackRequestModel(
      reportId: widget.timelineItem.reportId ?? 0,
      planId: widget.timelineItem.planId,
      thesisId: widget.thesis.thesisId,
      supervisorFeedback: feedbackText,
      supervisorScore: score,
      isPassed: _isPassed,
      submissionStatus: _isPassed ? 'Approved' : 'NeedsRevision',
    );

    final res = await _service.submitFeedback(req);

    if (mounted) {
      setState(() => _isSubmitting = false);

      final isSuccess = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(res['message']?.toString() ?? 'Đã lưu phản hồi')),
            ],
          ),
          backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (isSuccess) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.timelineItem;
    final leaderName = item.submitterName ?? widget.thesis.leaderName;
    final leaderCode = item.submitterCode ?? widget.thesis.leaderCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Chuẩn Scaffold App_Mobile.md
      body: SafeArea(
        child: Column(
          children: [
            // 1. FLOATING PILL HEADER
            _buildFloatingHeader(item),

            // 2. SCROLLABLE FORM BODY
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // THẺ 1: NGƯỜI NỘP - CỐ ĐỊNH LÀ NHÓM TRƯỞNG
                    _buildSubmitterCard(leaderName, leaderCode),

                    const SizedBox(height: 14),

                    // THẺ 2: YÊU CẦU & MỤC TIÊU CỦA TUẦN
                    _buildPlanRequirementsCard(item),

                    const SizedBox(height: 14),

                    // THẺ 3: NỘI DUNG BÁO CÁO CỦA SINH VIÊN
                    _buildStudentReportCard(item),

                    const SizedBox(height: 14),

                    // THẺ 4: BIỂU MẪU ĐÁNH GIÁ & NHẬN XÉT CỦA GIẢNG VIÊN
                    _buildLecturerFeedbackForm(item),

                    const SizedBox(height: 80), // Chừa khoảng trống cho bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. FIXED BOTTOM BAR THEO CHUẨN DESIGN SYSTEM 4.6 CỦA APP_MOBILE.MD
      bottomSheet: _buildFixedBottomBar(item),
    );
  }

  // 1. Floating Pill Header
  Widget _buildFloatingHeader(WeeklyTimelineItemModel item) {
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
            Expanded(
              child: Text(
                'BÁO CÁO TUẦN ${item.weekNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: item.statusBgColor,
                borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  // THẺ 1: NGƯỜI ĐẠI DIỆN NỘP - CỐ ĐỊNH LÀ NHÓM TRƯỞNG (App_Mobile.md 4.6 Card người nộp)
  Widget _buildSubmitterCard(String leaderName, String leaderCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar tròn
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leaderName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MSSV: $leaderCode • ${widget.thesis.groupName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Pill Badge: CỐ ĐỊNH LÀ NHÓM TRƯỞNG
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Nhóm trưởng',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Dòng ghi chú cố định nhóm trưởng đại diện nộp
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF0F766E)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Sinh viên đại diện nộp báo cáo cố định là Nhóm trưởng theo quy chế.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.timelineItem.formattedSubmittedAt != null)
                Text(
                  'Nộp lúc: ${widget.timelineItem.formattedSubmittedAt}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // THẺ 2: YÊU CẦU & MỤC TIÊU TUẦN
  Widget _buildPlanRequirementsCard(WeeklyTimelineItemModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Mục tiêu & Kế hoạch tuần',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hạn: ${item.formattedDeadline}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.detailedRequirements.isNotEmpty
                ? item.detailedRequirements
                : 'Thực hiện theo các yêu cầu chi tiết đã phân công trong đề cương.',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // THẺ 3: NỘI DUNG BÁO CÁO CỦA SINH VIÊN
  Widget _buildStudentReportCard(WeeklyTimelineItemModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_rounded, color: Color(0xFF0D9488), size: 20),
              SizedBox(width: 8),
              Text(
                'Nội dung sinh viên báo cáo',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (item.isSubmitted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                item.content ?? 'Nhóm đã nộp tài liệu đính kèm bên dưới.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ),

            if (item.reportFileUrl != null && item.reportFileUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              // File đính kèm Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.attach_file_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.reportFileUrl!.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const Text(
                            'Tài liệu báo cáo tiến độ • PDF/DOCX',
                            style: TextStyle(fontSize: 11, color: Color(0xFF60A5FA)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: Color(0xFF2563EB)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đang tải tệp: ${item.reportFileUrl!.split('/').last}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      tooltip: 'Tải tệp về',
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có báo cáo nào được nộp cho tuần này',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hệ thống đang chờ Nhóm trưởng nộp tiến độ.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // THẺ 4: BIỂU MẪU ĐÁNH GIÁ & NHẬN XÉT CỦA GIẢNG VIÊN (Form Input App_Mobile.md 4.6)
  Widget _buildLecturerFeedbackForm(WeeklyTimelineItemModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review_rounded, color: Color(0xFF0F766E), size: 20),
              SizedBox(width: 8),
              Text(
                'Đánh giá & Nhận xét của GVHD',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. SEGMENTED PILL TOGGLE: ĐẠT (DUYỆT) / CẦN CHỈNH SỬA (App_Mobile.md 4.6)
          const Text(
            'Kết quả đánh giá tuần:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isPassed = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _isPassed ? const Color(0xFF10B981) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isPassed
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: _isPassed ? Colors.white : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ĐẠT (DUYỆT TIẾN ĐỘ)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _isPassed ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isPassed = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !_isPassed ? const Color(0xFFEF4444) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !_isPassed
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: !_isPassed ? Colors.white : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CẦN CHỈNH SỬA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: !_isPassed ? Colors.white : const Color(0xFF64748B),
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

          const SizedBox(height: 16),

          // 2. NHẬP ĐIỂM TIẾN ĐỘ (0.0 -> 10.0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Điểm đánh giá (thang 10):',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_currentScore.toStringAsFixed(1)} / 10',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF0F766E),
              inactiveTrackColor: const Color(0xFFCBD5E1),
              thumbColor: const Color(0xFF0D9488),
              overlayColor: const Color(0xFF0D9488).withValues(alpha: 0.2),
              trackHeight: 5,
            ),
            child: Slider(
              value: _currentScore,
              min: 0.0,
              max: 10.0,
              divisions: 20,
              label: _currentScore.toStringAsFixed(1),
              onChanged: (val) {
                setState(() {
                  _currentScore = val;
                  _scoreController.text = val.toStringAsFixed(1);
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          // 3. KHUNG TEXTAREA NHẬN XÉT (Bo góc 12px theo Section 4.6)
          const Text(
            'Nhận xét chi tiết cho nhóm:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Nhập góp ý, hướng dẫn điều chỉnh hoặc dặn dò cho nhóm sinh viên...',
                hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickTag('Đạt yêu cầu tuần, tiếp tục phát huy!'),
                const SizedBox(width: 6),
                _buildQuickTag('Cần bổ sung thêm sơ đồ CSDL.'),
                const SizedBox(width: 6),
                _buildQuickTag('Bám sát tiến độ đề cương.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTag(String text) {
    return GestureDetector(
      onTap: () {
        if (_feedbackController.text.isEmpty) {
          _feedbackController.text = text;
        } else {
          _feedbackController.text = '${_feedbackController.text} $text';
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '+ $text',
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // 3. FIXED BOTTOM BAR THEO CHUẨN DESIGN SYSTEM 4.6 (App_Mobile.md)
  Widget _buildFixedBottomBar(WeeklyTimelineItemModel item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'LƯU ĐÁNH GIÁ & PHẢN HỒI',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
