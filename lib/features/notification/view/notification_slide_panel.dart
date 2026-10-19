import 'package:flutter/material.dart';
import '../../../core/utils/storage_service.dart';
import '../../auth/model/user_model.dart';
import '../../student/group/view/student_manage_group_screen.dart';
import '../../student/topic/view/student_topic_list_screen.dart';
import '../../lecturer/review_report/view/lecturer_weekly_report_list_screen.dart';
import '../../lecturer/topic/view/lecturer_topic_list_screen.dart';
import '../logic/notification_service.dart';
import '../model/notification_model.dart';

class NotificationSlidePanel extends StatefulWidget {
  final UserModel? user;

  const NotificationSlidePanel({super.key, this.user});

  /// Mở trang thông báo dạng ngăn kéo (Slide Panel) 85% màn hình từ phải qua trái
  static Future<void> show(BuildContext context, {UserModel? user}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NotificationSlidePanel',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return NotificationSlidePanel(user: user);
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  State<NotificationSlidePanel> createState() => _NotificationSlidePanelState();
}

class _NotificationSlidePanelState extends State<NotificationSlidePanel>
    with SingleTickerProviderStateMixin {
  final NotificationService _service = NotificationService();
  late TabController _tabController;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUser = widget.user;
    _initUserAndData();
  }

  Future<void> _initUserAndData() async {
    if (_currentUser == null) {
      final user = await StorageService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
    _service.fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Tiêu đề tab riêng tùy theo vai trò của tài khoản
  String get _roleTabTitle {
    final user = _currentUser;
    if (user == null) return 'Thông báo riêng';
    if (user.isStudent) return 'Thông báo sinh viên';
    if (user.isLecturer) return 'Thông báo giảng viên';
    if (user.isDeanOrAdmin) return 'Thông báo quản lý';
    return 'Thông báo riêng';
  }

  /// Phân loại: Thông báo chung
  bool _isGeneralNotification(AppNotification item) {
    final cat = item.category.toLowerCase();
    final title = item.title.toLowerCase();
    return cat == 'general' ||
        cat == 'announcement' ||
        cat == 'period_plan' ||
        cat == 'system' ||
        cat == 'broadcast' ||
        title.contains('kế hoạch') ||
        title.contains('thông báo chung') ||
        title.contains('toàn khoa') ||
        title.contains('quy định') ||
        title.contains('đợt');
  }

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width * 0.85;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 24,
                offset: Offset(-6, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                final allNotifs = _service.notifications;
                final generalList = allNotifs.where(_isGeneralNotification).toList();
                final roleList = allNotifs.where((n) => !_isGeneralNotification(n)).toList();

                final unreadGeneral = generalList.where((n) => !n.isRead).length;
                final unreadRole = roleList.where((n) => !n.isRead).length;
                final totalUnread = _service.unreadCount;

                return Column(
                  children: [
                    // 1. HEADER NGĂN KÉO
                    _buildHeader(totalUnread),

                    // 2. TAB BAR (2 TAB: CHUNG & THEO VAI TRÒ)
                    _buildTabBar(unreadGeneral, unreadRole),

                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                    // 3. TAB BAR VIEW NỘI DUNG
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotificationList(
                            items: generalList,
                            emptyMessage: 'Chưa có thông báo chung nào',
                            emptySubMessage: 'Các kế hoạch, tin tức đợt khóa luận sẽ hiển thị tại đây.',
                          ),
                          _buildNotificationList(
                            items: roleList,
                            emptyMessage: 'Chưa có $_roleTabTitle nào',
                            emptySubMessage: 'Các nhắc nhở về đề tài, nhóm và tiến độ sẽ hiển thị tại đây.',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int totalUnread) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7.5),
            decoration: BoxDecoration(
              color: const Color(0xFF0072E8).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF0072E8),
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'Thông báo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          if (totalUnread > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$totalUnread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (totalUnread > 0)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _service.markAllAsRead(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Đọc tất cả',
                  style: TextStyle(
                    color: Color(0xFF0072E8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int unreadGeneral, int unreadRole) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF0072E8),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        indicatorColor: const Color(0xFF0072E8),
        indicatorWeight: 2.8,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Thông báo chung'),
                if (unreadGeneral > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$unreadGeneral',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _roleTabTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadRole > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$unreadRole',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList({
    required List<AppNotification> items,
    required String emptyMessage,
    required String emptySubMessage,
  }) {
    if (_service.isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0072E8)),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF0072E8),
        onRefresh: () => _service.fetchNotifications(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 32,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emptySubMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0072E8),
      onRefresh: () => _service.fetchNotifications(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildNotificationItem(item);
        },
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification item) {
    Color iconBg = const Color(0xFFEFF6FF);
    Color iconColor = const Color(0xFF0072E8);
    IconData icon = Icons.notifications_rounded;

    final type = item.type.toLowerCase();
    final category = item.category.toLowerCase();

    if (type.contains('danger') || type.contains('error')) {
      iconBg = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFEF4444);
      icon = Icons.error_outline_rounded;
    } else if (type.contains('success')) {
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (type.contains('warning') || category.contains('thesis')) {
      iconBg = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFF97316);
      icon = Icons.assignment_turned_in_rounded;
    } else if (category.contains('invite') || category.contains('group')) {
      iconBg = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF059669);
      icon = Icons.group_add_rounded;
    } else if (category.contains('report') || category.contains('progress')) {
      iconBg = const Color(0xFFEEF2FF);
      iconColor = const Color(0xFF4F46E5);
      icon = Icons.assessment_outlined;
    }

    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleItemTap(item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
              width: item.isRead ? 1 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7.5,
                            height: 7.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0072E8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          item.timeAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleItemTap(AppNotification item) async {
    if (!item.isRead) {
      await _service.markAsRead(item.notificationId);
    }

    if (!mounted) return;
    final actionUrl = (item.actionUrl ?? '').toLowerCase();
    final user = _currentUser ?? await StorageService.getUser();
    if (!mounted || user == null) return;

    if (actionUrl.contains('group')) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentManageGroupScreen(user: user),
        ),
      );
    } else if (actionUrl.contains('topic') || actionUrl.contains('thes')) {
      Navigator.of(context).pop();
      if (user.isLecturer) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LecturerTopicListScreen(user: user),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentTopicListScreen(user: user),
          ),
        );
      }
    } else if (actionUrl.contains('report') || actionUrl.contains('progress')) {
      Navigator.of(context).pop();
      if (user.isLecturer) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LecturerWeeklyReportListScreen(user: user),
          ),
        );
      }
    }
  }
}
