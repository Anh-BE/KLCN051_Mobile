import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu chung
  static const Color primaryBlue = Color(0xFF0084FF);
  static const Color accentBlue = Color(0xFF38BDF8);

  // Light Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: const Color(0xFFF1F8FF),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFF1F5F9),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  // Dark Theme Data (Theo chuẩn ảnh mẫu OLED/Charcoal)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: const Color(0xFF0B0C0E),
      cardColor: const Color(0xFF18191C),
      dividerColor: const Color(0xFF27292D),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentBlue,
        surface: Color(0xFF18191C),
      ),
      useMaterial3: true,
    );
  }
}

/// Helper tiện ích truy xuất màu theo ngữ cảnh Sáng / Tối
class AppColors {
  final bool isDark;
  const AppColors(this.isDark);

  static AppColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppColors(isDark);
  }

  // Nền trang
  Color get scaffoldBg => isDark ? const Color(0xFF0B0C0E) : const Color(0xFFF1F8FF);
  List<Color> get pageGradient => isDark
      ? const [Color(0xFF0B0C0E), Color(0xFF101216), Color(0xFF0B0C0E)]
      : const [Color(0xFFE2F1FD), Color(0xFFF1F8FF), Color(0xFFF8FAFC)];

  // Nền thẻ card
  Color get cardBg => isDark ? const Color(0xFF18191C) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF26282C) : Colors.white;

  // Tiêu đề section (Login, Setting, Thông tin sinh viên)
  Color get sectionTitle => isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

  // Chữ
  Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
  Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Đường kẻ phân cách
  Color get divider => isDark ? const Color(0xFF232529) : const Color(0xFFF1F5F9);

  // Switch & Segmented Control
  Color get segmentBg => isDark ? const Color(0xFF232529) : const Color(0xFFF1F5F9);
  Color get switchActive => const Color(0xFF0084FF);

  // Sub-card & Input & Ô tìm kiếm
  Color get subCardBg => isDark ? const Color(0xFF1E2024) : const Color(0xFFF8FAFC);
  Color get subCardBorder => isDark ? const Color(0xFF2B2D33) : const Color(0xFFE2E8F0);
  Color get inputBg => isDark ? const Color(0xFF232529) : const Color(0xFFF1F5F9);
  Color get inputBorder => isDark ? const Color(0xFF2B2D33) : const Color(0xFFE2E8F0);
  Color get searchBg => isDark ? const Color(0xFF1E2024) : Colors.white;
  Color get searchBorder => isDark ? const Color(0xFF2B2D33) : const Color(0xFFE2E8F0);

  // Chip & Badge
  Color get chipBg => isDark ? const Color(0xFF232529) : const Color(0xFFE2E8F0);
  Color get chipText => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  // Nút Logout
  Color get logoutBg => isDark ? const Color(0xFF18191C) : Colors.white;
  Color get logoutBorder => isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2);
  Color get logoutText => const Color(0xFFEF4444);

  // Bottom Navigation Bar
  Color get bottomBarBg => isDark ? const Color(0xFF141518) : Colors.white;
  Color get bottomBarBorder => isDark ? const Color(0xFF26282C) : Colors.white.withValues(alpha: 0.9);
  Color get navActive => const Color(0xFF0084FF);
  Color get navInactive => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
}
