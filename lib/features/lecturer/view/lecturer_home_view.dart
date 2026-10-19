import 'package:flutter/material.dart';
import '../../../core/localization/app_language_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/model/user_model.dart';
import '../../notification/view/notification_bell_button.dart';
import '../review_report/view/lecturer_weekly_report_list_screen.dart';
import '../scoring/view/lecturer_scoring_list_screen.dart';
import '../topic/view/lecturer_topic_list_screen.dart';
import '../../../core/widgets/donut_stat_card.dart';
import '../../dashboard/logic/dashboard_service.dart';
import '../../dashboard/model/dashboard_stats_models.dart';

class LecturerHomeView extends StatefulWidget {
  final UserModel user;
  final Function(int)? onTabChange;

  const LecturerHomeView({
    super.key,
    required this.user,
    this.onTabChange,
  });

  @override
  State<LecturerHomeView> createState() => _LecturerHomeViewState();
}

class _LecturerHomeViewState extends State<LecturerHomeView> {
  final DashboardService _dashboardService = DashboardService();
  LecturerDashboardStats? _stats = LecturerDashboardStats();
  LecturerDashboardStats get _safeStats => _stats ?? LecturerDashboardStats();
  bool _isLoadingStats = true;

  UserModel get user => widget.user;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final data = await _dashboardService.getLecturerStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minCardHeight = (constraints.maxHeight - 200).clamp(360.0, 3000.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. HEADER DẠNG VIÊN THUỐC NỔI (FLOATING PILL CAPSULE) CHUẨN ĐỒNG BỘ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar Giảng viên
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white.withValues(alpha: 0.2),
                          image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 26)
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Thông tin Họ tên & Chức danh
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Giảng viên hướng dẫn • Khoa CNTT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chuông thông báo
                      const NotificationBellButton(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. BIỂU ĐỒ TRÒN THỐNG KÊ ĐỀ TÀI & HƯỚNG DẪN CỦA GIẢNG VIÊN (CHUẨN THIẾT KẾ DONUT)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoadingStats
                    ? Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: colors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.cardBorder),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF0072E8), strokeWidth: 2.5),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final stats = _stats ?? LecturerDashboardStats();
                          return DonutStatCard(
                            title: 'Trạng thái Đề xuất Đề tài',
                            filterPillText: stats.periodName.isNotEmpty ? stats.periodName : 'HK1 (2026-2027)',
                            topSummaryWidget: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.subCardBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.school_rounded, size: 20, color: Color(0xFF0072E8)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                                        children: [
                                          const TextSpan(text: 'Đang hướng dẫn: '),
                                          TextSpan(
                                            text: '${stats.supervisedThesesCount} đề tài',
                                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0072E8)),
                                          ),
                                          TextSpan(
                                            text: ' (${stats.supervisedGroupsCount} nhóm) • ',
                                          ),
                                          const TextSpan(text: 'Tổng đề xuất: '),
                                          TextSpan(
                                            text: '${stats.totalProposed}',
                                            style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            items: [
                              DonutStatItem(
                                value: stats.approvedCount,
                                label: 'Được duyệt',
                                progressPercent: stats.totalProposed > 0 ? stats.approvedCount / stats.totalProposed : 0.0,
                                color: const Color(0xFF16A34A),
                              ),
                              DonutStatItem(
                                value: stats.needsRevisionCount,
                                label: 'Cần chỉnh sửa',
                                progressPercent: stats.totalProposed > 0 ? stats.needsRevisionCount / stats.totalProposed : 0.0,
                                color: const Color(0xFFD97706),
                              ),
                              DonutStatItem(
                                value: stats.rejectedCount,
                                label: 'Không duyệt',
                                progressPercent: stats.totalProposed > 0 ? stats.rejectedCount / stats.totalProposed : 0.0,
                                color: const Color(0xFFEF4444),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // 3. KHỐI CARD CHỨC NĂNG CHÍNH CỦA GIẢNG VIÊN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  constraints: BoxConstraints(minHeight: minCardHeight),
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.cardBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : const Color(0xFF007AFF).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề khối
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF5FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.grid_view_rounded,
                              size: 16,
                              color: Color(0xFF0072E8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr('main_functions'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.isDark ? const Color(0xFF232529) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Khóa luận 2026',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // HÀNG 3 CHỨC NĂNG DÀN ĐỀU (PHONG CÁCH SQUIRCLE APP ICON)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Đề tài hướng dẫn (Navy Blue)
                          Expanded(
                            child: _buildSquircleActionItem(
                              context: context,
                              icon: Icons.description_rounded,
                              title: 'Đề tài hướng dẫn',
                              color: const Color(0xFF1D4ED8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LecturerTopicListScreen(user: user),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 2. Báo cáo tiến độ (HUIT Blue)
                          Expanded(
                            child: _buildSquircleActionItem(
                              context: context,
                              icon: Icons.view_timeline_rounded,
                              title: 'Báo cáo tiến độ',
                              color: const Color(0xFF0072E8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LecturerWeeklyReportListScreen(user: user),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 3. Chấm điểm phân công (Royal Purple / Violet)
                          Expanded(
                            child: _buildSquircleActionItem(
                              context: context,
                              icon: Icons.fact_check_rounded,
                              title: 'Nhập điểm phân công',
                              color: const Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LecturerScoringListScreen(user: user),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // HÀNG 2 THẺ THỐNG KÊ NHANH CỦA GIẢNG VIÊN
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              value: '${_safeStats.supervisedThesesCount}',
                              label: 'Đề tài hướng dẫn',
                              icon: Icons.menu_book_rounded,
                              color: const Color(0xFF0284C7),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LecturerTopicListScreen(user: user),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context: context,
                              value: '${_safeStats.approvedCount}',
                              label: 'Đã hoàn thành duyệt',
                              icon: Icons.pending_actions_rounded,
                              color: const Color(0xFFF59E0B),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LecturerWeeklyReportListScreen(user: user),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // BANNER THÔNG TIN HƯỚNG DẪN TIẾN ĐỘ
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFDCFCE7),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Theo dõi báo cáo tiến độ tuần',
                                    style: TextStyle(
                                      color: colors.isDark ? Colors.white : const Color(0xFF14532D),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Giảng viên duyệt kế hoạch tuần và chấm điểm nhận xét báo cáo định kỳ cho các nhóm sinh viên tại mục Xem báo cáo tuần.',
                                    style: TextStyle(
                                      color: colors.isDark ? Colors.white70 : const Color(0xFF166534),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 96), // Đệm dưới để không bị Bottom Navigation Bar che mất
            ],
          ),
        );
      },
    );
  }

  // WIDGET NÚT CHỨC NĂNG SQUIRCLE THEO PHONG CÁCH APP ICON
  Widget _buildSquircleActionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: color.withValues(alpha: 0.15),
      highlightColor: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Khung Squircle App Icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                if (badgeText != null && badgeText.isNotEmpty)
                  Positioned(
                    top: -3,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Tên chức năng (Text không viền)
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                height: 1.25,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET THẺ THỐNG KÊ NHANH
  Widget _buildStatCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
