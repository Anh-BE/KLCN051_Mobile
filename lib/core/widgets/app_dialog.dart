import 'package:flutter/material.dart';
import '../../features/auth/view/login_screen.dart';

enum DialogType { info, warning, danger, success }

/// Component Popup Dialog (Hộp thoại chặn giữa màn hình chuẩn mobile)
/// Dùng cho các tình huống cần người dùng quyết định hành động:
/// - Yêu cầu đăng nhập để sử dụng tính năng (như ảnh demo)
/// - Xác nhận đăng xuất, xóa, hủy thao tác
/// - Cảnh báo quan trọng cần người dùng xác nhận rõ ràng
class AppDialog {
  /// Hiển thị hộp thoại xác nhận 2 nút (Confirm Dialog)
  /// Trả về true nếu người dùng bấm nút Xác nhận, false nếu bấm Hủy/Quay lại.
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Quay lại',
    DialogType type = DialogType.info,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: _AppDialogLayout(
              title: title,
              message: message,
              type: type,
              icon: icon,
              cancelText: cancelText,
              confirmText: confirmText,
              onCancel: () => Navigator.of(ctx).pop(false),
              onConfirm: () => Navigator.of(ctx).pop(true),
            ),
          ),
        );
      },
    );
  }

  /// Hiển thị hộp thoại thông báo 1 nút (Alert Dialog)
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Đã hiểu',
    DialogType type = DialogType.info,
    IconData? icon,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: _AppDialogLayout(
              title: title,
              message: message,
              type: type,
              icon: icon,
              confirmText: buttonText,
              onConfirm: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
      },
    );
  }

  /// Hộp thoại yêu cầu đăng nhập (chuẩn giống ảnh chụp màn hình)
  /// Nếu người dùng chọn "Đăng nhập", có thể điều hướng thẳng đến LoginScreen
  static Future<bool?> showRequireLogin(
    BuildContext context, {
    String title = 'Thông báo',
    String message = 'Vui lòng đăng nhập để sử dụng tính năng này',
    String cancelText = 'Quay lại',
    String loginText = 'Đăng nhập',
    bool autoNavigateToLogin = true,
  }) async {
    final result = await showConfirm(
      context,
      title: title,
      message: message,
      cancelText: cancelText,
      confirmText: loginText,
      type: DialogType.info,
      icon: Icons.lock_outline_rounded,
    );

    if (result == true && autoNavigateToLogin && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }

    return result;
  }
}

class _AppDialogLayout extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;
  final IconData? icon;
  final String? cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  const _AppDialogLayout({
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    this.cancelText,
    required this.confirmText,
    this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18191C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: const Color(0xFF26282C), width: 1.2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon minh họa (nếu có)
              if (icon != null) ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.primaryColor, size: 28),
                ),
                const SizedBox(height: 14),
              ],

              // Tiêu đề hộp thoại
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              // Nội dung mô tả
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.42,
                ),
              ),
              const SizedBox(height: 22),

              // Các nút hành động bên dưới (Hủy & Xác nhận)
              Row(
                children: [
                  if (cancelText != null && onCancel != null) ...[
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: onCancel,
                          style: TextButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9),
                            foregroundColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            cancelText!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _DialogTheme _getTheme(DialogType type) {
    switch (type) {
      case DialogType.danger:
        return _DialogTheme(
          primaryColor: const Color(0xFFEF4444),
          badgeColor: const Color(0xFFFEE2E2),
        );
      case DialogType.warning:
        return _DialogTheme(
          primaryColor: const Color(0xFFF59E0B),
          badgeColor: const Color(0xFFFEF3C7),
        );
      case DialogType.success:
        return _DialogTheme(
          primaryColor: const Color(0xFF10B981),
          badgeColor: const Color(0xFFDCFCE7),
        );
      case DialogType.info:
        return _DialogTheme(
          primaryColor: const Color(0xFF0284C7),
          badgeColor: const Color(0xFFE0F2FE),
        );
    }
  }
}

class _DialogTheme {
  final Color primaryColor;
  final Color badgeColor;

  _DialogTheme({required this.primaryColor, required this.badgeColor});
}
