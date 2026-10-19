import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Địa chỉ Backend ASP.NET Core:
  // - Khi chạy trên Web / Windows Desktop: gọi trực tiếp http://localhost:5293/api (hoặc https://localhost:7292/api)
  // - Khi chạy trên Android Emulator: đổi localhost thành 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:5293/api';
      }
      return 'http://localhost:5293/api';
    }
    // Dành cho Android Emulator
    return 'http://10.0.2.2:5293/api';
  }

  static const String login = '/Auth/login';
  static const String theses = '/PhanCongDeTai/Theses';
  static const String studentProfile = '/ChucNangCuaSinhvien/Profile';

  // --- Chức năng Sinh viên & Nhóm Khóa luận ---
  static const String studentAllGroups = '/ChucNangCuaSinhvien/AllGroups';
  static const String studentGroupCreate = '/ChucNangCuaSinhvien/Create';
  static const String studentMyGroup = '/ChucNangCuaSinhvien/MyGroup';
  static String studentGroupInvite(int groupId) => '/ChucNangCuaSinhvien/$groupId/Invite';
  static String studentGroupRequestJoin(int groupId) => '/ChucNangCuaSinhvien/$groupId/RequestJoin';
  static String studentGroupApproveRequest(int groupId, int requestId) =>
      '/ChucNangCuaSinhvien/$groupId/Requests/$requestId/Approve';
  static String studentGroupRejectRequest(int groupId, int requestId) =>
      '/ChucNangCuaSinhvien/$groupId/Requests/$requestId/Reject';
  static String studentGroupRegisterThesis(int groupId) =>
      '/ChucNangCuaSinhvien/$groupId/RegisterThesis';
  static const String studentMyInvitations = '/ChucNangCuaSinhvien/MyInvitations';
  static String studentAcceptInvitation(int requestId) =>
      '/ChucNangCuaSinhvien/Invitations/$requestId/Accept';
  static String studentRejectInvitation(int requestId) =>
      '/ChucNangCuaSinhvien/Invitations/$requestId/Reject';

  // SignalR Notification Hub URL
  static String get hubUrl {
    final base = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base/hub/notifications';
  }

  // --- Thông báo (Notifications) ---
  static const String notifications = '/Notifications';
  static const String notificationsUnreadCount = '/Notifications/unread-count';
  static String notificationMarkAsRead(int id) => '/Notifications/$id/read';
  static const String notificationMarkAllAsRead = '/Notifications/read-all';

  // --- Đợt đăng ký & Thống kê ---
  static const String registrationPeriods = '/RegistrationPeriods';
  static const String myRegistrationPeriod = '/RegistrationPeriods/my-period';
  static const String myRegistrationPeriods = '/RegistrationPeriods/my-periods';
  static const String studentsWithoutGroup = '/ThongKeBaoCao/chi-tiet-sv-chua-nhom';
  static const String reportGroupList = '/ThongKeBaoCao/chi-tiet-nhom';
  static const String unassignedGroups = '/PhanCongDeTai/Groups';

  // --- Giảng viên (Ra đề tài & Đánh giá tiến độ) ---
  static const String raDeTaiHistory = '/RaDeTai/history';
  static const String lecturerThesesProgress = '/BaoCaoTienDo/lecturer/theses';
  static const String thesisTimeline = '/BaoCaoTienDo/thesis';
  static const String reportFeedback = '/BaoCaoTienDo/feedback';

  // --- Báo cáo tiến độ Sinh viên (Progress Report) ---
  static const String studentMyThesisProgress = '/ProgressReport/student/my-thesis';
  static const String submitProgressReport = '/ProgressReport/submit';
  static String unsubmitProgressReport(int reportId) => '/ProgressReport/unsubmit/$reportId';
  static const String uploadReportFile = '/ProgressReport/upload';

  // --- Nhập điểm phân công (Scoring) ---
  static const String scoringTheses = '/NhapDiem/Theses';
  static const String scoringObjectives = '/NhapDiem/Objectives';
  static const String saveScore = '/NhapDiem/Save';
}
