import 'package:flutter/material.dart';
import 'package:app_mobile/features/auth/model/user_model.dart';
import 'package:app_mobile/features/student/tasks/logic/student_task_service.dart';
import 'package:app_mobile/features/student/tasks/model/student_task_model.dart';

class LecturerManageTasksScreen extends StatefulWidget {
  final UserModel user;

  const LecturerManageTasksScreen({super.key, required this.user});

  @override
  State<LecturerManageTasksScreen> createState() => _LecturerManageTasksScreenState();
}

class _LecturerManageTasksScreenState extends State<LecturerManageTasksScreen> {
  final StudentTaskService _taskService = StudentTaskService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _taskService,
      builder: (context, _) {
        final tasks = _taskService.tasks;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF0F766E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GIAO VIỆC & THIẾT LẬP DEADLINE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Quy chuẩn tự động: Giờ giới hạn 23:59',
                  style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('GIAO VIỆC MỚI', style: TextStyle(fontWeight: FontWeight.w800)),
            onPressed: () => _openCreateTaskDialog(),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNER GIẢI THÍCH QUY TRÌNH THIẾT LẬP
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF99F6E4), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cơ chế thiết lập Deadline tự động:',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF134E4A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• Giảng viên / Quản lý chỉ cần chọn Ngày hết hạn.\n'
                              '• Hệ thống tự động thiết lập giờ giới hạn tuyệt đối là 23:59:59 và gửi nhắc việc đến ứng dụng sinh viên.\n'
                              '• Sinh viên nộp sau 23:59 sẽ bị hệ thống tự động gắn nhãn "Nộp trễ" để GV đánh giá thái độ.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF115E59), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Danh Sách Kế Hoạch & Deadline Đã Thiết Lập',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      '${tasks.length} nhiệm vụ',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...tasks.map((task) => _buildLecturerTaskCard(task)),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLecturerTaskCard(StudentTaskItem task) {
    final deadlineFormatted =
        '${task.deadline.day.toString().padLeft(2, '0')}/${task.deadline.month.toString().padLeft(2, '0')}/${task.deadline.year} lúc 23:59:59';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.weekName,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: task.statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.statusLabel,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: task.statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            task.description,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm_on_rounded, size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 6),
                Text(
                  'Mốc giới hạn: $deadlineFormatted',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateTaskDialog() {
    final titleController = TextEditingController();
    final weekController = TextEditingController(text: 'Tuần 7');
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_task_rounded, color: Color(0xFF0F766E), size: 24),
                SizedBox(width: 8),
                Text(
                  'Thiết Lập Kế Hoạch & Deadline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tên công việc / Báo cáo tuần:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Báo cáo tiến độ Tuần 7: Kiểm thử hệ thống...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Tuần áp dụng:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: weekController,
                    decoration: InputDecoration(
                      hintText: 'Tuần 7...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Mô tả yêu cầu chi tiết:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập nội dung cần nộp...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Chọn Ngày hết hạn (Deadline):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 120)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0D9488)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF0F766E), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Ngày: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F766E), fontSize: 13),
                          ),
                          const Spacer(),
                          const Text('Đổi ngày', style: TextStyle(color: Color(0xFF0D9488), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Khối thông báo tự động gán 23:59:59
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_on_rounded, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Hệ thống tự động thiết lập giờ giới hạn: 23:59:59 ngày ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('HỦY', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;

                  _taskService.createTask(
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty ? 'Nộp báo cáo định kỳ theo yêu cầu của GVHD.' : descController.text.trim(),
                    deadlineDate: selectedDate,
                    weekName: weekController.text.trim().isEmpty ? 'Tuần' : weekController.text.trim(),
                    target: 'GVHD: ${widget.user.fullName}',
                  );

                  Navigator.of(ctx).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tạo thành công nhiệm vụ với deadline 23:59 ngày ${selectedDate.day}/${selectedDate.month}!'),
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  );
                },
                child: const Text('LƯU & THIẾT LẬP', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }
}
