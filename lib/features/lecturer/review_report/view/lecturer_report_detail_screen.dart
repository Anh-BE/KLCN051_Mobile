import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
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
      AppToast.showWarning(
        context,
        'Nhóm chưa nộp báo cáo tuần này. Không thể gửi đánh giá.',
        title: 'Chưa có báo cáo',
      );
      return;
    }

    final score = double.tryParse(_scoreController.text.trim()) ?? _currentScore;
    if (score < 0 || score > 10) {
      AppToast.showError(
        context,
        'Điểm số phải nằm trong khoảng từ 0 đến 10.',
        title: 'Điểm không hợp lệ',
      );
      return;
    }

    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.isEmpty) {
      AppToast.showWarning(
        context,
        'Vui lòng nhập nhận xét/phản hồi cho sinh viên.',
        title: 'Thiếu nhận xét',
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
      if (isSuccess) {
        AppToast.showSuccess(
          context,
          res['message']?.toString() ?? 'Đã lưu phản hồi thành công.',
          title: 'Thành công',
        );
        Navigator.pop(context, true);
      } else {
        AppToast.showError(
          context,
          res['message']?.toString() ?? 'Lưu phản hồi thất bại.',
          title: 'Lỗi',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final item = widget.timelineItem;
    final leaderName = item.submitterName ?? widget.thesis.leaderName;
    final leaderCode = item.submitterCode ?? widget.thesis.leaderCode;

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
                        _buildSubmitterCard(leaderName, leaderCode, colors),

                        const SizedBox(height: 14),

                        // THẺ 2: YÊU CẦU & MỤC TIÊU CỦA TUẦN
                        _buildPlanRequirementsCard(item, colors),

                        const SizedBox(height: 14),

                        // THẺ 3: NỘI DUNG BÁO CÁO CỦA SINH VIÊN
                        _buildStudentReportCard(item, colors),

                        const SizedBox(height: 14),

                        // THẺ 4: BIỂU MẪU ĐÁNH GIÁ & NHẬN XÉT CỦA GIẢNG VIÊN
                        _buildLecturerFeedbackForm(item, colors),

                        const SizedBox(height: 80), // Chừa khoảng trống cho bottom bar
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 3. FIXED BOTTOM BAR THEO CHUẨN DESIGN SYSTEM 4.6 CỦA APP_MOBILE.MD
      bottomSheet: _buildFixedBottomBar(item, colors),
    );
  }

  // 1. Floating Pill Header chuẩn HUIT Blue Gradient
  Widget _buildFloatingHeader(WeeklyTimelineItemModel item) {
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
            Expanded(
              child: Text(
                'BÁO CÁO TUẦN ${item.weekNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.statusIcon, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    item.statusDisplayText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

  // THẺ 1: NGƯỜI ĐẠI DIỆN NỘP - CỐ ĐỊNH LÀ NHÓM TRƯỞNG
  Widget _buildSubmitterCard(String leaderName, String leaderCode, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              // Avatar tròn chuẩn HUIT Blue
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0072E8), Color(0xFF0091FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leaderName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MSSV: $leaderCode • ${widget.thesis.groupName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Pill Badge: CỐ ĐỊNH LÀ NHÓM TRƯỞNG (Chuẩn HUIT Xanh & Trắng)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF0072E8), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Nhóm trưởng',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // THẺ 2: YÊU CẦU & MỤC TIÊU TUẦN
  Widget _buildPlanRequirementsCard(WeeklyTimelineItemModel item, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mục tiêu & Kế hoạch tuần',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  'Hạn: ${item.formattedDeadline}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
            ),
          ),
          if (item.detailedRequirements.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.detailedRequirements,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // THẺ 3: NỘI DUNG BÁO CÁO CỦA SINH VIÊN
  Widget _buildStudentReportCard(WeeklyTimelineItemModel item, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nội dung sinh viên báo cáo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (item.formattedSubmittedAt != null)
                Text(
                  'Nộp lúc: ${item.formattedSubmittedAt}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.isSubmitted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.subCardBorder),
              ),
              child: Text(
                item.content ?? 'Nhóm đã nộp tài liệu đính kèm bên dưới.',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),

            if (item.reportFileUrl != null && item.reportFileUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              ...item.reportFileUrl!.split(';').map((rawItem) {
                final fileOrUrl = rawItem.trim();
                if (fileOrUrl.isEmpty) return const SizedBox.shrink();

                final isLink = fileOrUrl.startsWith('http://') ||
                    fileOrUrl.startsWith('https://') ||
                    fileOrUrl.startsWith('github.com');
                final isGitHub = fileOrUrl.toLowerCase().contains('github.com');

                if (isLink) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.isDark ? const Color(0xFF263345) : const Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isGitHub ? Icons.code_rounded : Icons.link_rounded,
                            color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGitHub ? 'Mã nguồn GitHub' : 'Liên kết sản phẩm / Báo cáo',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fileOrUrl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.isDark ? const Color(0xFF93C5FD) : const Color(0xFF0072E8),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                          tooltip: 'Sao chép liên kết',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: fileOrUrl));
                            AppToast.showSuccess(
                              context,
                              'Đã sao chép liên kết vào bộ nhớ tạm: $fileOrUrl',
                              title: 'Đã sao chép',
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                // Trường hợp tệp đính kèm tải lên máy chủ (/uploads/...)
                final segments = fileOrUrl.split('/').where((s) => s.isNotEmpty).toList();
                String fileName = segments.isNotEmpty ? segments.last : fileOrUrl;
                if (fileName.contains('_')) {
                  fileName = fileName.substring(fileName.indexOf('_') + 1);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.isDark ? const Color(0xFF263345) : const Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.attach_file_rounded,
                          color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: colors.isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                              ),
                            ),
                            Text(
                              'Tài liệu báo cáo tiến độ • PDF/DOCX',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                        ),
                        onPressed: () {
                          AppToast.showInfo(
                            context,
                            'Tài liệu báo cáo: $fileName',
                            title: 'Tài liệu báo cáo',
                          );
                        },
                        tooltip: 'Tải tệp về',
                      ),
                    ],
                  ),
                );
              }),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.subCardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 34, color: colors.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có báo cáo nào được nộp cho tuần này',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Hệ thống đang chờ Nhóm trưởng nộp tiến độ.',
                    style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // THẺ 4: BIỂU MẪU ĐÁNH GIÁ & NHẬN XÉT CỦA GIẢNG VIÊN
  Widget _buildLecturerFeedbackForm(WeeklyTimelineItemModel item, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.rate_review_rounded,
                  color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Đánh giá & Nhận xét của GVHD',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. SEGMENTED PILL TOGGLE: ĐẠT (DUYỆT) / CẦN CHỈNH SỬA
          Text(
            'Kết quả đánh giá tuần:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.segmentBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.cardBorder),
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
                            color: _isPassed ? Colors.white : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ĐẠT (DUYỆT TIẾN ĐỘ)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _isPassed ? Colors.white : colors.textSecondary,
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
                        color: !_isPassed ? const Color(0xFFF59E0B) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !_isPassed
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
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
                            color: !_isPassed ? Colors.white : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CẦN CHỈNH SỬA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: !_isPassed ? Colors.white : colors.textSecondary,
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
              Text(
                'Điểm đánh giá (thang 10):',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  '${_currentScore.toStringAsFixed(1)} / 10',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF0072E8),
              inactiveTrackColor: colors.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              thumbColor: const Color(0xFF0072E8),
              overlayColor: const Color(0xFF0072E8).withValues(alpha: 0.15),
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

          // 3. KHUNG TEXTAREA NHẬN XÉT
          Text(
            'Nhận xét chi tiết cho nhóm:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: colors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.cardBorder),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nhập góp ý, hướng dẫn điều chỉnh hoặc dặn dò cho nhóm sinh viên...',
                hintStyle: TextStyle(fontSize: 12.5, color: colors.textMuted),
                contentPadding: const EdgeInsets.all(12),
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
                _buildQuickTag('Đạt yêu cầu tuần, tiếp tục phát huy!', colors),
                const SizedBox(width: 6),
                _buildQuickTag('Cần bổ sung thêm sơ đồ CSDL.', colors),
                const SizedBox(width: 6),
                _buildQuickTag('Bám sát tiến độ đề cương.', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTag(String text, AppColors colors) {
    return GestureDetector(
      onTap: () {
        if (_feedbackController.text.isEmpty) {
          _feedbackController.text = text;
        } else {
          _feedbackController.text = '${_feedbackController.text} $text';
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Text(
          '+ $text',
          style: TextStyle(
            fontSize: 11,
            color: colors.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0072E8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // 3. FIXED BOTTOM BAR THEO CHUẨN DESIGN SYSTEM HUIT BLUE
  Widget _buildFixedBottomBar(WeeklyTimelineItemModel item, AppColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        border: Border(top: BorderSide(color: colors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.3 : 0.05),
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
              backgroundColor: const Color(0xFF0072E8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: const Color(0xFF0072E8).withValues(alpha: 0.35),
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
