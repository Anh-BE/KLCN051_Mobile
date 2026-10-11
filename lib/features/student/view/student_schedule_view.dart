import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/huit_loading.dart';
import '../../auth/model/user_model.dart';
import '../../notification/view/notification_bell_button.dart';
import '../progress/logic/student_progress_service.dart';
import '../progress/model/student_progress_model.dart';

class StudentScheduleView extends StatefulWidget {
  final UserModel user;

  const StudentScheduleView({super.key, required this.user});

  @override
  State<StudentScheduleView> createState() => _StudentScheduleViewState();
}

class _StudentScheduleViewState extends State<StudentScheduleView> {
  final StudentProgressService _service = StudentProgressService();
  bool _isLoading = true;
  StudentThesisProgressModel? _progressData;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);
    final data = await _service.getMyThesisProgress();
    if (mounted) {
      setState(() {
        _progressData = data;
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // XỬ LÝ NỘP BÀI TẬP (SUBMIT MODAL)
  // ==========================================
  void _showSubmitModal(WeeklyPlanModel plan) {
    final colors = AppColors.of(context);
    final contentController = TextEditingController(text: plan.report?.content ?? '');
    final fileUrlController = TextEditingController();

    String? uploadedFileUrl;
    String? uploadedFileName;

    // Phân tích reportFileUrl ban đầu (nếu đã nộp trước đó)
    if (plan.report?.reportFileUrl != null && plan.report!.reportFileUrl!.isNotEmpty) {
      final initialUrl = plan.report!.reportFileUrl!;
      if (initialUrl.contains('/uploads/')) {
        final parts = initialUrl.split(';').map((s) => s.trim()).toList();
        for (final p in parts) {
          if (p.contains('/uploads/')) {
            uploadedFileUrl = p;
            final fileNameOnly = p.split('/').last;
            uploadedFileName = fileNameOnly.contains('_')
                ? fileNameOnly.substring(fileNameOnly.indexOf('_') + 1)
                : fileNameOnly;
          } else if (p.isNotEmpty) {
            fileUrlController.text = p;
          }
        }
      } else {
        fileUrlController.text = initialUrl;
      }
    }

    bool isUploadingFile = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAndUploadFile() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'rar', '7z', 'pptx', 'xlsx'],
                );

                if (result.isEmpty) return;
                final picked = result.first;
                final fileSize = (await picked.length()) ?? 0;

                if (fileSize > 50 * 1024 * 1024) {
                  if (ctx.mounted) {
                    AppToast.showError(ctx, 'Dung lượng tệp vượt quá giới hạn 50MB.');
                  }
                  return;
                }

                setModalState(() => isUploadingFile = true);

                final fileBytes = await picked.readAsBytes();
                final res = await _service.uploadReportFile(
                  filePath: picked.path,
                  fileBytes: fileBytes,
                  fileName: picked.name,
                );

                if (res['success'] == true) {
                  setModalState(() {
                    uploadedFileUrl = res['fileUrl'];
                    uploadedFileName = res['fileName'] ?? picked.name;
                    isUploadingFile = false;
                  });
                  if (ctx.mounted) {
                    AppToast.showSuccess(ctx, 'Tải tệp lên thành công!');
                  }
                } else {
                  setModalState(() => isUploadingFile = false);
                  if (ctx.mounted) {
                    AppToast.showError(ctx, res['message'] ?? 'Tải tệp thất bại.');
                  }
                }
              } catch (e) {
                setModalState(() => isUploadingFile = false);
                if (ctx.mounted) {
                  AppToast.showError(ctx, 'Lỗi chọn tệp: $e');
                }
              }
            }

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
                                'Hạn chót: ${_formatDateTime(plan.deadline)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: plan.isOverdue ? const Color(0xFFEF4444) : colors.textSecondary,
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
                      controller: contentController,
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
                    if (uploadedFileName != null && uploadedFileName!.isNotEmpty) ...[
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
                                    uploadedFileName!,
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
                                setModalState(() {
                                  uploadedFileUrl = null;
                                  uploadedFileName = null;
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
                          onPressed: isUploadingFile ? null : pickAndUploadFile,
                          icon: isUploadingFile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.upload_file_rounded, size: 20, color: colors.sectionTitle),
                          label: Text(
                            isUploadingFile ? 'Đang tải tệp lên máy chủ...' : 'Chọn tệp (PDF, Word, Zip... tối đa 50MB)',
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
                      controller: fileUrlController,
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
                        onPressed: (isSubmitting || isUploadingFile)
                            ? null
                            : () async {
                                final content = contentController.text.trim();
                                final linkUrl = fileUrlController.text.trim();

                                String finalUrl = '';
                                if (uploadedFileUrl != null && uploadedFileUrl!.isNotEmpty) {
                                  finalUrl = uploadedFileUrl!;
                                  if (linkUrl.isNotEmpty) {
                                    finalUrl = '$finalUrl; $linkUrl';
                                  }
                                } else {
                                  finalUrl = linkUrl;
                                }

                                if (content.isEmpty && finalUrl.isEmpty) {
                                  AppToast.showWarning(
                                    ctx,
                                    'Vui lòng nhập tóm tắt công việc hoặc chọn tệp / dán liên kết báo cáo.',
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                final result = await _service.submitReport(
                                  planId: plan.planId,
                                  content: content,
                                  reportFileUrl: finalUrl,
                                );
                                setModalState(() => isSubmitting = false);

                                if (result['success'] == true) {
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  if (mounted) {
                                    AppToast.showSuccess(
                                      this.context,
                                      result['message'] ?? 'Nộp bài báo cáo thành công!',
                                    );
                                    _loadProgressData();
                                  }
                                } else {
                                  if (ctx.mounted) {
                                    AppToast.showError(
                                      ctx,
                                      result['message'] ?? 'Lỗi khi nộp bài.',
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0084FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
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
          },
        );
      },
    );
  }

  // ==========================================
  // XỬ LÝ HỦY NỘP BÀI (UNSUBMIT)
  // ==========================================
  Future<void> _handleUnsubmit(WeeklyPlanModel plan) async {
    if (plan.report == null) return;

    final confirm = await AppDialog.showConfirm(
      context,
      title: 'Hủy nộp bài',
      message: 'Bạn có chắc chắn muốn hủy nộp bài tập Tuần ${plan.weekNumber} để cập nhật lại nội dung không?',
      confirmText: 'Đồng ý hủy nộp',
      cancelText: 'Đóng',
      type: DialogType.warning,
      icon: Icons.refresh_rounded,
    );

    if (confirm == true) {
      final res = await _service.unsubmitReport(plan.report!.reportId);
      if (res['success'] == true) {
        if (mounted) {
          AppToast.showSuccess(context, res['message'] ?? 'Đã hủy nộp bài thành công.');
          _loadProgressData();
        }
      } else {
        if (mounted) {
          AppToast.showError(context, res['message'] ?? 'Không thể hủy nộp bài.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return RefreshIndicator(
      onRefresh: _loadProgressData,
      color: colors.sectionTitle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER DẠNG VIÊN THUỐC NỔI
            _buildHeaderPill(context),

            const SizedBox(height: 16),

            // 2. NỘI DUNG CHÍNH (LOADING / EMPTY / DỮ LIỆU THẬT)
            if (_isLoading) ...[
              _buildLoadingSkeleton(colors),
            ] else if (_progressData == null || !_progressData!.hasThesis || _progressData!.weeklyPlans.isEmpty) ...[
              _buildEmptyStateCard(colors),
            ] else ...[
              // 2.1 CARD TỔNG QUAN TIẾN ĐỘ THẬT
              _buildProgressOverviewCard(context, colors, _progressData!),

              const SizedBox(height: 16),

              // 2.2 TIÊU ĐỀ SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kế hoạch báo cáo định kỳ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.sectionTitle,
                        letterSpacing: 0.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_progressData!.weeklyPlans.length} tuần',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.sectionTitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2.3 DANH SÁCH CÁC TUẦN THỰC TẾ
              ..._progressData!.weeklyPlans.map(
                (plan) => _buildWeeklyPlanCard(context, colors, plan),
              ),
            ],

            const SizedBox(height: 70), // Khoảng đệm cho bottom navigation bar
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER DẠNG VIÊN THUỐC NỔI
  // ==========================================
  Widget _buildHeaderPill(BuildContext context) {
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
          const NotificationBellButton(),
        ],
      ),
    );
  }

  // ==========================================
  // CARD TỔNG QUAN TIẾN ĐỘ THẬT
  // ==========================================
  Widget _buildProgressOverviewCard(
    BuildContext context,
    AppColors colors,
    StudentThesisProgressModel data,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ thực hiện đề tài',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: colors.sectionTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đang thực hiện',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.thesisTitle.isNotEmpty ? data.thesisTitle : 'Đề tài khóa luận',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_pin_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'GVHD: ${data.supervisorName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ nộp báo cáo:',
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
              Text(
                '${data.submittedCount} / ${data.weeklyPlans.length} tuần (${data.completionPercent}%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: data.weeklyPlans.isEmpty ? 0 : data.completionPercent / 100,
              minHeight: 7,
              backgroundColor: colors.isDark ? const Color(0xFF26282C) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(colors.sectionTitle),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD MỖI TUẦN BÁO CÁO THỰC TẾ
  // ==========================================
  Widget _buildWeeklyPlanCard(
    BuildContext context,
    AppColors colors,
    WeeklyPlanModel plan,
  ) {
    // Phân tích trạng thái
    String statusText;
    Color statusColor;
    Color statusBg;

    if (plan.report != null && plan.report!.isGraded) {
      statusText = plan.report!.isPassed == true ? 'ĐẠT' : 'CHƯA ĐẠT';
      statusColor = plan.report!.isPassed == true ? const Color(0xFF10B981) : const Color(0xFFEF4444);
      statusBg = plan.report!.isPassed == true
          ? (colors.isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
          : (colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2));
    } else if (plan.report != null && plan.report!.submittedAt != null) {
      final isTurnedIn = plan.report!.submissionStatus == 'TurnedIn';
      statusText = isTurnedIn ? 'Đã nộp bài' : 'Nộp muộn';
      statusColor = isTurnedIn ? const Color(0xFF0284C7) : const Color(0xFFF59E0B);
      statusBg = isTurnedIn
          ? (colors.isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE))
          : (colors.isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7));
    } else {
      statusText = plan.isOverdue ? 'Quá hạn' : 'Đã giao bài';
      statusColor = plan.isOverdue ? const Color(0xFFEF4444) : colors.textSecondary;
      statusBg = plan.isOverdue
          ? (colors.isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2))
          : (colors.isDark ? const Color(0xFF26282C) : const Color(0xFFF1F5F9));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF007AFF).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuần ${plan.weekNumber}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Tên tuần
          Text(
            _cleanPlanTitle(plan.title, plan.weekNumber),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          // Hạn chót
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: colors.textMuted),
              const SizedBox(width: 5),
              Text(
                'Hạn chót: ${_formatDateTime(plan.deadline)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: plan.isOverdue && !plan.isSubmitted ? const Color(0xFFEF4444) : colors.textSecondary,
                ),
              ),
            ],
          ),

          if (plan.detailedRequirements.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 0.7, color: colors.divider),
            const SizedBox(height: 10),
            Text(
              plan.detailedRequirements,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          // Đã nộp bài
          if (plan.report != null && plan.report!.submittedAt != null) ...[
            const SizedBox(height: 12),
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
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'Đã nộp lúc: ${_formatDateTime(plan.report!.submittedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (plan.report!.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '“${plan.report!.content}”',
                      style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ],
                  if (plan.report!.reportFileUrl != null && plan.report!.reportFileUrl!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...plan.report!.reportFileUrl!.split(';').map((rawItem) {
                      final item = rawItem.trim();
                      if (item.isEmpty) return const SizedBox.shrink();
                      final isUploaded = item.contains('/uploads/');
                      String displayName = item;
                      if (isUploaded) {
                        displayName = item.split('/').last;
                        if (displayName.contains('_')) {
                          displayName = displayName.substring(displayName.indexOf('_') + 1);
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              isUploaded ? Icons.insert_drive_file_rounded : Icons.link_rounded,
                              size: 15,
                              color: isUploaded ? const Color(0xFF10B981) : colors.sectionTitle,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUploaded ? colors.textPrimary : colors.sectionTitle,
                                  decoration: isUploaded ? TextDecoration.none : TextDecoration.underline,
                                  fontWeight: isUploaded ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],

          // Nhận xét của giảng viên
          if (plan.report != null && plan.report!.isGraded) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nhận xét từ GVHD:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (plan.report!.supervisorScore != null)
                        Text(
                          'Điểm: ${plan.report!.supervisorScore}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                  if (plan.report!.supervisorFeedback != null && plan.report!.supervisorFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${plan.report!.supervisorFeedback}”',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Nút hành động (Nộp bài / Hủy nộp)
          if (plan.report == null || plan.report!.submittedAt == null) ...[
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _showSubmitModal(plan),
                icon: const Icon(Icons.upload_file_rounded, size: 17),
                label: const Text('Nộp báo cáo tuần', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (!plan.report!.isGraded) ...[
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () => _handleUnsubmit(plan),
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFEF4444)),
                label: const Text('Hủy nộp bài (để sửa lại)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE CARD
  // ==========================================
  Widget _buildEmptyStateCard(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_late_outlined, size: 54, color: colors.textMuted),
          const SizedBox(height: 14),
          Text(
            'Chưa có kế hoạch tiến độ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _progressData?.message ?? 'Nhóm của bạn hiện chưa được duyệt đề tài hoặc dữ liệu kế hoạch tuần đang được cập nhật.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadProgressData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tải lại dữ liệu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0084FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LOADING SKELETON (HUIT SPINNER)
  // ==========================================
  Widget _buildLoadingSkeleton(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      alignment: Alignment.center,
      child: const HuitLoading(
        size: 76,
        message: 'Đang tải kế hoạch tiến độ...',
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Chưa có hạn';
    String pad(int n) => n < 10 ? '0$n' : '$n';
    return '${pad(dt.hour)}:${pad(dt.minute)} ${pad(dt.day)}/${pad(dt.month)}/${dt.year}';
  }

  String _cleanPlanTitle(String title, int weekNumber) {
    final cleaned = title.replaceFirst(RegExp(r'^Tuần\s*\d+\s*[:\-\.]?\s*', caseSensitive: false), '').trim();
    return cleaned.isNotEmpty ? cleaned : title;
  }
}
