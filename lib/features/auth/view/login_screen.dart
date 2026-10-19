import 'package:flutter/material.dart';
import '../../../core/localization/app_language_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_service.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/huit_loading.dart';
import '../../main_layout/view/main_layout_screen.dart';
import '../logic/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  AppColors get _colors => AppColors.of(context);

  final String _logoUrl = 'https://res.cloudinary.com/wpyhssfm/image/upload/logohuit';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final savedUsername = await StorageService.getSavedUsername();
    final rememberMe = await StorageService.getRememberMe();
    if (savedUsername != null && savedUsername.isNotEmpty) {
      setState(() {
        _usernameController.text = savedUsername;
        _rememberMe = rememberMe;
      });
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      AppToast.showError(
        context,
        tr('username_empty'),
        title: 'Chưa nhập thông tin',
      );
      return;
    }
    if (password.isEmpty) {
      AppToast.showError(
        context,
        tr('password_empty'),
        title: 'Chưa nhập thông tin',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService().login(username, password, _rememberMe);

      if (!mounted) {
        return;
      }

      AppToast.showSuccess(
        context,
        'Xin chào ${result.user.fullName}!',
        title: 'Đăng nhập thành công',
      );

      // Giữ màn hình loading HUIT chuyển tiếp mượt mà sang trang chủ
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainLayoutScreen(user: result.user),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      AppToast.showError(
        context,
        errorMsg,
        title: 'Đăng nhập thất bại',
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final brandColor = _colors.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0B519C);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _colors.isDark
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _colors.pageGradient,
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/bg_login.png',
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
            child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. THANH TIỆN ÍCH TRÊN CÙNG
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _colors.cardBg.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _colors.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PopupMenuButton<String>(
                                    tooltip: 'Language',
                                    offset: const Offset(0, 34),
                                    color: _colors.cardBg,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    onSelected: (code) {
                                      AppLanguageService().setLanguage(code);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'vi',
                                        child: Row(
                                          children: [
                                            Text('🇻🇳', style: TextStyle(fontSize: 16)),
                                            SizedBox(width: 8),
                                            Text('Tiếng Việt', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'en',
                                        child: Row(
                                          children: [
                                            Text('🇬🇧', style: TextStyle(fontSize: 16)),
                                            SizedBox(width: 8),
                                            Text('English', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            AppLanguageService().isVietnamese ? '🇻🇳 VI' : '🇬🇧 EN',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _colors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.keyboard_arrow_down, size: 16, color: _colors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text('|', style: TextStyle(color: _colors.cardBorder, fontSize: 12)),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      final isDark = _colors.isDark;
                                      AppThemeService().setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Icon(
                                        _colors.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                        size: 16,
                                        color: const Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(flex: 2),

                          // 2. KHU VỰC THƯƠNG HIỆU: LOGO + TÊN TRƯỜNG
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.network(
                                _logoUrl,
                                height: 86,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.school,
                                  size: 70,
                                  color: brandColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'TRƯỜNG ĐẠI HỌC',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: brandColor,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 3),
                                    padding: const EdgeInsets.only(bottom: 2),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: brandColor,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'CÔNG THƯƠNG TP. HCM',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: brandColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'HCMC UNIVERSITY OF INDUSTRY AND TRADE',
                                    style: TextStyle(
                                      fontSize: 10.2,
                                      fontWeight: FontWeight.w700,
                                      color: brandColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const Spacer(flex: 2),

                          // 3. KHUNG TRẮNG FORM ĐĂNG NHẬP
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                color: _colors.cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: _colors.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: _colors.isDark ? 0.35 : 0.08),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ô 1: Mã số SV / Tên đăng nhập
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _colors.inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _colors.inputBorder),
                                    ),
                                    child: TextField(
                                      controller: _usernameController,
                                      textInputAction: TextInputAction.next,
                                      style: TextStyle(fontSize: 15, color: _colors.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: tr('username_hint'),
                                        hintStyle: TextStyle(color: _colors.textMuted, fontSize: 14.5),
                                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF0284C7), size: 22),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Ô 2: Mật khẩu
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _colors.inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _colors.inputBorder),
                                    ),
                                    child: TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _handleLogin(),
                                      style: TextStyle(fontSize: 15, color: _colors.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: tr('password_hint'),
                                        hintStyle: TextStyle(color: _colors.textMuted, fontSize: 14.5),
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7), size: 22),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: _colors.textMuted,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Hàng Ghi nhớ & Quên mật khẩu
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: Checkbox(
                                                  value: _rememberMe,
                                                  activeColor: const Color(0xFF0284C7),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                  side: BorderSide(color: _colors.cardBorder, width: 1.5),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      _rememberMe = val ?? false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  tr('remember_me'),
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: _colors.textSecondary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          tr('forgot_password'),
                                          style: const TextStyle(
                                            color: Color(0xFF0284C7),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Hàng Nút ĐĂNG NHẬP + Nút Sinh trắc học
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              tr('login_button'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Nút FaceID / Vân tay
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _colors.cardBg,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _colors.isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: _colors.isDark ? 0.2 : 0.03),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.face_retouching_natural_rounded,
                                            color: Color(0xFF0284C7),
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            AppToast.showInfo(
                                              context,
                                              'Tính năng Đăng nhập sinh trắc học đang được phát triển.',
                                              title: 'Tính năng sắp ra mắt',
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // 4. BẢN QUYỀN CHÂN TRANG
                          Text(
                            '© 2026 HUIT. All rights reserved.',
                            style: TextStyle(
                              color: _colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: HuitLoading(
                  size: 88,
                  message: 'Đang đăng nhập hệ thống...',
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
}
