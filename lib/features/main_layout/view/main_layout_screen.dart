import 'package:flutter/material.dart';
import '../../../core/localization/app_language_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/model/user_model.dart';
import '../../profile/view/profile_view.dart';
import '../../student/view/student_home_view.dart';
import '../../student/view/student_schedule_view.dart';
import '../../lecturer/view/lecturer_home_view.dart';
import '../../manager/view/manager_home_view.dart';
import '../../notification/logic/notification_service.dart';
import '../../notification/view/notification_bottom_sheet.dart';

class MainLayoutScreen extends StatefulWidget {
  final UserModel user;

  const MainLayoutScreen({super.key, required this.user});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo kết nối SignalR thông báo realtime
    NotificationService().initSignalR();

    // Lắng nghe thông báo nổi In-App khi đang lướt app
    NotificationService().onNotificationReceived = (notif) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 20),
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0072E8).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF38BDF8),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    if (notif.message.isNotEmpty)
                      Text(
                        notif.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Xem',
            textColor: const Color(0xFF38BDF8),
            onPressed: () => NotificationBottomSheet.show(context),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    };
  }

  @override
  void dispose() {
    NotificationService().onNotificationReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isStudent = widget.user.isStudent;

    // Danh sách trang hiển thị cho Sinh viên (3 Tab)
    final List<Widget> studentPages = [
      StudentHomeView(
        user: widget.user,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      StudentScheduleView(user: widget.user),
      ProfileView(user: widget.user),
    ];

    // Danh sách trang cho Giảng viên / Quản lý (đầy đủ)
    final List<Widget> nonStudentPages = [
      widget.user.isLecturer ? LecturerHomeView(user: widget.user) : ManagerHomeView(user: widget.user),
      StudentScheduleView(user: widget.user),
      ProfileView(user: widget.user),
    ];


    final pages = isStudent ? studentPages : nonStudentPages;
    final colors = AppColors.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền chung (Ảnh nền ban ngày / Gradient tối cho Dark Mode)
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
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFE2F1FD), Color(0xFFF8FAFC), Color(0xFFE8F4FD)],
                        ),
                      ),
                    ),
                  ),
          ),
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 14,
        ),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: colors.bottomBarBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: colors.bottomBarBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : const Color(0xFF007AFF).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              if (!colors.isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, tr('nav_home')),
                _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_today_outlined, tr('nav_schedule')),
                _buildNavItem(2, Icons.person_rounded, Icons.person_outline_rounded, tr('nav_profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final colors = AppColors.of(context);
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? colors.navActive : colors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            // Vạch xanh báo active
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? colors.navActive : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
