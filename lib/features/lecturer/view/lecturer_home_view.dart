import 'dart:async';
import 'package:flutter/material.dart';
import '../../auth/model/user_model.dart';
import '../../notification/logic/notification_service.dart';
import '../../notification/view/notification_sheet.dart';
import '../review_report/view/lecturer_weekly_report_list_screen.dart';
import '../scoring/view/lecturer_scoring_list_screen.dart';
import '../topic/view/lecturer_topic_list_screen.dart';
import '../../../core/widgets/donut_stat_card.dart';
import '../../dashboard/logic/dashboard_service.dart';
import '../../dashboard/model/dashboard_stats_models.dart';


class LecturerHomeView extends StatefulWidget {
  final UserModel user;

  const LecturerHomeView({super.key, required this.user});

  @override
  State<LecturerHomeView> createState() => _LecturerHomeViewState();
}

class _LecturerHomeViewState extends State<LecturerHomeView> {
  final NotificationService _notificationService = NotificationService();
  final DashboardService _dashboardService = DashboardService();
  int _unreadCount = 0;
  LecturerDashboardStats _stats = LecturerDashboardStats();
  bool _isLoadingStats = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _loadDashboardStats();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchUnreadCount();
    });
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
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted && count != _unreadCount) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _openNotifications() {
    NotificationSheet.show(
      context,
      user: widget.user,
      onNotificationChanged: _fetchUnreadCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER GRADIENT DÀNH CHO GIẢNG VIÊN
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
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
                // Avatar tròn
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
                      ? const Icon(Icons.school, color: Colors.white, size: 30)
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
                        'Mã GV: ${user.identifierCode} • Giảng viên hướng dẫn',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
// Quả chuông thông báo có badge
                InkWell(
                  onTap: _openNotifications,
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              _unreadCount > 99 ? '99+' : '$_unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. LƯỚI CÁC CHỨC NĂNG TRỌNG TÂM CỦA GIẢNG VIÊN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFF0D9488), size: 22),
                      SizedBox(width: 6),
                      Text(
                        'Thao tác dành cho Giảng viên',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        icon: Icons.list_alt_rounded,
                        label: 'Đề tài & Trạng thái',
                        bgColor: const Color(0xFFF0FDF4),
                        iconColor: const Color(0xFF16A34A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LecturerTopicListScreen(user: user),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.rate_review_outlined,
                        label: 'Xem báo cáo tuần',
                        bgColor: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LecturerWeeklyReportListScreen(user: user),
                            ),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.edit_note_rounded,
                        label: 'Nhập điểm phân công',
                        bgColor: const Color(0xFFFAF5FF),
                        iconColor: const Color(0xFF9333EA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LecturerScoringListScreen(user: user),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 3. BIỂU ĐỒ TRÒN THỐNG KÊ ĐỀ TÀI & HƯỚNG DẪN CỦA GIẢNG VIÊN (CHUẨN THIẾT KẾ DONUT)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _isLoadingStats
                ? Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F766E), strokeWidth: 2.5),
                    ),
                  )
                : DonutStatCard(
                    title: 'Trạng thái Đề xuất Đề tài',
                    filterPillText: _stats.periodName,
                    topSummaryWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 20, color: Color(0xFF0F766E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                children: [
                                  const TextSpan(text: 'Đang hướng dẫn: '),
                                  TextSpan(
                                    text: '${_stats.supervisedThesesCount} đề tài',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                                  ),
                                  TextSpan(
                                    text: ' (${_stats.supervisedGroupsCount} nhóm) • ',
                                  ),
                                  const TextSpan(text: 'Tổng đề xuất: '),
                                  TextSpan(
                                    text: '${_stats.totalProposed}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
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
                        value: _stats.approvedCount,
                        label: 'Được duyệt',
                        progressPercent: _stats.totalProposed > 0 ? _stats.approvedCount / _stats.totalProposed : 0.0,
                        color: const Color(0xFF16A34A),
                      ),
                      DonutStatItem(
                        value: _stats.needsRevisionCount,
                        label: 'Cần chỉnh sửa',
                        progressPercent: _stats.totalProposed > 0 ? _stats.needsRevisionCount / _stats.totalProposed : 0.0,
                        color: const Color(0xFFD97706),
                      ),
                      DonutStatItem(
                        value: _stats.rejectedCount,
                        label: 'Không duyệt',
                        progressPercent: _stats.totalProposed > 0 ? _stats.rejectedCount / _stats.totalProposed : 0.0,
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 18),

          // 4. BANNER THÔNG TIN HƯỚNG DẪN TIẾN ĐỘ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theo dõi báo cáo tiến độ tuần',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Giảng viên duyệt kế hoạch tuần và chấm điểm nhận xét báo cáo định kỳ cho các nhóm sinh viên tại mục Xem báo cáo tuần.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
