import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../progress/logic/student_progress_service.dart';
import '../../progress/model/student_progress_model.dart';

/// Modal bottom sheet cho sinh viên nộp báo cáo tiến độ tuần
class SubmitReportSheet extends StatefulWidget {
  final WeeklyPlanModel plan;
  final StudentProgressService service;
  final VoidCallback onSubmittedSuccess;

  const SubmitReportSheet({
    super.key,
    required this.plan,
    required this.service,
    required this.onSubmittedSuccess,
  });

  @override
  State<SubmitReportSheet> createState() => _SubmitReportSheetState();
}

class _SubmitReportSheetState extends State<SubmitReportSheet> {
  late final TextEditingController _contentController;
  late final TextEditingController _fileUrlController;

  String? _uploadedFileUrl;
  String? _uploadedFileName;

  bool _isUploadingFile = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.plan.report?.content ?? '');
    _fileUrlController = TextEditingController();

    // Phân tích reportFileUrl ban đầu (nếu đã nộp trước đó)
    if (widget.plan.report?.reportFileUrl != null && widget.plan.report!.reportFileUrl!.isNotEmpty) {
      final initialUrl = widget.plan.report!.reportFileUrl!;
      if (initialUrl.contains('/uploads/')) {
        final parts = initialUrl.split(';').map((s) => s.trim()).toList();
        for (final p in parts) {
          if (p.contains('/uploads/')) {
            _uploadedFileUrl = p;
            final fileNameOnly = p.split('/').last;
            _uploadedFileName = fileNameOnly.contains('_')
                ? fileNameOnly.substring(fileNameOnly.indexOf('_') + 1)
                : fileNameOnly;
          } else if (p.isNotEmpty) {
            _fileUrlController.text = p;
          }
        }
      } else {
        _fileUrlController.text = initialUrl;
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null || dt.year <= 2000) return 'Chưa có hạn nộp';
    String pad(int n) => n < 10 ? '0$n' : '$n';
    return '${pad(dt.hour)}:${pad(dt.minute)} ${pad(dt.day)}/${pad(dt.month)}/${dt.year}';
  }

  String _cleanPlanTitle(String title, int weekNumber) {
    final cleaned = title.replaceFirst(RegExp(r'^Tuần\s*\d+\s*[:\-\.]?\s*', caseSensitive: false), '').trim();
    return cleaned.isNotEmpty ? cleaned : title;
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'rar', '7z', 'pptx', 'xlsx'],
      );

      if (result.isEmpty) return;
      final picked = result.first;
      final fileSize = (await picked.length()) ?? 0;

      if (fileSize > 50 * 1024 * 1024) {
        if (mounted) {
          AppToast.showError(context, 'Dung lượng tệp vượt quá giới hạn 50MB.', title: 'Tệp quá lớn');
        }
        return;
      }

      setState(() => _isUploadingFile = true);

      final fileBytes = await picked.readAsBytes();
      final res = await widget.service.uploadReportFile(
        filePath: picked.path,
        fileBytes: fileBytes,
        fileName: picked.name,
      );

      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _uploadedFileUrl = res['fileUrl'];
            _uploadedFileName = res['fileName'] ?? picked.name;
            _isUploadingFile = false;
          });
          AppToast.showSuccess(context, 'Tải tệp lên thành công!', title: 'Tải tệp hoàn tất');
        }
      } else {
        if (mounted) {
          setState(() => _isUploadingFile = false);
          AppToast.showError(context, res['message'] ?? 'Tải tệp thất bại.', title: 'Tải tệp thất bại');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFile = false);
        AppToast.showError(context, 'Lỗi chọn tệp: $e', title: 'Chọn tệp thất bại');
      }
    }
  }

  Future<void> _submitReport() async {
    final content = _contentController.text.trim();
    final linkUrl = _fileUrlController.text.trim();

    String finalUrl = '';
    if (_uploadedFileUrl != null && _uploadedFileUrl!.isNotEmpty) {
      finalUrl = _uploadedFileUrl!;
      if (linkUrl.isNotEmpty) {
        finalUrl = '$finalUrl; $linkUrl';
      }
    } else {
      finalUrl = linkUrl;
    }

    if (content.isEmpty && finalUrl.isEmpty) {
      AppToast.showWarning(
        context,
        'Vui lòng nhập tóm tắt công việc hoặc chọn tệp / dán liên kết báo cáo.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await widget.service.submitReport(
      planId: widget.plan.planId,
      content: content,
      reportFileUrl: finalUrl,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop();
      widget.onSubmittedSuccess();
      AppToast.showSuccess(
        context,
        result['message'] ?? 'Nộp bài báo cáo thành công!',
      );
    } else {
      AppToast.showError(
        context,
        result['message'] ?? 'Lỗi khi nộp bài.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final plan = widget.plan;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh gạt modal
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề modal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nộp báo cáo - Tuần ${plan.weekNumber}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        plan.hasValidDeadline
                            ? 'Hạn chót: ${_formatDateTime(plan.deadline)}'
                            : 'Chưa có hạn nộp',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: (plan.isOverdue && plan.hasValidDeadline) ? const Color(0xFFEF4444) : colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, thickness: 0.7, color: colors.divider),
            const SizedBox(height: 14),

            // Yêu cầu của tuần
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E222A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanPlanTitle(plan.title, plan.weekNumber),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (plan.detailedRequirements.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan.detailedRequirements,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 1. Ô nhập nội dung báo cáo
            Text(
              '1. Tóm tắt công việc đã thực hiện *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _contentController,
              maxLines: 4,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nhập tóm tắt tiến độ, các công việc đã làm trong tuần...',
                hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                filled: true,
                fillColor: colors.isDark ? const Color(0xFF141518) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.sectionTitle, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Đính kèm tệp tin báo cáo
            Text(
              '2. Đính kèm tệp tin báo cáo / mã nguồn',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            if (_uploadedFileName != null && _uploadedFileName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _uploadedFileName!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Đã tải lên máy chủ',
                            style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 20),
                      tooltip: 'Xóa tệp',
                      onPressed: () {
                        setState(() {
                          _uploadedFileUrl = null;
                          _uploadedFileName = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingFile ? null : _pickAndUploadFile,
                  icon: _isUploadingFile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.upload_file_rounded, size: 20, color: colors.sectionTitle),
                  label: Text(
                    _isUploadingFile ? 'Đang tải tệp lên máy chủ...' : 'Chọn tệp (PDF, Word, Zip... tối đa 50MB)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.sectionTitle,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.sectionTitle.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 3. Ô nhập đường dẫn tệp / liên kết trực tiếp
            Text(
              '3. HOẶC dán liên kết sản phẩm (GitHub / Drive / Figma)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _fileUrlController,
              style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.link_rounded, size: 20, color: colors.textSecondary),
                hintText: 'https://github.com/... hoặc link Drive',
                hintStyle: TextStyle(fontSize: 12.5, color: colors.textMuted),
                filled: true,
                fillColor: colors.isDark ? const Color(0xFF141518) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.sectionTitle, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nút nộp bài
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isUploadingFile) ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Xác nhận nộp bài',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
