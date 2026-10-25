import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/model/user_model.dart';
import 'manager_detailed_stats_screen.dart';
import '../../notification/view/notification_bell_button.dart';
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

  void _navigateToDashboard([int initialTab = 0]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManagerDetailedStatsScreen(
          user: widget.user,
          initialTabIndex: initialTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = widget.user;
    final stats = _safeStats;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER GRADIENT DÀNH CHO QUẢN LÝ / BAN CHỦ NHIỆM / TRƯỞNG BỘ MÔN
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                        'Ban Chủ Nhiệm / Trưởng Bộ Môn • HUIT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _navigateToDashboard(0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
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

          // 2. MỤC "DASHBOARD" NỔI BẬT ĐỂ VÀO XEM CHI TIẾT (KHÔNG SHOW TRÀN LAN RA NGOÀI GIAO DIỆN CHÍNH NỮA)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _navigateToDashboard(0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'DASHBOARD',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Xem chi tiết',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Biểu đồ Donut, tỷ lệ nghiệp vụ, 5 bộ môn & hội đồng',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 3. KHỐI CHỨC NĂNG NGHIỆP VỤ QUẢN LÝ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(24),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF1D4ED8)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Danh Mục Quản Lý & Báo Cáo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stats.periodName.isNotEmpty ? stats.periodName : 'HK1 (2026-2027)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // HÀNG CÁC MỤC NGHIỆP VỤ SQUIRCLE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Dashboard
                      Expanded(
                        child: _buildSquircleItem(
                          context: context,
                          icon: Icons.insights_rounded,
                          title: 'Dashboard',
                          color: const Color(0xFF1D4ED8),
                          onTap: () => _navigateToDashboard(0),
                        ),
                      ),

                      // 2. Bộ môn & Đề tài
                      Expanded(
                        child: _buildSquircleItem(
                          context: context,
                          icon: Icons.apartment_rounded,
                          title: 'Bộ Môn',
                          color: const Color(0xFF0F766E),
                          onTap: () => _navigateToDashboard(0),
                        ),
                      ),

                      // 3. Tiến độ & Trễ hạn
                      Expanded(
                        child: _buildSquircleItem(
                          context: context,
                          icon: Icons.warning_amber_rounded,
                          title: 'Nộp Trễ',
                          color: const Color(0xFFD97706),
                          onTap: () => _navigateToDashboard(1),
                        ),
                      ),

                      // 4. Hội đồng bảo vệ
                      Expanded(
                        child: _buildSquircleItem(
                          context: context,
                          icon: Icons.groups_rounded,
                          title: 'Hội Đồng',
                          color: const Color(0xFF7C3AED),
                          onTap: () => _navigateToDashboard(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. THẺ TÓM TẮT NHANH QUY MÔ TOÀN KHOA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tóm Tắt Chỉ Số Toàn Khoa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Tổng đề tài',
                          _isLoading ? '...' : '${stats.totalTheses}',
                          const Color(0xFF1D4ED8),
                          colors,
                        ),
                      ),
                      Container(width: 1, height: 36, color: colors.cardBorder),
                      Expanded(
                        child: _buildMetricTile(
                          'Đã đăng ký',
                          _isLoading ? '...' : '${stats.registeredTheses}',
                          const Color(0xFF10B981),
                          colors,
                        ),
                      ),
                      Container(width: 1, height: 36, color: colors.cardBorder),
                      Expanded(
                        child: _buildMetricTile(
                          'GVHD trong kỳ',
                          _isLoading ? '...' : '${stats.activeLecturersCount}',
                          const Color(0xFF8B5CF6),
                          colors,
                        ),
                      ),
                    ],
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

  Widget _buildMetricTile(String title, String value, Color color, AppColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSquircleItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
