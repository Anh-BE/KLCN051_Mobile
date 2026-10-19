import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_service.dart';
import '../../auth/model/user_model.dart';
import '../../student/group/view/student_manage_group_screen.dart';
import '../../student/topic/view/student_topic_list_screen.dart';
import '../../lecturer/review_report/view/lecturer_weekly_report_list_screen.dart';
import '../../lecturer/topic/view/lecturer_topic_list_screen.dart';
import '../logic/notification_service.dart';
import '../model/notification_model.dart';

class AppNotificationScreen extends StatefulWidget {
  final UserModel? user;

  const AppNotificationScreen({super.key, this.user});

  /// Mở trang thông báo toàn màn hình với hiệu ứng trượt từ phải qua trái
  static Future<void> show(BuildContext context, {UserModel? user}) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return AppNotificationScreen(user: user);
        },
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<AppNotificationScreen> createState() => _AppNotificationScreenState();
}

class _AppNotificationScreenState extends State<AppNotificationScreen>
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
    if (user == null) return 'Thông báo cá nhân';
    if (user.isStudent) return 'Thông báo sinh viên';
    if (user.isLecturer) return 'Thông báo giảng viên';
    if (user.isDeanOrAdmin) return 'Thông báo quản lý';
    return 'Thông báo cá nhân';
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ảnh nền tương đồng với các trang khác trong ứng dụng
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
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
          ),

          // 2. Nội dung chính: Thanh viên thuốc phía trên + Khung 2 tab ở dưới
          SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) {
                final allNotifs = _service.notifications;
                final generalList = allNotifs.where(_isGeneralNotification).toList();
                final roleList = allNotifs.where((n) => !_isGeneralNotification(n)).toList();

                final unreadGeneral = generalList.where((n) => !n.isRead).length;
                final unreadRole = roleList.where((n) => !n.isRead).length;

                return Column(
                  children: [
                    // TOP APP BAR DẠNG VIÊN THUỐC GRADIENT CÓ ICON BACK
                    _buildHeader(),

                    const SizedBox(height: 6),

                    // KHUNG TRẮNG Ở DƯỚI CHIA LÀM 2 TAB
                    Expanded(
                      child: _buildMainFrame(
                        colors: colors,
                        generalList: generalList,
                        roleList: roleList,
                        unreadGeneral: unreadGeneral,
                        unreadRole: unreadRole,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top App Bar dạng viên thuốc gradient với icon back
  Widget _buildHeader() {
    final totalUnread = _service.unreadCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              color: const Color(0xFF007AFF).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Quay lại',
            ),
            const Expanded(
              child: Text(
                'THÔNG BÁO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (totalUnread > 0)
              TextButton(
                onPressed: () => _service.markAllAsRead(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Đọc tất cả',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  /// 2. Khung ở dưới bo góc chứa 2 Tab (Thông báo chung & Thông báo vai trò)
  Widget _buildMainFrame({
    required AppColors colors,
    required List<AppNotification> generalList,
    required List<AppNotification> roleList,
    required int unreadGeneral,
    required int unreadRole,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.cardBorder, width: 1.2),
          left: BorderSide(color: colors.cardBorder, width: 1.2),
          right: BorderSide(color: colors.cardBorder, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Segmented TabBar chọn tab
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colors.isDark ? const Color(0xFF2C3038) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF0072E8),
              unselectedLabelColor: colors.textSecondary,
              labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Thông báo chung'),
                      if (unreadGeneral > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadGeneral',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
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
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadRole',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: colors.divider),

          // Nội dung từng tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(
                  colors: colors,
                  items: generalList,
                  emptyMessage: 'Chưa có thông báo chung nào',
                  emptySubMessage: 'Các kế hoạch, quy chế đợt khóa luận sẽ hiển thị tại đây.',
                ),
                _buildNotificationList(
                  colors: colors,
                  items: roleList,
                  emptyMessage: 'Chưa có $_roleTabTitle nào',
                  emptySubMessage: 'Các nhắc nhở về đề tài, nhóm và tiến độ cá nhân sẽ hiển thị tại đây.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Danh sách thông báo trong từng Tab
  Widget _buildNotificationList({
    required AppColors colors,
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 34,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emptySubMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildNotificationItem(colors, item);
        },
      ),
    );
  }

  /// Thẻ thông báo từng mục
  Widget _buildNotificationItem(AppColors colors, AppNotification item) {
    Color iconBg = colors.isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.25) : const Color(0xFFEFF6FF);
    Color iconColor = const Color(0xFF0072E8);
    IconData icon = Icons.notifications_rounded;

    final type = item.type.toLowerCase();
    final category = item.category.toLowerCase();

    if (type.contains('danger') || type.contains('error')) {
      iconBg = colors.isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFEF4444);
      icon = Icons.error_outline_rounded;
    } else if (type.contains('success')) {
      iconBg = colors.isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (type.contains('warning') || category.contains('thesis')) {
      iconBg = colors.isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.3) : const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFF97316);
      icon = Icons.assignment_turned_in_rounded;
    } else if (category.contains('invite') || category.contains('group')) {
      iconBg = colors.isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF059669);
      icon = Icons.group_add_rounded;
    } else if (category.contains('report') || category.contains('progress')) {
      iconBg = colors.isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEEF2FF);
      iconColor = const Color(0xFF4F46E5);
      icon = Icons.assessment_outlined;
    }

    return Material(
      color: item.isRead
          ? colors.cardBg
          : (colors.isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFD)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleItemTap(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? colors.cardBorder
                  : (colors.isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
              width: item.isRead ? 1 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
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
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0072E8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.timeAgo,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textMuted,
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentManageGroupScreen(user: user),
        ),
      );
    } else if (actionUrl.contains('topic') || actionUrl.contains('thes')) {
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
