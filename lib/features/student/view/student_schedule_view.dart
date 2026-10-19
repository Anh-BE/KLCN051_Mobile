import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/huit_loading.dart';
import '../../auth/model/user_model.dart';
import '../../notification/view/notification_bell_button.dart';
import '../group/logic/student_group_service.dart';
import '../group/model/student_group_model.dart';
import '../progress/logic/student_progress_service.dart';
import '../progress/model/student_progress_model.dart';
import 'widgets/student_progress_overview_card.dart';
import 'widgets/submit_report_sheet.dart';
import 'widgets/weekly_plan_card.dart';

class StudentScheduleView extends StatefulWidget {
  final UserModel user;

  const StudentScheduleView({super.key, required this.user});

  @override
  State<StudentScheduleView> createState() => _StudentScheduleViewState();
}

class _StudentScheduleViewState extends State<StudentScheduleView> {
  final StudentProgressService _service = StudentProgressService();
  bool _isLoading = true;
  StudentThesisProgressModel? _progressData;
  StudentGroupModel? _myGroup;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);
    final data = await _service.getMyThesisProgress();
    StudentGroupModel? group;
    try {
      group = await StudentGroupService().getMyGroup(widget.user);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _progressData = data;
        _myGroup = group;
        _isLoading = false;
      });
    }
  }

  bool get _isLeader {
    if (_progressData != null && _progressData!.students.isNotEmpty) {
      final isProgressLeader = _progressData!.students.any(
        (s) =>
            (s.studentId == widget.user.userId ||
                (widget.user.identifierCode.isNotEmpty && s.studentCode == widget.user.identifierCode)) &&
            s.isLeader,
      );
      if (isProgressLeader) return true;
    }
    if (_myGroup != null) {
      return _myGroup!.isUserLeader(widget.user);
    }
    return false;
  }

  // ==========================================
  // XỬ LÝ NỘP BÀI TẬP (SUBMIT MODAL)
  // ==========================================
  void _showSubmitModal(WeeklyPlanModel plan) {
    if (!_isLeader) {
      AppDialog.showAlert(
        context,
        title: 'Quyền thao tác',
        message: 'Chỉ nhóm trưởng mới có quyền nộp báo cáo tuần.',
        buttonText: 'Đã hiểu',
      );
      return;
    }

    if (!plan.hasValidDeadline) {
      AppDialog.showAlert(
        context,
        title: 'Thông báo',
        message: 'Giáo viên chưa gia hạn bài tập trong Tuần này',
        buttonText: 'Đã hiểu',
      );
      return;
    }

    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SubmitReportSheet(
        plan: plan,
        service: _service,
        onSubmittedSuccess: _loadProgressData,
      ),
    );
  }

  // ==========================================
  // XỬ LÝ HỦY NỘP BÀI (UNSUBMIT)
  // ==========================================
  Future<void> _handleUnsubmit(WeeklyPlanModel plan) async {
    if (!_isLeader) {
      AppDialog.showAlert(
        context,
        title: 'Quyền thao tác',
        message: 'Chỉ nhóm trưởng mới có quyền hủy nộp báo cáo.',
        buttonText: 'Đã hiểu',
      );
      return;
    }

    if (plan.report == null) return;

    final confirm = await AppDialog.showConfirm(
      context,
      title: 'Hủy nộp bài',
      message: 'Bạn có chắc chắn muốn hủy nộp bài tập Tuần ${plan.weekNumber} để cập nhật lại nội dung không?',
      confirmText: 'Đồng ý hủy nộp',
      cancelText: 'Đóng',
      type: DialogType.warning,
      icon: Icons.refresh_rounded,
    );

    if (confirm == true) {
      final res = await _service.unsubmitReport(plan.report!.reportId);
      if (res['success'] == true) {
        if (mounted) {
          AppToast.showSuccess(context, res['message'] ?? 'Đã hủy nộp bài thành công.');
          _loadProgressData();
        }
      } else {
        if (mounted) {
          AppToast.showError(context, res['message'] ?? 'Không thể hủy nộp bài.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return RefreshIndicator(
      onRefresh: _loadProgressData,
      color: colors.sectionTitle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER DẠNG VIÊN THUỐC NỔI
            _buildHeaderPill(context),

            const SizedBox(height: 16),

            // 2. NỘI DUNG CHÍNH (LOADING / EMPTY / DỮ LIỆU THẬT)
            if (_isLoading) ...[
              _buildLoadingSkeleton(colors),
            ] else if (_progressData == null || !_progressData!.hasThesis || _progressData!.weeklyPlans.isEmpty) ...[
              _buildEmptyStateCard(colors),
            ] else ...[
              // 2.1 CARD TỔNG QUAN TIẾN ĐỘ THẬT
              StudentProgressOverviewCard(data: _progressData!),

              const SizedBox(height: 16),

              // 2.2 TIÊU ĐỀ SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kế hoạch báo cáo định kỳ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.sectionTitle,
                        letterSpacing: 0.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_progressData!.weeklyPlans.length} tuần',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.sectionTitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2.3 DANH SÁCH CÁC TUẦN THỰC TẾ
              ..._progressData!.weeklyPlans.map(
                (plan) => WeeklyPlanCard(
                  plan: plan,
                  isLeader: _isLeader,
                  onSubmitPressed: () => _showSubmitModal(plan),
                  onUnsubmitPressed: () => _handleUnsubmit(plan),
                ),
              ),
            ],

            const SizedBox(height: 70), // Khoảng đệm cho bottom navigation bar
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER DẠNG VIÊN THUỐC NỔI
  // ==========================================
  Widget _buildHeaderPill(BuildContext context) {
    final user = widget.user;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0072E8), Color(0xFF0091FF), Color(0xFF00A2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white.withValues(alpha: 0.25),
              image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(user.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'MSSV: ${user.identifierCode}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const NotificationBellButton(),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE CARD
  // ==========================================
  Widget _buildEmptyStateCard(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_late_outlined, size: 54, color: colors.textMuted),
          const SizedBox(height: 14),
          Text(
            'Chưa có kế hoạch tiến độ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _progressData?.message ?? 'Nhóm của bạn hiện chưa được duyệt đề tài hoặc dữ liệu kế hoạch tuần đang được cập nhật.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadProgressData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tải lại dữ liệu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0084FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOADING SKELETON (HUIT SPINNER)
  // ==========================================
  Widget _buildLoadingSkeleton(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: const HuitLoading(
        size: 76,
        message: 'Đang tải kế hoạch tiến độ...',
      ),
    );
  }
}
