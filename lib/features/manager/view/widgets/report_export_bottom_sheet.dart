import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/model/user_model.dart';
import '../../logic/report_export_service.dart';

class ReportExportBottomSheet extends StatefulWidget {
  final ReportExportData reportData;
  final UserModel user;

  const ReportExportBottomSheet({
    super.key,
    required this.reportData,
    required this.user,
  });

  static Future<void> show({
    required BuildContext context,
    required ReportExportData reportData,
    required UserModel user,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportExportBottomSheet(
        reportData: reportData,
        user: user,
      ),
    );
  }

  @override
  State<ReportExportBottomSheet> createState() => _ReportExportBottomSheetState();
}

class _ReportExportBottomSheetState extends State<ReportExportBottomSheet> {
  bool _isSaving = false;

  Future<void> _handleSaveFile() async {
    setState(() => _isSaving = true);
    await ReportExportService().exportAndSaveFile(
      context: context,
      data: widget.reportData,
      user: widget.user,
    );
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _handleCopyClipboard() {
    final text = widget.reportData.toClipboardText();
    Clipboard.setData(ClipboardData(text: text));
    AppToast.showSuccess(
      context,
      'Đã sao chép ${widget.reportData.rows.length} dòng dữ liệu vào bộ nhớ tạm!',
      title: 'Đã sao chép',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final data = widget.reportData;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // 1. HEADER MODAL
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.table_view_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.reportTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data.periodName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${data.rows.length} bản ghi',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 24),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 2. BẢNG XEM TRƯỚC DỮ LIỆU TRÊN MOBILE
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.remove_red_eye_outlined, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Xem trước bảng dữ liệu trích xuất:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          colors.isDark ? const Color(0xFF1E293B) : const Color(0xFF1E3A8A),
                        ),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                        dataTextStyle: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                        columnSpacing: 20,
                        horizontalMargin: 16,
                        columns: data.headers.map((h) => DataColumn(label: Text(h))).toList(),
                        rows: List.generate(data.rows.length, (rowIndex) {
                          final row = data.rows[rowIndex];
                          final isEven = rowIndex % 2 == 0;
                          return DataRow(
                            color: WidgetStateProperty.all(
                              isEven
                                  ? Colors.transparent
                                  : (colors.isDark
                                      ? const Color(0xFF1E222A).withValues(alpha: 0.5)
                                      : const Color(0xFFF8FAFC)),
                            ),
                            cells: row.map((cell) => DataCell(Text(cell))).toList(),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. THANH THAO TÁC HÀNH ĐỘNG CHUẨN MOBILE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardBg,
                border: Border(top: BorderSide(color: colors.cardBorder)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Nút Sao chép vào bộ nhớ tạm
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: colors.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _handleCopyClipboard,
                          icon: Icon(Icons.copy_rounded, size: 18, color: colors.textPrimary),
                          label: Text(
                            'Sao Chép',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nút Xuất file Excel / CSV thật
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isSaving ? null : _handleSaveFile,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'Đang lưu...' : 'Lưu File Excel / CSV',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
  }
}

