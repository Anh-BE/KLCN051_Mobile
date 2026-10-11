import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../model/weekly_report_model.dart';

class WeeklyReportService {
  static final WeeklyReportService _instance = WeeklyReportService._internal();
  factory WeeklyReportService() => _instance;
  WeeklyReportService._internal();

  // Cache cục bộ hỗ trợ test mượt mà ngay cả khi offline
  final Map<int, List<WeeklyTimelineItemModel>> _localTimelines = {};

  // Mock data danh sách đề tài & tiến độ báo cáo tuần
  final List<LecturerThesisProgressModel> _mockTheses = [
    LecturerThesisProgressModel(
      thesisId: 30,
      thesisCode: 'KLCN030',
      thesisTitle: 'Nghiên cứu ứng dụng trí tuệ nhân tạo và học sâu trong giám sát năng lượng khuôn viên HUIT',
      groupId: 101,
      groupName: 'Nhóm Nghiên cứu AI & IoT HUIT',
      leaderId: 1,
      leaderCode: '2001210123',
      leaderName: 'Nguyễn Văn An',
      leaderEmail: 'an.nv@sinhvien.huit.edu.vn',
      leaderPhone: '0987 654 321',
      memberCount: 3,
      totalWeeks: 12,
      submittedWeeksCount: 2,
      approvedWeeksCount: 1,
      pendingWeeksCount: 1,
      progressPercentage: 8.3,
    ),
    LecturerThesisProgressModel(
      thesisId: 26,
      thesisCode: 'KLCN026',
      thesisTitle: 'Xây dựng ứng dụng di động quản lý khóa luận tốt nghiệp đa nền tảng Flutter và Microservices',
      groupId: 102,
      groupName: 'Nhóm Kỹ thuật phần mềm KLCN051',
      leaderId: 2,
      leaderCode: '2001210456',
      leaderName: 'Trần Thị Bích',
      leaderEmail: 'bich.tt@sinhvien.huit.edu.vn',
      leaderPhone: '0912 345 678',
      memberCount: 3,
      totalWeeks: 12,
      submittedWeeksCount: 3,
      approvedWeeksCount: 3,
      pendingWeeksCount: 0,
      progressPercentage: 25.0,
    ),
    LecturerThesisProgressModel(
      thesisId: 2,
      thesisCode: 'KLCN002',
      thesisTitle: 'Phân tích dữ liệu lớn trên nền tảng Apache Spark & Dự báo xu hướng tiêu dùng trực tuyến',
      groupId: 103,
      groupName: 'Nhóm Data Science HUIT K12',
      leaderId: 3,
      leaderCode: '2001210789',
      leaderName: 'Lê Hoàng Cường',
      leaderEmail: 'cuong.lh@sinhvien.huit.edu.vn',
      leaderPhone: '0978 999 111',
      memberCount: 2,
      totalWeeks: 12,
      submittedWeeksCount: 2,
      approvedWeeksCount: 1,
      pendingWeeksCount: 1,
      progressPercentage: 8.3,
    ),
    LecturerThesisProgressModel(
      thesisId: 3,
      thesisCode: 'KLCN003',
      thesisTitle: 'Xây dựng sàn giao dịch điện tử phi tập trung trên mạng Blockchain Ethereum và Polygon',
      groupId: 104,
      groupName: 'Nhóm Blockchain Labs',
      leaderId: 4,
      leaderCode: '2001210999',
      leaderName: 'Phạm Minh Đức',
      leaderEmail: 'duc.pm@sinhvien.huit.edu.vn',
      leaderPhone: '0933 123 456',
      memberCount: 3,
      totalWeeks: 12,
      submittedWeeksCount: 0,
      approvedWeeksCount: 0,
      pendingWeeksCount: 0,
      progressPercentage: 0.0,
    ),
  ];

