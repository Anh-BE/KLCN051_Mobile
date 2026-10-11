import 'package:flutter/material.dart';
import 'package:app_mobile/features/auth/model/user_model.dart';
import '../logic/student_task_service.dart';
import '../model/student_task_model.dart';

class StudentTaskDeadlineScreen extends StatefulWidget {
  final UserModel user;

  const StudentTaskDeadlineScreen({super.key, required this.user});

  @override
  State<StudentTaskDeadlineScreen> createState() => _StudentTaskDeadlineScreenState();
}

class _StudentTaskDeadlineScreenState extends State<StudentTaskDeadlineScreen> {
  final StudentTaskService _taskService = StudentTaskService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _taskService,
      builder: (context, _) {
        final tasks = _taskService.tasks;
        final pendingCount = tasks.where((t) => t.status == TaskStatus.pending).length;
        final overdueCount = tasks.where((t) => t.status == TaskStatus.overdue).length;
        final completedCount = tasks.where((t) => t.isSubmitted).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF0072E8),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NHẮC VIỆC & DEADLINE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Mốc giới hạn chuẩn: 23:59 • HUIT',
                  style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNER THÔNG ĐIỆP QUY TẮC DEADLINE 23:59
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quy định theo dõi hạn chót (Deadline):',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• Hạn nộp bài luôn kết thúc tại mốc 23:59 của ngày quy định.\n'
                              '• Quá 23:59 hệ thống KHÔNG KHÓA nộp bài, sinh viên vẫn được nộp nhưng tự động gắn cờ "Nộp trễ" để GVHD đánh giá.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. THỐNG KÊ NHANH CÁC NHIỆM VỤ
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryBox(
                        title: 'Đang mở',
                        count: pendingCount.toString(),
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryBox(
                        title: 'Quá hạn',
                        count: overdueCount.toString(),
                        color: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFEE2E2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryBox(
                        title: 'Đã nộp',
                        count: completedCount.toString(),
                        color: const Color(0xFF10B981),
                        bgColor: const Color(0xFFD1FAE5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  'Danh Sách Công Việc & Báo Cáo Tuần',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. DANH SÁCH TỪNG TASK
                ...tasks.map((task) => _buildTaskCard(task)),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryBox({
    required String title,
    required String count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(StudentTaskItem task) {
    final deadlineFormatted =
        '${task.deadline.day.toString().padLeft(2, '0')}/${task.deadline.month.toString().padLeft(2, '0')}/${task.deadline.year} lúc 23:59:59';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.status == TaskStatus.overdue
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFE2E8F0),
          width: task.status == TaskStatus.overdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header task: Tuần + Badge trạng thái
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.weekName,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: task.statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(task.statusIcon, size: 14, color: task.statusColor),
                      const SizedBox(width: 4),
                      Text(
                        task.statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: task.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tiêu đề
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 6),

            // Mô tả
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 10),

            // Hạn chót & Thời gian còn lại
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: task.statusBgColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, size: 18, color: task.statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hạn chót: $deadlineFormatted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: task.statusColor,
                          ),
                        ),
                        Text(
                          task.remainingTimeFormatted,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nếu đã nộp: hiển thị thông tin bài nộp
            if (task.isSubmitted) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          task.isLate ? Icons.assignment_late_rounded : Icons.check_circle_rounded,
                          size: 15,
                          color: task.isLate ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.isLate ? 'ĐÃ NỘP TRỄ' : 'ĐÃ NỘP ĐÚNG HẠN',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: task.isLate ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    if (task.submissionNote != null && task.submissionNote!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Nội dung: ${task.submissionNote}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ],
                    if (task.attachmentLink != null && task.attachmentLink!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Link đính kèm: ${task.attachmentLink}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Nút bấm hành động
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openSubmissionModal(task),
                    icon: Icon(
                      task.isSubmitted ? Icons.edit_note_rounded : Icons.file_upload_outlined,
                      size: 18,
                    ),
                    label: Text(
                      task.isSubmitted
                          ? 'Cập nhật lại bài nộp'
                          : (task.status == TaskStatus.overdue
                              ? 'Nộp báo cáo (Đang quá hạn)'
                              : 'Nộp báo cáo ngay'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.status == TaskStatus.overdue && !task.isSubmitted
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF0072E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                if (task.isSubmitted) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Khôi phục để test lại',
                    onPressed: () {
                      _taskService.resetTaskForTesting(task.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã đặt lại trạng thái cho "${task.title}" để kiểm thử lại.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSubmissionModal(StudentTaskItem task) {
    final noteController = TextEditingController(text: task.submissionNote ?? '');
    final linkController = TextEditingController(text: task.attachmentLink ?? 'https://github.com/huit/doan-tot-nghiep');
    bool simulateLate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final now = DateTime.now();
            final isCurrentlyLate = now.isAfter(task.deadline);

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nộp Báo Cáo: ${task.weekName}',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hạn chót: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year} lúc 23:59:59',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // Cảnh báo trạng thái thời gian nộp
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isCurrentlyLate || simulateLate)
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isCurrentlyLate || simulateLate)
                              ? const Color(0xFFFDBA74)
                              : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (isCurrentlyLate || simulateLate)
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                            color: (isCurrentlyLate || simulateLate)
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF059669),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (isCurrentlyLate || simulateLate)
                                  ? 'CẢNH BÁO QUÁ HẠN: Thời điểm nộp vượt quá mốc 23:59! Hệ thống KHÔNG KHÓA bài nhưng sẽ tự động gắn cờ "NỘP TRỄ".'
                                  : 'HỢP LỆ: Thời điểm nộp bài trước mốc 23:59. Bài nộp sẽ được tính là "Đúng hạn".',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: (isCurrentlyLate || simulateLate)
                                    ? const Color(0xFF9A3412)
                                    : const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tùy chọn kiểm thử: Giả lập nộp trễ / nộp đúng hạn
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.science_outlined, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Chế độ test: Giả lập nộp trễ (sau 23:59)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                          Switch(
                            value: simulateLate,
                            onChanged: (val) {
                              setModalState(() {
                                simulateLate = val;
                              });
                            },
                            activeColor: const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Ô nhập nội dung
                    const Text('Nội dung tóm tắt tiến độ tuần:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập các đầu việc nhóm đã hoàn thành trong tuần...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Ô nhập link
                    const Text('Đường dẫn báo cáo / mã nguồn (GitHub, Google Drive):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: linkController,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        prefixIcon: const Icon(Icons.link_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nút xác nhận nộp
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isCurrentlyLate || simulateLate)
                              ? const Color(0xFFEA580C)
                              : const Color(0xFF0072E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          DateTime submitTime = DateTime.now();
                          if (simulateLate) {
                            submitTime = task.deadline.add(const Duration(hours: 3, minutes: 15));
                          }

                          final result = _taskService.submitTask(
                            taskId: task.id,
                            note: noteController.text.trim(),
                            attachmentLink: linkController.text.trim(),
                            customSubmitTime: submitTime,
                          );

                          Navigator.of(ctx).pop();

                          _showResultDialog(
                            title: result['isLate'] ? 'Đã Ghi Nhận (Nộp Trễ)' : 'Nộp Bài Thành Công',
                            message: result['message'],
                            isLate: result['isLate'],
                          );
                        },
                        child: Text(
                          (isCurrentlyLate || simulateLate)
                              ? 'XÁC NHẬN NỘP BÀI (GẮN CỜ NỘP TRỄ)'
                              : 'XÁC NHẬN NỘP BÀI (ĐÚNG HẠN)',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
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

  void _showResultDialog({required String title, required String message, required bool isLate}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isLate ? Icons.assignment_late_rounded : Icons.check_circle_rounded,
              color: isLate ? const Color(0xFFEA580C) : const Color(0xFF10B981),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: isLate ? const Color(0xFFEA580C) : const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ĐÃ HIỂU', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
