import 'package:flutter/material.dart';
import '../../../core/localization/app_language_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_service.dart';
import '../../auth/model/user_model.dart';
import '../group/logic/student_group_service.dart';
import '../group/view/student_group_list_screen.dart';
import '../group/view/student_manage_group_screen.dart';
import '../model/registration_period_model.dart';
import '../topic/view/student_topic_list_screen.dart';
import '../../notification/logic/notification_service.dart';
import '../../notification/view/notification_bell_button.dart';
import 'widgets/period_selection_dialog.dart';

class StudentHomeView extends StatefulWidget {
  final UserModel user;
  final Function(int)? onTabChange;

  const StudentHomeView({super.key, required this.user, this.onTabChange});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView> {
  bool _hasShownImportantPopupInSession = false;
  List<RegistrationPeriodModel> _studentPeriods = [];
  RegistrationPeriodModel? _currentSelectedPeriod;

  UserModel get user => widget.user;
  Function(int)? get onTabChange => widget.onTabChange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStudentPeriods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Chiều cao tối thiểu để khung trắng kéo dài xuống sát thanh bottom navigation bar
        final minCardHeight = (constraints.maxHeight - 200).clamp(360.0, 3000.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. HEADER DẠNG VIÊN THUỐC NỔI (FLOATING PILL CAPSULE) CHUẨN TRANG CHỦ
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
                      // Avatar tròn viền trắng
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white.withValues(alpha: 0.25),
                          image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                              ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 14),

                      // Tên và MSSV
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

                      // Quả chuông thông báo (Hiển thị badge số lượng thông báo realtime & mở ngăn kéo thông báo 85%)
                      NotificationBellButton(
                        iconColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. KHỐI CARD CHỨC NĂNG CHÍNH KÉO DÀI XUỐNG SÁT BOTTOM BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  constraints: BoxConstraints(minHeight: minCardHeight),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
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
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _studentPeriods.length >= 2
                                ? () {
                                    _openPeriodSelectionDialog(canCancel: true);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _studentPeriods.length >= 2
                                    ? (colors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE))
                                    : (colors.isDark ? const Color(0xFF232529) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                                border: _studentPeriods.length >= 2
                                    ? Border.all(
                                        color: const Color(0xFF0072E8).withValues(alpha: 0.35),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 160),
                                    child: Text(
                                      _currentSelectedPeriod != null
                                          ? _currentSelectedPeriod!.periodName
                                          : 'Chưa có đợt',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _studentPeriods.length >= 2
                                            ? const Color(0xFF0072E8)
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (_studentPeriods.length >= 2) ...[
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 15,
                                      color: Color(0xFF0072E8),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // HÀNG 4 CHỨC NĂNG DÀN ĐỀU (PHONG CÁCH SQUIRCLE APP ICON)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Xem nhóm (Navy Blue)
                          Expanded(
                            child: _buildSquircleActionItem(
                              context: context,
                              icon: Icons.groups_rounded,
                              title: tr('view_group'),
                              color: const Color(0xFF1D4ED8),
                              onTap: () async {
                                final targetIndex = await Navigator.of(context).push<int>(
                                  MaterialPageRoute(
                                    builder: (_) => StudentGroupListScreen(user: user),
                                  ),
                                );
                                if (targetIndex != null && onTabChange != null) {
                                  onTabChange!(targetIndex);
                                }
                              },
                            ),
                          ),

                          // 2. Tạo / Mời nhóm (Dark Emerald / Teal)
                          Expanded(
                            child: _buildSquircleActionItem(
                              context: context,
                              icon: Icons.person_add_alt_1_rounded,
                              title: tr('create_invite_group'),
                              color: const Color(0xFF0F766E),
                              onTap: () async {
                                final targetIndex = await Navigator.of(context).push<int>(
                                  MaterialPageRoute(
                                    builder: (_) => StudentManageGroupScreen(user: user),
                                  ),
                                );
                                if (targetIndex != null && onTabChange != null) {
                                  onTabChange!(targetIndex);
                                }
                              },
                            ),
                          ),

                          // 3. Đăng ký đề tài (Royal Purple / Violet)
                          Expanded(
                            child: _buildSquircleActionItem(
                              context: context,
                              icon: Icons.description_rounded,
                              title: tr('register_topic'),
                              color: const Color(0xFF6B21A8),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentTopicListScreen(user: user),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 4. Lịch tiến độ (Raspberry / Burgundy)
                          Expanded(
                            child: _buildSquircleActionItem(
                              context: context,
                              icon: Icons.calendar_month_rounded,
                              title: tr('nav_schedule'),
                              color: const Color(0xFF9E1B42),
                              onTap: () {
                                if (onTabChange != null) {
                                  onTabChange!(1);
                                }
                              },
                            ),
                          ),
                        ],
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

  Future<void> _checkStudentPeriods() async {
    if (!mounted) {
      return;
    }

    final periods = await StudentGroupService().getMyPeriods(forceRefresh: true);
    if (!mounted) {
      return;
    }

    _studentPeriods = periods;

    if (periods.isEmpty) {
      if (mounted) {
        setState(() {
          _currentSelectedPeriod = null;
        });
        _checkAndShowImportantNotificationDialog();
      }
      return;
    }

    if (periods.length == 1) {
      final onlyPeriod = periods.first;
      await StudentGroupService().switchPeriod(onlyPeriod);
      if (mounted) {
        setState(() {
          _currentSelectedPeriod = onlyPeriod;
        });
        _checkAndShowImportantNotificationDialog();
      }
      return;
    }

    // Có từ 2 đợt trở lên (tham gia song song)
    final savedPeriodId = await StorageService.getSelectedPeriodId();
    RegistrationPeriodModel? matchedPeriod;
    if (savedPeriodId != null && savedPeriodId > 0) {
      for (final p in periods) {
        if (p.periodId == savedPeriodId) {
          matchedPeriod = p;
          break;
        }
      }
    }

    if (matchedPeriod != null) {
      if (mounted) {
        setState(() {
          _currentSelectedPeriod = matchedPeriod;
        });
        _checkAndShowImportantNotificationDialog();
      }
    } else {
      // Vừa đăng nhập hoặc chưa chọn đợt -> Bắt buộc mở dialog chọn đợt (canCancel = false)
      if (mounted) {
        _openPeriodSelectionDialog(canCancel: false);
      }
    }
  }

  Future<void> _openPeriodSelectionDialog({required bool canCancel}) async {
    if (_studentPeriods.isEmpty) {
      return;
    }

    await PeriodSelectionDialog.show(
      context: context,
      periods: _studentPeriods,
      currentSelectedPeriodId: _currentSelectedPeriod?.periodId,
      canCancel: canCancel,
      onPeriodSelected: (selectedPeriod) async {
        await StudentGroupService().switchPeriod(selectedPeriod);
        if (mounted) {
          setState(() {
            _currentSelectedPeriod = selectedPeriod;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0A58CA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đã vào không gian: ${selectedPeriod.periodName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );

    if (!canCancel && mounted) {
      _checkAndShowImportantNotificationDialog();
    }
  }

  /// Tự động hiển thị popup thông báo quan trọng ở giữa màn hình khi mở trang chủ
  void _checkAndShowImportantNotificationDialog() async {
    if (!mounted || _hasShownImportantPopupInSession) {
      return;
    }

    final service = NotificationService();
    if (service.notifications.isEmpty) {
      await service.getNotifications(limit: 20);
      if (!mounted) return;
    }

    final urgentList = service.notifications.where((n) {
      final title = n.title.toLowerCase();
      final msg = n.message.toLowerCase();
      return !n.isRead && (
        n.category == 'group_invite' ||
        n.category == 'group_request' ||
        n.category == 'student' ||
        n.type == 'warning' ||
        n.type == 'danger' ||
        title.contains('lời mời') ||
        title.contains('yêu cầu') ||
        msg.contains('lời mời') ||
        msg.contains('yêu cầu')
      );
    }).toList();

    if (urgentList.isEmpty) {
      return;
    }

    _hasShownImportantPopupInSession = true;
    final item = urgentList.first;
    final colors = AppColors.of(context);


    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
            decoration: BoxDecoration(
              color: colors.isDark ? const Color(0xFF1E222A) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: colors.isDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tiêu đề: "Thông báo"
                Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w700,
                    color: colors.isDark ? Colors.white : const Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Nội dung thông báo căn trái, màu xám chuẩn theo ảnh
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6679),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Hai nút căn hai bên trái/phải hình chữ nhật
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút bên trái: "Quay lại"
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        service.markAsRead(item.notificationId);
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.isDark ? const Color(0xFF2A2D34) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Quay lại',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: colors.isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),

                    // Nút bên phải: "Chi tiết"
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        service.markAsRead(item.notificationId);
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentManageGroupScreen(
                              user: widget.user,
                              initialTab: 1,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A58CA),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A58CA).withValues(alpha: 0.38),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