  /// 1. Lấy danh sách đề tài của Giảng viên và thống kê nộp báo cáo tuần
  Future<List<LecturerThesisProgressModel>> getLecturerTheses({int? lecturerId}) async {
    try {
      final token = await StorageService.getToken();
      String url = '${ApiEndpoints.baseUrl}${ApiEndpoints.lecturerThesesProgress}';
      if (lecturerId != null) {
        url += '?lecturerId=$lecturerId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
        if (raw is List && raw.isNotEmpty) {
          final list = raw
              .where((e) => e != null && e is Map)
              .map((e) => LecturerThesisProgressModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          return list;
        }
      }
    } catch (e) {
      debugPrint('[WeeklyReportService] API GetLecturerTheses Error: $e. Fallback to mock.');
    }

    return List.from(_mockTheses);
  }

  /// 2. Lấy lộ trình tiến độ 12 tuần của một đề tài
  Future<List<WeeklyTimelineItemModel>> getThesisTimeline(int thesisId, {String? defaultLeaderName, String? defaultLeaderCode}) async {
    // Kiểm tra cache nội bộ nếu vừa cập nhật feedback
    if (_localTimelines.containsKey(thesisId) && _localTimelines[thesisId]!.isNotEmpty) {
      return _localTimelines[thesisId]!;
    }

    try {
      final token = await StorageService.getToken();
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.thesisTimeline}/$thesisId/timeline';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
        if (raw is List && raw.isNotEmpty) {
          final list = raw
              .where((e) => e != null && e is Map)
              .map((e) => WeeklyTimelineItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          _localTimelines[thesisId] = list;
          return list;
        }
      }
    } catch (e) {
      debugPrint('[WeeklyReportService] API GetThesisTimeline Error: $e. Fallback to mock.');
    }

    // Mock 12 tuần chuẩn HUIT
    final mockList = _generateMock12Weeks(
      thesisId: thesisId,
      leaderName: defaultLeaderName ?? 'Nguyễn Văn An',
      leaderCode: defaultLeaderCode ?? '2001210123',
    );
    _localTimelines[thesisId] = mockList;
    return mockList;
  }

