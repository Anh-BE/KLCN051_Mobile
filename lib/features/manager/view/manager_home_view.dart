import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/model/user_model.dart';
import 'manager_detailed_stats_screen.dart';
import '../../notification/view/notification_bell_button.dart';

class ManagerHomeView extends StatelessWidget {
  final UserModel user;

  const ManagerHomeView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

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

          // 2. DASHBOARD NHANH (THU THẬP DỮ LIỆU & HIỂN THỊ TỨC THÌ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dashboard Tổng quan Nhanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.sectionTitle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 12,
                            color: colors.isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đồng bộ tự động',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lưới 4 ô chỉ số nghiệp vụ chính
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(colors, '124', 'Đề tài đã công bố', Icons.article_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(colors, '248', 'Sinh viên đủ ĐK', Icons.groups_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(colors, '35', 'Giảng viên HD', Icons.co_present_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(colors, '14%', 'Tỷ lệ nộp trễ (23:59)', Icons.assignment_late_rounded, const Color(0xFFEA580C), const Color(0xFFFFEDD5)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // NÚT TRUY CẬP SỐ LIỆU TỔNG HỢP CHI TIẾT THEO LUỒNG LOGIC
                Container(
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
              ],
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
                  _buildProgressRow(colors, 'Tỷ lệ đề tài được BCN duyệt', 0.92, '92% (114/124)', const Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  _buildProgressRow(colors, 'Tỷ lệ nhóm sinh viên đã ghép đủ', 0.85, '85% (106/124 nhóm)', const Color(0xFF0284C7)),
                  const SizedBox(height: 12),
                  _buildProgressRow(colors, 'Tỷ lệ sinh viên nộp báo cáo đúng hạn (< 23:59)', 0.82, '82%', const Color(0xFF059669)),
                  const SizedBox(height: 12),
                  _buildProgressRow(colors, 'Tỷ lệ sinh viên nộp trễ hạn (> 23:59)', 0.14, '14%', const Color(0xFFEA580C)),
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
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(AppColors colors, String value, String title, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.isDark ? iconColor.withValues(alpha: 0.18) : bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: iconColor)),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

