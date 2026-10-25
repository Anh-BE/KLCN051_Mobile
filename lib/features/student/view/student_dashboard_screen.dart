import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/donut_stat_card.dart';
import '../../auth/model/user_model.dart';
import '../../dashboard/logic/dashboard_service.dart';
import '../../dashboard/model/dashboard_stats_models.dart';
import '../group/logic/student_group_service.dart';
import '../model/registration_period_model.dart';
import '../progress/logic/student_progress_service.dart';
import '../progress/model/student_progress_model.dart';
import 'widgets/period_selection_dialog.dart';
import 'widgets/student_progress_overview_card.dart';
import 'widgets/weekly_plan_card.dart';
import 'widgets/submit_report_sheet.dart';

/// Màn hình Dashboard và Xem Chi Tiết dành riêng cho Sinh viên
class StudentDashboardScreen extends StatefulWidget {
  final UserModel user;

  const StudentDashboardScreen({super.key, required this.user});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final StudentProgressService _progressService = StudentProgressService();

  StudentDashboardStats? _stats = StudentDashboardStats();
  StudentThesisProgressModel? _thesisProgress;
  List<RegistrationPeriodModel> _studentPeriods = [];
  RegistrationPeriodModel? _currentPeriod;

  bool _isLoading = true;

  UserModel get user => widget.user;

  @override
  void initState() {
    super.initState();
    _loadAllDashboardData();
  }

  Future<void> _loadAllDashboardData() async {
    try {
      final periods = await StudentGroupService().getMyPeriods();
      final currentPeriodId = await StudentGroupService().getCurrentPeriodId();
      RegistrationPeriodModel? currentP;
      if (periods.isNotEmpty) {
        currentP = periods.firstWhere(
          (p) => p.periodId == currentPeriodId,
          orElse: () => periods.first,
        );
      }
      final statsData = await _dashboardService.getStudentStats();
      final progressData = await _progressService.getMyThesisProgress();

      if (mounted) {
        setState(() {
          _studentPeriods = periods;
          _currentPeriod = currentP;
          _stats = statsData;
          _thesisProgress = progressData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadAllDashboardData();
  }

  void _openPeriodSelector() {
    if (_studentPeriods.length < 2) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PeriodSelectionDialog(
        periods: _studentPeriods,
        canCancel: true,
        currentSelectedPeriodId: _currentPeriod?.periodId,
        onPeriodSelected: (p) async {
          setState(() {
            _currentPeriod = p;
            _isLoading = true;
          });
          await StudentGroupService().switchPeriod(p);
          await _loadAllDashboardData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final stats = _stats ?? StudentDashboardStats();

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0072E8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DASHBOARD TIẾN ĐỘ',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              _currentPeriod?.periodName ?? 'Khoa Công Nghệ Thông Tin • HUIT',
              style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          if (_studentPeriods.length >= 2)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
              tooltip: 'Đổi đợt khóa luận',
              onPressed: _openPeriodSelector,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: 'Làm mới',
            onPressed: _handleRefresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0072E8), strokeWidth: 2.5),
            )
          : RefreshIndicator(
              color: const Color(0xFF0072E8),
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. BIỂU ĐỒ 3 VÒNG TRÒN DONUT THỐNG KÊ TIẾN ĐỘ BÁO CÁO
                    DonutStatCard(
                      title: 'Tiến độ Báo cáo & Nhiệm vụ',
                      filterPillText: stats.periodName.isNotEmpty ? stats.periodName : (_currentPeriod?.periodName ?? 'HK1 (2026-2027)'),
                      onFilterTap: _studentPeriods.length >= 2 ? _openPeriodSelector : null,
                      topSummaryWidget: stats.hasUpcomingDeadline
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stats.upcomingDeadlineTitle ?? 'Báo cáo tuần',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: colors.isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Hạn nộp: ${stats.upcomingDeadlineTime != null ? "${stats.upcomingDeadlineTime!.day.toString().padLeft(2, '0')}/${stats.upcomingDeadlineTime!.month.toString().padLeft(2, '0')} 23:59" : "23:59"} • ${stats.upcomingRemainingText ?? ""}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                      items: [
                        DonutStatItem(
                          value: stats.submittedWeeks,
                          label: 'Tuần đã nộp',
                          progressPercent: stats.totalWeeks > 0 ? stats.submittedWeeks / stats.totalWeeks : 0.0,
                          color: const Color(0xFF10B981),
                        ),
                        DonutStatItem(
                          value: stats.unsubmittedWeeks,
                          label: 'Chưa nộp',
                          progressPercent: stats.totalWeeks > 0 ? stats.unsubmittedWeeks / stats.totalWeeks : 0.0,
                          color: const Color(0xFFEA580C),
                        ),
                        DonutStatItem(
                          value: stats.assignedTasksCount,
                          label: 'Bài GV đã giao',
                          progressPercent: stats.totalWeeks > 0 ? 1.0 : 0.0,
                          color: const Color(0xFF0072E8),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 2. CARD TỔNG QUAN TIẾN ĐỘ ĐỀ TÀI (NẾU CÓ)
                    if (_thesisProgress != null && _thesisProgress!.hasThesis) ...[
                      StudentProgressOverviewCard(data: _thesisProgress!),
                      const SizedBox(height: 16),
                    ],

                    // 3. TIÊU ĐỀ CHI TIẾT TỪNG TUẦN
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0072E8).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.format_list_bulleted_rounded, size: 18, color: Color(0xFF0072E8)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chi Tiết Báo Cáo Theo Tuần',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: colors.sectionTitle,
                          ),
                        ),
                        const Spacer(),
                        if (_thesisProgress != null && _thesisProgress!.weeklyPlans.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_thesisProgress!.weeklyPlans.length} Tuần',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 4. DANH SÁCH CHI TIẾT CÁC TUẦN BÁO CÁO
                    if (_thesisProgress == null || _thesisProgress!.weeklyPlans.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: colors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_late_outlined, size: 48, color: colors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              (_thesisProgress?.message != null && _thesisProgress!.message!.isNotEmpty)
                                  ? _thesisProgress!.message!
                                  : 'Bạn chưa đăng ký đề tài hoặc đề tài đang chờ phê duyệt.\nKế hoạch báo cáo tuần sẽ tự động hiển thị khi đề tài được duyệt chính thức.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _thesisProgress!.weeklyPlans.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final plan = _thesisProgress!.weeklyPlans[index];
                          return WeeklyPlanCard(
                            plan: plan,
                            isLeader: true,
                            onSubmitPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => SubmitReportSheet(
                                  plan: plan,
                                  service: _progressService,
                                  onSubmittedSuccess: _handleRefresh,
                                ),
                              );
                            },
                            onUnsubmitPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: colors.cardBg,
                                  title: const Text('Hủy nộp bài?'),
                                  content: const Text('Bạn có chắc muốn hủy bài nộp này để nộp lại không?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await StudentProgressService().unsubmitReport(plan.weekNumber);
                                _handleRefresh();
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