  /// 3. Giảng viên gửi đánh giá & phản hồi tiến độ
  Future<Map<String, dynamic>> submitFeedback(FeedbackRequestModel request) async {
    try {
      final token = await StorageService.getToken();
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.reportFeedback}';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Cập nhật local timeline cache
        _updateLocalCache(request);
        return {'success': true, 'message': 'Đã gửi đánh giá và nhận xét thành công!'};
      } else {
        final dynamic errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final msg = errorBody is Map ? (errorBody['message'] ?? 'Lỗi từ máy chủ') : 'Lỗi từ máy chủ';
        return {'success': false, 'message': msg.toString()};
      }
    } catch (e) {
      debugPrint('[WeeklyReportService] API SubmitFeedback Error: $e. Using local update.');
      // Giả lập lưu thành công khi offline để người dùng trải nghiệm trơn tru
      _updateLocalCache(request);
      return {
        'success': true,
        'message': 'Đã lưu phản hồi thành công (Chế độ ngoại tuyến).',
      };
    }
  }

  void _updateLocalCache(FeedbackRequestModel request) {
    if (_localTimelines.containsKey(request.thesisId)) {
      final list = _localTimelines[request.thesisId]!;
      final index = list.indexWhere((w) => w.reportId == request.reportId || w.planId == request.planId);
      if (index != -1) {
        final current = list[index];
        list[index] = current.copyWith(
          submissionStatus: request.submissionStatus,
          supervisorFeedback: request.supervisorFeedback,
          supervisorScore: request.supervisorScore,
          isPassed: request.isPassed,
        );
      }
    }

    // Cập nhật thống kê trong mock theses
    final tIdx = _mockTheses.indexWhere((t) => t.thesisId == request.thesisId);
    if (tIdx != -1) {
      final t = _mockTheses[tIdx];
      int approved = t.approvedWeeksCount;
      int pending = t.pendingWeeksCount > 0 ? t.pendingWeeksCount - 1 : 0;
      if (request.isPassed) approved++;
      _mockTheses[tIdx] = LecturerThesisProgressModel(
        thesisId: t.thesisId,
        thesisCode: t.thesisCode,
        thesisTitle: t.thesisTitle,
        groupId: t.groupId,
        groupName: t.groupName,
        leaderId: t.leaderId,
        leaderCode: t.leaderCode,
        leaderName: t.leaderName,
        leaderEmail: t.leaderEmail,
        leaderPhone: t.leaderPhone,
        memberCount: t.memberCount,
        totalWeeks: t.totalWeeks,
        submittedWeeksCount: t.submittedWeeksCount,
        approvedWeeksCount: approved,
        pendingWeeksCount: pending,
        progressPercentage: t.totalWeeks > 0 ? (approved / t.totalWeeks * 100) : 0,
      );
    }
  }

  /// Sinh dữ liệu mẫu 12 tuần với người nộp CỐ ĐỊNH LÀ NHÓM TRƯỞNG
  List<WeeklyTimelineItemModel> _generateMock12Weeks({
    required int thesisId,
    required String leaderName,
    required String leaderCode,
  }) {
    final now = DateTime.now();

    final titles = [
      'Khảo sát hiện trạng & Lập kế hoạch chi tiết',
      'Phân tích yêu cầu nghiệp vụ & Thiết kế kiến trúc tổng thể',
      'Thiết kế Cơ sở dữ liệu ERD & API Contract',
      'Xây dựng phân hệ xác thực & Quản lý người dùng',
      'Xây dựng các chức năng cốt lõi (Module chính đợt 1)',
      'Tích hợp giao diện Frontend Web & Mobile App',
      'Báo cáo sơ kết giữa kỳ với Giảng viên hướng dẫn',
      'Phát triển Module nâng cao & Xử lý nghiệp vụ phụ trợ',
      'Kiểm thử đơn vị (Unit Test) & Tối ưu hóa hiệu năng',
      'Kiểm thử tích hợp (Integration Test) & Sửa lỗi hệ thống',
      'Hoàn thiện báo cáo khóa luận, Slide thuyết minh & Video demo',
      'Nghiệm thu cuối kỳ, tổng duyệt sản phẩm và chuẩn bị bảo vệ',
    ];

    final requirements = [
      'Khảo sát tài liệu nghiên cứu liên quan, xác định mục tiêu và phạm vi đề tài, phân công nhiệm vụ cụ thể cho từng thành viên.',
      'Vẽ sơ đồ Use Case, Activity Diagram và định nghĩa luồng dữ liệu hệ thống (DFD / BPMN).',
      'Thiết kế lược đồ quan hệ CSDL chuẩn hóa 3NF, viết tài liệu đặc tả RESTful API.',
      'Lập trình module Login, Register, phân quyền RBAC dựa trên JWT Bearer Token.',
      'Lập trình các nghiệp vụ chính theo yêu cầu đề cương được phê duyệt.',
      'Kết nối Frontend Flutter/Vue với Backend API, đảm bảo giao diện đáp ứng (responsive).',
      'Thuyết minh sản phẩm giai đoạn 1, giải trình tiến độ và tiếp thu ý kiến của GVHD.',
      'Cài đặt các tính năng mở rộng, tích hợp AI, thông báo Realtime hoặc thanh toán.',
      'Viết kịch bản kiểm thử, đo lường thời gian phản hồi API và tối ưu câu lệnh truy vấn.',
      'Test toàn diện luồng nghiệp vụ trên môi trường Staging, ghi nhận Bug log.',
      'Soạn thảo tài liệu thuyết minh đầy đủ theo mẫu chuẩn của Khoa CNTT - ĐH Công Thương.',
      'Đóng gói mã nguồn, triển khai ứng dụng lên máy chủ và kiểm tra slide thuyết trình.',
    ];

    List<WeeklyTimelineItemModel> list = [];

    for (int i = 0; i < 12; i++) {
      final weekNum = i + 1;
      final deadline = now.add(Duration(days: (i - 1) * 7));
      final formattedDeadline = '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year} 23:59';

      if (weekNum == 1) {
        // Tuần 1: Đã duyệt (Approved)
        final submitTime = deadline.subtract(const Duration(days: 1, hours: 2));
        list.add(
          WeeklyTimelineItemModel(
            planId: 1000 + weekNum,
            thesisId: thesisId,
            weekNumber: weekNum,
            title: titles[i],
            detailedRequirements: requirements[i],
            deadline: deadline,
            formattedDeadline: formattedDeadline,
            reportId: 501,
            content: 'Nhóm đã hoàn thành khảo sát 15 bài báo khoa học liên quan, thống nhất công nghệ sử dụng (.NET 8 + Flutter + PostgreSQL), lập bảng phân công Gantt Chart chi tiết 12 tuần trong file đính kèm.',
            reportFileUrl: 'https://storage.huit.edu.vn/reports/tuan_01_khao_sat.pdf',
            submittedAt: submitTime,
            formattedSubmittedAt: '${submitTime.day.toString().padLeft(2, '0')}/${submitTime.month.toString().padLeft(2, '0')}/${submitTime.year} 15:30',
            submissionStatus: 'Approved',
            submitterRole: 'Nhóm trưởng (Đại diện nộp)',
            submitterName: leaderName,
            submitterCode: leaderCode,
            supervisorFeedback: 'Kế hoạch rõ ràng, phân công hợp lý. Đã đối chiếu đúng mục tiêu đề cương. Cho phép nhóm triển khai tiếp Tuần 2 theo đúng tiến độ.',
            supervisorScore: 9.0,
            isPassed: true,
          ),
        );
      } else if (weekNum == 2) {
        // Tuần 2: Đang chờ duyệt (Pending)
        final submitTime = now.subtract(const Duration(hours: 4));
        list.add(
          WeeklyTimelineItemModel(
            planId: 1000 + weekNum,
            thesisId: thesisId,
            weekNumber: weekNum,
            title: titles[i],
            detailedRequirements: requirements[i],
            deadline: deadline,
            formattedDeadline: formattedDeadline,
            reportId: 502,
            content: 'Kính gửi thầy/cô,\nNhóm đã hoàn thiện tài liệu đặc tả yêu cầu SRS phiên bản 1.0 cùng bộ sơ đồ Use Case và Class Diagram chi tiết. Nhóm đã đẩy mã nguồn thiết kế lên repository Git và đính kèm báo cáo tiến độ tuần 2.',
            reportFileUrl: 'https://storage.huit.edu.vn/reports/tuan_02_thiet_ke_kientruc.docx',
            submittedAt: submitTime,
            formattedSubmittedAt: '${submitTime.day.toString().padLeft(2, '0')}/${submitTime.month.toString().padLeft(2, '0')}/${submitTime.year} 10:15',
            submissionStatus: 'Pending',
            submitterRole: 'Nhóm trưởng (Đại diện nộp)',
            submitterName: leaderName,
            submitterCode: leaderCode,
            supervisorFeedback: null,
            supervisorScore: null,
            isPassed: null,
          ),
        );
      } else {
        // Tuần 3..12: Chưa nộp (NotSubmitted)
        list.add(
          WeeklyTimelineItemModel(
            planId: 1000 + weekNum,
            thesisId: thesisId,
            weekNumber: weekNum,
            title: titles[i],
            detailedRequirements: requirements[i],
            deadline: deadline,
            formattedDeadline: formattedDeadline,
            reportId: null,
            content: null,
            reportFileUrl: null,
            submittedAt: null,
            formattedSubmittedAt: null,
            submissionStatus: 'NotSubmitted',
            submitterRole: 'Nhóm trưởng (Đại diện nộp)',
            submitterName: leaderName,
            submitterCode: leaderCode,
            supervisorFeedback: null,
            supervisorScore: null,
            isPassed: null,
          ),
        );
      }
    }

    return list;
  }
}
