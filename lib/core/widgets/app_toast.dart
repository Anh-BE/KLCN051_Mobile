import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

enum ToastStyle {
  /// Kính mờ trắng tinh khôi chuẩn Apple iOS Frosted Glass
  frostedLight,

  /// Viên thuốc đen tuyền huyền bí chuẩn Apple Dynamic Island
  dynamicIslandDark,
}

/// Helper hiển thị thông báo Top Banner / Toast chuẩn thiết kế Mobile quốc tế
/// Tham khảo từ các chuẩn UI hiện đại: Mobbin, Dribbble, Apple iOS, Linear & Toastification.
/// - Hiệu ứng Kính mờ (BackdropFilter Frosted Glass)
/// - Bo góc viên thuốc khí động học (Pill/Capsule)
/// - Icon Squircle Gradient nổi khối cao cấp
/// - Thanh đếm thời gian siêu mảnh (Progress Indicator)
/// - Thao tác vuốt lên để đóng (Swipe to dismiss)
class AppToast {
  static OverlayEntry? _activeEntry;
  static _AppToastWidgetState? _currentState;

  /// Hiển thị thông báo thành công
  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Thành công',
    Duration duration = const Duration(milliseconds: 3200),
    ToastStyle style = ToastStyle.frostedLight,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: ToastType.success,
      duration: duration,
      style: style,
    );
  }

  /// Hiển thị thông báo lỗi
  static void showError(
    BuildContext context,
    String message, {
    String title = 'Đăng nhập thất bại',
    Duration duration = const Duration(milliseconds: 3800),
    ToastStyle style = ToastStyle.frostedLight,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: ToastType.error,
      duration: duration,
      style: style,
    );
  }

  /// Hiển thị thông báo thông tin
  static void showInfo(
    BuildContext context,
    String message, {
    String title = 'Thông báo',
    Duration duration = const Duration(milliseconds: 3000),
    ToastStyle style = ToastStyle.frostedLight,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: ToastType.info,
      duration: duration,
      style: style,
    );
  }

  /// Hiển thị thông báo cảnh báo
  static void showWarning(
    BuildContext context,
    String message, {
    String title = 'Cảnh báo',
    Duration duration = const Duration(milliseconds: 3500),
    ToastStyle style = ToastStyle.frostedLight,
  }) {
    show(
      context,
      title: title,
      message: message,
      type: ToastType.warning,
      duration: duration,
      style: style,
    );
  }

  /// Hiển thị thông báo tùy chỉnh
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 3200),
    ToastStyle style = ToastStyle.frostedLight,
  }) {
    dismissImmediate();

    final overlay = Navigator.of(context, rootNavigator: true).overlay ?? Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _AppToastWidget(
          title: title,
          message: message,
          type: type,
          style: style,
          duration: duration,
          onDismiss: () => dismiss(),
          onCreated: (state) {
            _currentState = state;
          },
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  /// Đóng thông báo với hiệu ứng trượt mượt mà
  static void dismiss() {
    if (_currentState != null && _currentState!.mounted) {
      _currentState!.dismissWithAnimation(() {
        dismissImmediate();
      });
    } else {
      dismissImmediate();
    }
  }

  /// Xóa ngay lập tức khỏi Overlay
  static void dismissImmediate() {
    _currentState = null;
    if (_activeEntry != null) {
      try {
        _activeEntry?.remove();
      } catch (_) {}
      _activeEntry = null;
    }
  }
}

class _AppToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final ToastStyle style;
  final Duration duration;
  final VoidCallback onDismiss;
  final ValueChanged<_AppToastWidgetState> onCreated;

  const _AppToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.style,
    required this.duration,
    required this.onDismiss,
    required this.onCreated,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _progressController;

  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onCreated(this);

    // Controller chuyển động vào/ra (Spring physics)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.9),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Controller thanh thời gian đếm ngược
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });

    _entranceController.forward().then((_) {
      if (mounted && !_isDismissing) {
        _progressController.forward();
      }
    });
  }

  void dismissWithAnimation(VoidCallback onDone) {
    if (_isDismissing) return;
    _isDismissing = true;
    _progressController.stop();
    _entranceController.reverse().then((_) {
      onDone();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final isDark = widget.style == ToastStyle.dynamicIslandDark;

    final config = _getToastConfig(widget.type);

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  // Vuốt nhẹ lên trên để đóng ngay lập tức
                  if (details.primaryDelta != null && details.primaryDelta! < -4) {
                    widget.onDismiss();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      // Đổ bóng khuếch tán đa tầng phong cách Apple
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: config.accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xEB0F172A)
                              : Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Squircle Icon Badge với Gradient nổi khối cao cấp
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: config.gradientColors,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: config.gradientColors.first.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      config.icon,
                                      color: Colors.white,
                                      size: 21,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Nội dung: Tiêu đề & Thông điệp
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14.2,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2.5),
                                        Text(
                                          widget.message,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.8,
                                            fontWeight: FontWeight.w500,
                                            height: 1.32,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Nút đóng nhanh tối giản
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: widget.onDismiss,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Thanh thời gian siêu mảnh (Mini Progress Indicator)
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(24),
                                  ),
                                  child: LinearProgressIndicator(
                                    value: 1.0 - _progressController.value,
                                    minHeight: 2.2,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      config.accentColor.withValues(
                                        alpha: isDark ? 0.75 : 0.6,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastVisualConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastVisualConfig(
          icon: Icons.check_rounded,
          gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
          accentColor: const Color(0xFF10B981),
        );
      case ToastType.error:
        return _ToastVisualConfig(
          icon: Icons.priority_high_rounded,
          gradientColors: [const Color(0xFFF43F5E), const Color(0xFFE11D48)],
          accentColor: const Color(0xFFF43F5E),
        );
      case ToastType.warning:
        return _ToastVisualConfig(
          icon: Icons.warning_amber_rounded,
          gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          accentColor: const Color(0xFFF59E0B),
        );
      case ToastType.info:
        return _ToastVisualConfig(
          icon: Icons.info_outline_rounded,
          gradientColors: [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
          accentColor: const Color(0xFF0EA5E9),
        );
    }
  }
}

class _ToastVisualConfig {
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;

  _ToastVisualConfig({
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
  });
}
