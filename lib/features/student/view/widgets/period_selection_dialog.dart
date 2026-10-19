import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../model/registration_period_model.dart';

/// Hộp thoại chọn đợt khóa luận cho sinh viên khi tham gia từ 2 đợt song song trở lên.
/// Thiết kế theo đúng khung chuẩn HUIT của thông báo lời mời nhóm.
class PeriodSelectionDialog extends StatefulWidget {
  final List<RegistrationPeriodModel> periods;
  final int? currentSelectedPeriodId;
  final bool canCancel;
  final Function(RegistrationPeriodModel) onPeriodSelected;

  const PeriodSelectionDialog({
    super.key,
    required this.periods,
    this.currentSelectedPeriodId,
    required this.canCancel,
    required this.onPeriodSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<RegistrationPeriodModel> periods,
    int? currentSelectedPeriodId,
    required bool canCancel,
    required Function(RegistrationPeriodModel) onPeriodSelected,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: canCancel,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (dialogContext) {
        return PeriodSelectionDialog(
          periods: periods,
          currentSelectedPeriodId: currentSelectedPeriodId,
          canCancel: canCancel,
          onPeriodSelected: onPeriodSelected,
        );
      },
    );
  }

  @override
  State<PeriodSelectionDialog> createState() => _PeriodSelectionDialogState();
}

class _PeriodSelectionDialogState extends State<PeriodSelectionDialog> {
  int? _selectedPeriodId;

  @override
  void initState() {
    super.initState();
    if (widget.currentSelectedPeriodId != null) {
      _selectedPeriodId = widget.currentSelectedPeriodId;
    } else {
      if (widget.periods.isNotEmpty) {
        _selectedPeriodId = widget.periods.first.periodId;
      }
    }
  }

  void _onConfirm() {
    if (_selectedPeriodId == null) {
      return;
    }

    final matched = widget.periods.firstWhere(
      (p) {
        return p.periodId == _selectedPeriodId;
      },
      orElse: () {
        return widget.periods.first;
      },
    );

    Navigator.of(context).pop();
    widget.onPeriodSelected(matched);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bool isDark = colors.isDark;

    return PopScope(
      canPop: widget.canCancel,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222A) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TIÊU ĐỀ: "Thông báo *"
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Thông báo',
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. LỜI DẪN THÔNG BÁO THEO KHUNG
              Text(
                widget.canCancel
                    ? 'Chọn đợt bên dưới để chuyển đổi không gian làm việc:'
                    : 'Hệ thống ghi nhận bạn đang tham gia ${widget.periods.length} đợt khóa luận song song. Vui lòng chọn 1 đợt để tiếp tục vào ứng dụng:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6679),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),

              // 3. DANH SÁCH THẺ ĐỢT ĐƯỢC BIẾN TẤU VỪA VẶN
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 290),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: widget.periods.map((period) {
                      final bool isSelected = period.periodId == _selectedPeriodId;

                      Color cardBg = isDark ? const Color(0xFF252932) : const Color(0xFFF8FAFC);
                      if (isSelected) {
                        cardBg = isDark
                            ? const Color(0xFF1A365D).withValues(alpha: 0.45)
                            : const Color(0xFFF0F7FF);
                      }

                      Color borderColor = isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : const Color(0xFFE2E8F0);
                      if (isSelected) {
                        borderColor = const Color(0xFF0A58CA);
                      }

                      return InkWell(
                        borderRadius: BorderRadius.circular(2),
                        onTap: () {
                          setState(() {
                            _selectedPeriodId = period.periodId;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: borderColor,
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nút tròn Radio indicator
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0A58CA)
                                          : const Color(0xFF94A3B8),
                                      width: isSelected ? 6 : 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Thông tin chi tiết đợt
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bậc đào tạo
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: period.isEngineer
                                            ? const Color(0xFFFAF5FF)
                                            : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: period.isEngineer
                                              ? const Color(0xFFD8B4FE)
                                              : const Color(0xFFBFDBFE),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        period.degreeBadgeText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: period.isEngineer
                                              ? const Color(0xFF7E22CE)
                                              : const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Tên đợt khóa luận
                                    Text(
                                      period.periodName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF0A58CA)
                                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                        height: 1.3,
                                      ),
                                    ),

                                    // Tiến độ tuần
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 13,
                                          color: isDark
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFF0284C7),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tiến độ: Tuần ${period.currentWeek}/${period.totalWeeks}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFF38BDF8)
                                                : const Color(0xFF0284C7),
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
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 28),

              // 4. HAI NÚT THAO TÁC CĂN HAI BÊN TRÁI / PHẢI CHUẨN FORM THÔNG BÁO
              Row(
                mainAxisAlignment: widget.canCancel
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  // Nút bên trái: "Quay lại" (chỉ hiện khi được phép hủy)
                  if (widget.canCancel)
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2D34) : const Color(0xFFF1F5F9),
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
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),

                  // Nút bên phải: "Vào trang chủ" / "Xác nhận"
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: _onConfirm,
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
                      child: Text(
                        widget.canCancel ? 'Xác nhận' : 'Vào trang chủ',
                        style: const TextStyle(
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
      ),
    );
  }
}
