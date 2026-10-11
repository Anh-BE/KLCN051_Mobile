import 'package:flutter/material.dart';
import '../model/student_task_model.dart';
import 'notification_service.dart';

class StudentTaskService extends ChangeNotifier {
  static final StudentTaskService _instance = StudentTaskService._internal();
  factory StudentTaskService() => _instance;
  StudentTaskService._internal() {
    _initSampleTasks();
  }

  final List<StudentTaskItem> _tasks = [];

  List<StudentTaskItem> get tasks => List.unmodifiable(_tasks);

  // Lấy các task chưa hoàn thành
  List<StudentTaskItem> get activeTasks =>
      _tasks.where((t) => !t.isSubmitted).toList();

  // Task gấp nhất cần làm (nhắc việc)
  StudentTaskItem? get upcomingUrgentTask {
    final uncompleted = _tasks.where((t) => !t.isSubmitted).toList();
    if (uncompleted.isEmpty) return null;
    uncompleted.sort((a, b) => a.deadline.compareTo(b.deadline));
    return uncompleted.first;
  }

  void _initSampleTasks() {
    // Luồng logic: Thiết lập mốc thời gian kèm theo giờ cụ thể 23 giờ 59 phút
    final now = DateTime.now();

    _tasks.addAll([
      // 1. Task quá hạn (để test nộp trễ)
      StudentTaskItem(
        id: 'TASK-W04',
        title: 'Báo cáo tiến độ Tuần 4: Thiết kế CSDL & Sơ đồ ERD',
        description: 'Nộp báo cáo chi tiết thiết kế các bảng CSDL SQL Server và sơ đồ tương quan thực thể, kèm đường link mã nguồn database.',
        deadline: DateTime(now.year, now.month, now.day - 2, 23, 59, 59),
        weekName: 'Tuần 4',
        target: 'Nộp cho GVHD: ThS. Vũ Văn Vinh',
        isSubmitted: false,
      ),

      // 2. Task đang trong hạn (gần tới hạn 23:59)
      StudentTaskItem(
        id: 'TASK-W05',
        title: 'Nộp đề cương chi tiết & Báo cáo tiến độ Tuần 5',
        description: 'Hoàn thiện đề cương chi tiết đề tài nghiên cứu, phân công công việc các thành viên trong nhóm và mockup giao diện Mobile.',
        deadline: DateTime(now.year, now.month, now.day + 2, 23, 59, 59),
        weekName: 'Tuần 5 (Hiện tại)',
        target: 'Nộp cho GVHD: ThS. Vũ Văn Vinh',
        isSubmitted: false,
      ),

      // 3. Task sắp tới (Tuần 6)
      StudentTaskItem(
        id: 'TASK-W06',
        title: 'Báo cáo tiến độ Tuần 6: Xây dựng Module Mobile & API',
        description: 'Tích hợp xác thực JWT, kết nối API Backend ASP.NET Core và giao diện màn hình Đăng ký / Duyệt đồ án.',
        deadline: DateTime(now.year, now.month, now.day + 9, 23, 59, 59),
        weekName: 'Tuần 6',
        target: 'Nộp cho GVHD: ThS. Vũ Văn Vinh',
        isSubmitted: false,
      ),

      // 4. Task đã nộp đúng hạn trong quá khứ
      StudentTaskItem(
        id: 'TASK-W02',
        title: 'Báo cáo tiến độ Tuần 2: Khảo sát hiện trạng & Tổng quan',
        description: 'Khảo sát các hệ thống quản lý đề tài tốt nghiệp hiện có và đề xuất giải pháp kỹ thuật cho HUIT.',
        deadline: DateTime(now.year, now.month, now.day - 14, 23, 59, 59),
        weekName: 'Tuần 2',
        target: 'Nộp cho GVHD: ThS. Vũ Văn Vinh',
        isSubmitted: true,
        submittedAt: DateTime(now.year, now.month, now.day - 15, 20, 15, 0),
        isLate: false,
        submissionNote: 'Nhóm đã nộp đầy đủ file báo cáo PDF và tài liệu khảo sát.',
        attachmentLink: 'https://github.com/Anh-BE/KLCN051_Mobile',
      ),
    ]);
  }

  // Luồng logic: Xử lý nộp bài
  // Khi thời gian vượt qua 23:59:59 (bước sang 00:00 ngày tiếp theo),
  // hệ thống KHÔNG KHÓA chức năng nộp bài, mà tự động gắn cờ isLate = true
  Map<String, dynamic> submitTask({
    required String taskId,
    required String note,
    required String attachmentLink,
    DateTime? customSubmitTime, // Dùng để kiểm thử giả lập thời gian nộp
  }) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      throw Exception('Không tìm thấy công việc này!');
    }

    final task = _tasks[index];
    final submitTime = customSubmitTime ?? DateTime.now();

    // Kiểm tra mốc 23:59:59
    final isLate = submitTime.isAfter(task.deadline);

    task.isSubmitted = true;
    task.submittedAt = submitTime;
    task.isLate = isLate;
    task.submissionNote = note;
    task.attachmentLink = attachmentLink;

    notifyListeners();

    return {
      'isLate': isLate,
      'submittedAt': submitTime,
      'deadline': task.deadline,
      'message': isLate
          ? 'Bài nộp được ghi nhận thành công, nhưng hệ thống tự động gắn trạng thái "NỘP TRỄ" (quá hạn 23:59).'
          : 'Bài nộp được ghi nhận thành công và đúng hạn!',
    };
  }

  // Giảng viên hoặc Nhà quản lý tạo nhiệm vụ và thiết lập deadline
  // Luồng logic: Khi định ra ngày hết hạn cho một công việc, hệ thống tự động
  // thiết lập kèm theo thời gian cụ thể là 23 giờ 59 phút 59 giây làm mốc giới hạn.
  StudentTaskItem createTask({
    required String title,
    required String description,
    required DateTime deadlineDate,
    required String weekName,
    required String target,
  }) {
    // Tự động gán giờ giới hạn là 23:59:59 của ngày đã chọn
    final absoluteDeadline = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
      23,
      59,
      59,
    );

    final newTask = StudentTaskItem(
      id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      deadline: absoluteDeadline,
      weekName: weekName,
      target: target,
      isSubmitted: false,
    );

    _tasks.insert(0, newTask);
    notifyListeners();

    // Tự động bắn thông báo deadline mới vào Quả Chuông của Sinh viên
    NotificationService().addNotification(
      title: 'Giảng viên giao deadline mới: $weekName',
      message: 'Nhiệm vụ "$title" có hạn nộp tuyệt đối là 23:59:59 ngày ${deadlineDate.day}/${deadlineDate.month}. Hệ thống đã đặt lịch nhắc việc tự động!',
      type: NotificationType.newDeadline,
      relatedTaskId: newTask.id,
    );

    return newTask;
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  // Khôi phục trạng thái để kiểm thử lại
  void resetTaskForTesting(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isSubmitted = false;
      _tasks[index].submittedAt = null;
      _tasks[index].isLate = false;
      _tasks[index].submissionNote = null;
      _tasks[index].attachmentLink = null;
      notifyListeners();
    }
  }
}
