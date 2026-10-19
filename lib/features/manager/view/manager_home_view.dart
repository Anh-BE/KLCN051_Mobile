import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/model/user_model.dart';
import 'manager_detailed_stats_screen.dart';
import '../../notification/view/notification_bell_button.dart';
import '../../../core/widgets/donut_stat_card.dart';
import '../../dashboard/logic/dashboard_service.dart';
import '../../dashboard/model/dashboard_stats_models.dart';

class ManagerHomeView extends StatefulWidget {
  final UserModel user;

  const ManagerHomeView({super.key, required this.user});

  @override
  State<ManagerHomeView> createState() => _ManagerHomeViewState();
}

class _ManagerHomeViewState extends State<ManagerHomeView> {
  final DashboardService _dashboardService = DashboardService();
  AdminDashboardStats? _stats = AdminDashboardStats();
  AdminDashboardStats get _safeStats => _stats ?? AdminDashboardStats();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminStats();
  }

  Future<void> _loadAdminStats() async {
    try {
      final data = await _dashboardService.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = data;
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = widget.user;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER GRADIENT DÀNH CHO QUẢN LÝ / BAN CHỦ NHIỆM
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white.withOpacity(0.2),
                    image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 30)
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ban Chủ Nhiệm Khoa CNTT • HUIT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManagerDetailedStatsScreen(user: user),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                // Quả chuông thông báo realtime
                const NotificationBellButton(),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. BIỂU ĐỒ 3 VÒNG TRÒN DONUT THỐNG KÊ QUY MÔ TOÀN KHOA (CHUẨN THIẾT KẾ DONUT)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _isLoading
                ? Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1D4ED8), strokeWidth: 2.5),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final stats = _stats ?? AdminDashboardStats();
                      return DonutStatCard(
                        title: 'Tình hình Đề tài & Hướng dẫn Toàn Khoa',
                        filterPillText: stats.periodName.isNotEmpty ? stats.periodName : 'HK1 (2026-2027)',
                        topSummaryWidget: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_stories_rounded, size: 20, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                                    children: [
                                      const TextSpan(text: 'Tổng số đề tài toàn khoa: '),
                                      TextSpan(
                                        text: '${stats.totalTheses} đề tài',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8), fontSize: 14),
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
                            value: stats.registeredTheses,
                            label: 'Được đăng ký',
                            progressPercent: stats.totalTheses > 0 ? stats.registeredTheses / stats.totalTheses : 0.0,
                            color: const Color(0xFF2563EB),
                          ),
                          DonutStatItem(
                            value: stats.supervisedTheses,
                            label: 'Được hướng dẫn',
                            progressPercent: stats.totalTheses > 0 ? stats.supervisedTheses / stats.totalTheses : 0.0,
                            color: const Color(0xFF10B981),
                          ),
                          DonutStatItem(
                            value: stats.activeLecturersCount,
                            label: 'GVHD trong kỳ',
                            progressPercent: stats.activeLecturersCount > 0 ? 0.8 : 0.0,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // NÚT TRUY CẬP SỐ LIỆU TỔNG HỢP CHI TIẾT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManagerDetailedStatsScreen(user: user),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
                label: const Text(
                  'XEM SỐ LIỆU TỔNG HỢP CHI TIẾT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. TIẾN ĐỘ THỰC HIỆN ĐỢT KHÓA LUẬN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: colors.isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tỷ Lệ Nghiệp Vụ Khóa Luận (HUIT)',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: colors.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildProgressRow(
                    colors,
                    'Tỷ lệ đề tài được SV đăng ký',
                    _safeStats.totalTheses > 0 ? (_safeStats.registeredTheses / _safeStats.totalTheses) : 0.0,
                    _safeStats.totalTheses > 0
                        ? '${((_safeStats.registeredTheses / _safeStats.totalTheses) * 100).toStringAsFixed(1)}% (${_safeStats.registeredTheses}/${_safeStats.totalTheses})'
                        : '0%',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressRow(
                    colors,
                    'Tỷ lệ đề tài đã có Giảng viên hướng dẫn',
                    _safeStats.totalTheses > 0 ? (_safeStats.supervisedTheses / _safeStats.totalTheses) : 0.0,
                    _safeStats.totalTheses > 0
                        ? '${((_safeStats.supervisedTheses / _safeStats.totalTheses) * 100).toStringAsFixed(1)}% (${_safeStats.supervisedTheses}/${_safeStats.totalTheses})'
                        : '0%',
                    const Color(0xFF0284C7),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressRow(
                    colors,
                    'Đội ngũ Giảng viên hướng dẫn tham gia',
                    _safeStats.activeLecturersCount > 0 ? 1.0 : 0.0,
                    '${_safeStats.activeLecturersCount} Giảng viên',
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProgressRow(AppColors colors, String title, double value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: colors.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
