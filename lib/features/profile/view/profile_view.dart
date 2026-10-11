import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_service.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/huit_loading.dart';
import '../../auth/model/user_model.dart';
import '../../auth/view/login_screen.dart';
import '../../notification/logic/notification_service.dart';
import '../../notification/view/notification_bell_button.dart';

class ProfileView extends StatefulWidget {
  final UserModel user;

  const ProfileView({super.key, required this.user});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Trạng thái các công tắc cài đặt (Mock tương tác UI)
  bool _twoStepVerification = false;
  bool _unlockFaceId = true;
  bool _timekeepingReminder = true;
  int _selectedThemeIndex = 0; // 0: Sun (Day), 1: Moon (Night), 2: Gear (System)
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final mode = AppThemeService().currentThemeMode;
    _selectedThemeIndex = mode == ThemeMode.dark ? 1 : (mode == ThemeMode.system ? 2 : 0);
  }

  void _showLogoutDialog(BuildContext context) async {
    final nav = Navigator.of(context);
    final confirm = await AppDialog.showConfirm(
      context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?',
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      type: DialogType.danger,
      icon: Icons.logout_rounded,
    );

    if (confirm == true) {
      await NotificationService().stop();
      await StorageService.clearAuth();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showPendingFeatureNotice(String featureName) {
    AppToast.showInfo(
      context,
      'Tính năng "$featureName" đang được phát triển.',
      title: 'Thông báo',
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _isRefreshing = false);
      AppToast.showSuccess(context, 'Đã cập nhật thông tin mới nhất!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.pageGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: _isRefreshing
          ? Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: const HuitLoading(
                size: 76,
                message: 'Đang làm mới thông tin...',
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: colors.sectionTitle,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    // HEADER DẠNG VIÊN THUỐC NỔI (BLUE CAPSULE)
                    _buildHeaderPill(),

            const SizedBox(height: 16),

            // CARD 1: THÔNG TIN KHOA & HỌC TẬP (TỪ ĐƠN VỊ / KHOA TRỞ XUỐNG)
            _buildStudentInfoCard(),

            const SizedBox(height: 16),

            // CARD 2: LOGIN & BẢO MẬT
            _buildLoginSectionCard(),

            const SizedBox(height: 16),

            // CARD 3: SETTING
            _buildSettingSectionCard(),

            const SizedBox(height: 16),

            // CARD 4: SUPPORT
            _buildSupportSectionCard(),

            const SizedBox(height: 20),

            // CARD 5: NÚT LOGOUT
            _buildLogoutButton(),

                    const SizedBox(height: 70), // Khoảng đệm cho bottom navigation bar
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================
  // HEADER DẠNG VIÊN THUỐC NỔI (ẢNH 1)
  // ==========================================
  Widget _buildHeaderPill() {
    final user = widget.user;

    return Container(
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
          // Avatar tròn viền trắng tinh tế
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white.withValues(alpha: 0.25),
              image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(user.avatarUrl!),
                      fit: BoxFit.cover,
                    )
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

          // Quả chuông thông báo realtime
          const NotificationBellButton(),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 1: THẺ THÔNG TIN ĐƠN VỊ KHOA & HỌC TẬP (ẢNH 2)
  // ==========================================
  Widget _buildStudentInfoCard() {
    final user = widget.user;

    return _buildSectionCard(
      title: 'Thông tin sinh viên',
      children: [
        _buildInfoRow('Đơn vị / Khoa', 'Khoa Công Nghệ Thông Tin - HUIT'),
        _buildDivider(),
        _buildInfoRow('Ngành học', 'Công nghệ thông tin'),
        _buildDivider(),
        _buildInfoRow('Lớp sinh hoạt', '11DHTH05'),
        _buildDivider(),
        _buildInfoRow('Email liên hệ', user.email),
        _buildDivider(),
        _buildInfoRow('Đợt khóa luận', 'Khóa luận tốt nghiệp 2026'),
        _buildDivider(),
        _buildInfoRow('Trạng thái', 'Đang thực hiện', isStatus: true),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.2,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.2,
                fontWeight: isStatus ? FontWeight.w800 : FontWeight.w600,
                color: isStatus ? colors.sectionTitle : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 16, thickness: 0.7, color: AppColors.of(context).divider);
  }

  // ==========================================
  // CARD 2: SECTION LOGIN
  // ==========================================
  Widget _buildLoginSectionCard() {
    return _buildSectionCard(
      title: 'Login',
      children: [
        _buildSettingItem(
          icon: Icons.shield_outlined,
          title: 'Two-step verification',
          trailing: Switch(
            value: _twoStepVerification,
            activeThumbColor: const Color(0xFF0284C7),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) {
              setState(() => _twoStepVerification = val);
            },
          ),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.notifications_outlined,
          title: 'Unlock quick by FaceID',
          trailing: Switch(
            value: _unlockFaceId,
            activeThumbColor: const Color(0xFF0284C7),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) {
              setState(() => _unlockFaceId = val);
            },
          ),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.lock_outline_rounded,
          title: 'Change password',
          onTap: () => _showPendingFeatureNotice('Đổi mật khẩu'),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.help_outline_rounded,
          title: 'Signed-in device',
          onTap: () => _showPendingFeatureNotice('Thiết bị đã đăng nhập'),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 3: SECTION SETTING
  // ==========================================
  Widget _buildSettingSectionCard() {
    return _buildSectionCard(
      title: 'Setting',
      children: [
        _buildSettingItem(
          icon: Icons.language_rounded,
          title: 'Language',
          onTap: () => _showPendingFeatureNotice('Ngôn ngữ'),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.nightlight_round_outlined,
          title: 'Interface',
          trailing: _buildThemeSegment(),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notification settings',
          onTap: () => _showPendingFeatureNotice('Cài đặt thông báo'),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.lock_outline_rounded,
          title: 'Timekeeping reminder',
          trailing: Switch(
            value: _timekeepingReminder,
            activeThumbColor: const Color(0xFF0284C7),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val) {
              setState(() => _timekeepingReminder = val);
            },
          ),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.help_outline_rounded,
          title: 'Display a reminder',
          onTap: () => _showPendingFeatureNotice('Hiển thị nhắc nhở'),
        ),
        _buildItemDivider(),
        _buildSettingItem(
          icon: Icons.info_outline_rounded,
          title: 'Version',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1.0.60 ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              Text(
                '(Latest)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).sectionTitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 4: SECTION SUPPORT
  // ==========================================
  Widget _buildSupportSectionCard() {
    return _buildSectionCard(
      title: 'Support',
      children: [
        _buildSettingItem(
          icon: Icons.help_outline_rounded,
          title: 'Respond to a reminder',
          onTap: () => _showPendingFeatureNotice('Phản hồi nhắc nhở'),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 5: NÚT LOGOUT RIÊNG BIỆT DƯỚI CÙNG
  // ==========================================
  Widget _buildLogoutButton() {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: colors.logoutBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.logoutBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: colors.isDark ? 0.08 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogoutDialog(context),
          child: Center(
            child: Text(
              'Logout',
              style: TextStyle(
                color: colors.logoutText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS DÙNG CHUNG CHO CÁC KHỐI
  // ==========================================
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF007AFF).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          if (!colors.isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề Section (màu xanh dương)
          Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: colors.sectionTitle,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colors = AppColors.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 21, color: colors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: colors.textMuted,
              ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildItemDivider() {
    return Divider(height: 16, thickness: 0.7, color: AppColors.of(context).divider);
  }

  // Toggle giao diện 3 chế độ [☀️ Sáng, 🌙 Tối, ⚙️ Hệ thống]
  Widget _buildThemeSegment() {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.segmentBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentOption(
            icon: Icons.wb_sunny_rounded,
            isSelected: _selectedThemeIndex == 0,
            activeColor: const Color(0xFFF59E0B),
            onTap: () {
              setState(() => _selectedThemeIndex = 0);
              AppThemeService().setThemeMode(ThemeMode.light);
            },
          ),
          const SizedBox(width: 4),
          _buildSegmentOption(
            icon: Icons.nightlight_round,
            isSelected: _selectedThemeIndex == 1,
            activeColor: const Color(0xFF0084FF),
            onTap: () {
              setState(() => _selectedThemeIndex = 1);
              AppThemeService().setThemeMode(ThemeMode.dark);
            },
          ),
          const SizedBox(width: 4),
          _buildSegmentOption(
            icon: Icons.settings_rounded,
            isSelected: _selectedThemeIndex == 2,
            activeColor: const Color(0xFF64748B),
            onTap: () {
              setState(() => _selectedThemeIndex = 2);
              AppThemeService().setThemeMode(ThemeMode.system);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOption({
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 15,
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
