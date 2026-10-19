import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Thanh công cụ tìm kiếm và lọc đề tài theo giảng viên, hướng nghiên cứu và trạng thái
class TopicFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final List<String> lecturers;
  final String selectedLecturer;
  final ValueChanged<String?> onLecturerChanged;
  final List<String> directions;
  final String selectedDirection;
  final ValueChanged<String?> onDirectionChanged;
  final List<String> statuses;
  final String selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback? onResetFilters;
  final int topicCount;

  const TopicFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.lecturers,
    required this.selectedLecturer,
    required this.onLecturerChanged,
    required this.directions,
    required this.selectedDirection,
    required this.onDirectionChanged,
    required this.statuses,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.onResetFilters,
    required this.topicCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cardBg = colors.cardBg;
    final borderSubtle = colors.cardBorder;
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;
    final textMuted = colors.textMuted;

    final isFiltered = searchController.text.isNotEmpty ||
        (selectedLecturer != 'Giảng viên' && selectedLecturer != 'Tất cả') ||
        (selectedDirection != 'Hướng đề tài' && selectedDirection != 'Tất cả') ||
        (selectedStatus != 'Trạng thái' && selectedStatus != 'Tất cả');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ô tìm kiếm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã đề tài...',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8C9BA8), size: 22),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 2. Hai dropdown bộ lọc: Giảng viên & Hướng đề tài
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Dropdown 1: Giảng viên
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedLecturer != 'Giảng viên' && selectedLecturer != 'Tất cả'
                          ? const Color(0xFF1A73E8)
                          : borderSubtle,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: lecturers.contains(selectedLecturer) ? selectedLecturer : lecturers.first,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textPrimary),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: textSecondary),
                      items: lecturers.map((l) {
                        return DropdownMenuItem(
                          value: l,
                          child: Text(l, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: onLecturerChanged,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Dropdown 2: Hướng đề tài
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedDirection != 'Hướng đề tài' && selectedDirection != 'Tất cả'
                          ? const Color(0xFF1A73E8)
                          : borderSubtle,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: directions.contains(selectedDirection) ? selectedDirection : directions.first,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textPrimary),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: textSecondary),
                      items: directions.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: onDirectionChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. Dropdown bộ lọc Trạng thái đề tài & Nút đặt lại bộ lọc
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Dropdown 3: Trạng thái đề tài
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedStatus != 'Trạng thái' && selectedStatus != 'Tất cả'
                          ? const Color(0xFF1A73E8)
                          : borderSubtle,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: statuses.contains(selectedStatus) ? selectedStatus : statuses.first,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textPrimary),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: textSecondary),
                      items: statuses.map((s) {
                        Color? dotColor;
                        if (s == 'Mở đăng ký') {
                          dotColor = const Color(0xFF10B981);
                        } else if (s == 'Đã đóng') {
                          dotColor = const Color(0xFF94A3B8);
                        } else if (s == 'Đã có nhóm') {
                          dotColor = const Color(0xFFEA580C);
                        }

                        return DropdownMenuItem(
                          value: s,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (dotColor != null) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Flexible(
                                child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: onStatusChanged,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Nút Đặt lại bộ lọc (Reset)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isFiltered ? onResetFilters : null,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isFiltered
                          ? (colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF5FE))
                          : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFiltered ? const Color(0xFF1A73E8) : borderSubtle,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 18,
                          color: isFiltered ? const Color(0xFF1A73E8) : textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFiltered ? const Color(0xFF1A73E8) : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. Label số lượng đề tài
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            '$topicCount đề tài',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
