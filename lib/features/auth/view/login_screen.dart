import 'package:flutter/material.dart';
import '../../../core/localization/app_language_service.dart';
import '../../../core/utils/storage_service.dart';
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
      _showNotification(tr('username_empty'), isError: true);
      return;
    }
    if (password.isEmpty) {
      _showNotification(tr('password_empty'), isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService().login(username, password, _rememberMe);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showNotification(
        'Đăng nhập thành công!\nXin chào ${result.user.fullName}',
        isError: false,
      );

      // Chuyển màn hình vào MainLayout theo vai trò
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainLayoutScreen(user: result.user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showNotification(errorMsg, isError: true);
    }
  }

  void _showNotification(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
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
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
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
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.palette_outlined, size: 16, color: Color(0xFF0284C7)),
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
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.school,
                                  size: 70,
                                  color: Color(0xFF0B519C),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'TRƯỜNG ĐẠI HỌC',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B519C),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 3),
                                    padding: const EdgeInsets.only(bottom: 2),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFF0B519C),
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'CÔNG THƯƠNG TP. HCM',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0B519C),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'HCMC UNIVERSITY OF INDUSTRY AND TRADE',
                                    style: TextStyle(
                                      fontSize: 10.2,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B519C),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0B519C).withOpacity(0.08),
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _usernameController,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                                      decoration: InputDecoration(
                                        hintText: tr('username_hint'),
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.5),
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _handleLogin(),
                                      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                                      decoration: InputDecoration(
                                        hintText: tr('password_hint'),
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.5),
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7), size: 22),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: const Color(0xFF94A3B8),
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
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: const Color(0xFF0284C7),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                              onChanged: (val) {
                                                setState(() {
                                                  _rememberMe = val ?? false;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            tr('remember_me'),
                                            style: const TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                                color: const Color(0xFF0284C7).withOpacity(0.35),
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
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        tr('login_button'),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w700,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
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
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
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
                                            _showNotification('Tính năng Đăng nhập sinh trắc học đang phát triển!', isError: false);
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
                          const Text(
                            '© 2026 HUIT. All rights reserved.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
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
      ],
    ),
  );
}
}
