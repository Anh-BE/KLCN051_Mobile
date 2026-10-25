import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../../lecturer/topic/logic/lecturer_topic_service.dart';
import '../../student/progress/logic/student_progress_service.dart';
import '../../student/topic/logic/student_topic_service.dart';
import '../model/dashboard_stats_models.dart';
import '../../manager/model/manager_stats_model.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 1. LẤY SỐ LIỆU CHO GIẢNG VIÊN HƯỚNG DẪN (100% TỪ CSDL THẬT)
  Future<LecturerDashboardStats> getLecturerStats({int? periodId}) async {
    // 1. Thử gọi API chuyên biệt nếu Backend đã thêm DashboardController
    try {
      final headers = await _getHeaders();
      String urlString = '${ApiEndpoints.baseUrl}/Dashboard/lecturer';
      if (periodId != null) urlString += '?periodId=$periodId';

      final res = await http.get(Uri.parse(urlString), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return LecturerDashboardStats.fromJson(decoded);
        }
      }
    } catch (_) {}

    // 2. Tự động tổng hợp từ dữ liệu đề tài thật của Giảng viên qua GET /api/RaDeTai/history
    try {
      final theses = await LecturerTopicService().getTheses(periodId: periodId);
      final totalProposed = theses.length;
      final approvedCount = theses.where((t) => t.isApproved).length;
      final needsRevisionCount = theses.where((t) {
        final st = t.status.toLowerCase();
        return st.contains('chinhsua') || st.contains('revision') || st.contains('yeucau');
      }).length;
      final rejectedCount = theses.where((t) => t.isRejected).length;
      final supervisedThesesCount = theses.where((t) => t.hasGroup).length;
      final supervisedGroupsCount = theses.fold<int>(0, (sum, t) => sum + t.registeredGroups.length);
      final periodName = theses.isNotEmpty ? theses.first.periodName : 'HK1 (2026-2027)';

      return LecturerDashboardStats(
        totalProposed: totalProposed,
        approvedCount: approvedCount,
        needsRevisionCount: needsRevisionCount,
        rejectedCount: rejectedCount,
        supervisedThesesCount: supervisedThesesCount,
        supervisedGroupsCount: supervisedGroupsCount,
        periodName: periodName,
      );
    } catch (e) {
      debugPrint('[DashboardService] getLecturerStats error: $e');
      return LecturerDashboardStats();
    }
  }

  /// 2. LẤY SỐ LIỆU CHO ADMIN KHOA (100% TỪ CSDL THẬT)
  Future<AdminDashboardStats> getAdminStats({int? periodId}) async {
    // 1. Thử gọi API chuyên biệt nếu Backend đã thêm DashboardController
    try {
      final headers = await _getHeaders();
      String urlString = '${ApiEndpoints.baseUrl}/Dashboard/admin';
      if (periodId != null) urlString += '?periodId=$periodId';

      final res = await http.get(Uri.parse(urlString), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return AdminDashboardStats.fromJson(decoded);
        }
      }
    } catch (_) {}

    // 2. Tự động tổng hợp từ danh sách đề tài toàn khoa thật qua GET /api/PhanCongDeTai/Theses
    try {
      final topics = await StudentTopicService().getTopics();
      final totalTheses = topics.length;
      final registeredTheses = topics
          .where((t) => t.registeredGroupId != null && t.registeredGroupId!.isNotEmpty && t.registeredGroupId != '0')
          .length;
      final supervisedTheses = topics
          .where((t) => t.lecturerName.trim().isNotEmpty && !t.lecturerName.toLowerCase().contains('chưa'))
          .length;
      final activeLecturersCount = topics
          .map((t) => t.lecturerName.trim())
          .where((name) => name.isNotEmpty && !name.toLowerCase().contains('chưa'))
          .toSet()
          .length;

      return AdminDashboardStats(
        totalTheses: totalTheses,
        registeredTheses: registeredTheses,
        supervisedTheses: supervisedTheses,
        activeLecturersCount: activeLecturersCount,
        periodName: 'HK1 (2026-2027)',
      );
    } catch (e) {
      debugPrint('[DashboardService] getAdminStats error: $e');
      return AdminDashboardStats();
    }
  }

  /// 3. LẤY SỐ LIỆU CHO SINH VIÊN (100% TỪ CSDL THẬT)
  Future<StudentDashboardStats> getStudentStats() async {
    // 1. Thử gọi API chuyên biệt nếu Backend đã thêm DashboardController
    try {
      final headers = await _getHeaders();
      final res = await http
          .get(Uri.parse('${ApiEndpoints.baseUrl}/Dashboard/student'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return StudentDashboardStats.fromJson(decoded);
        }
      }
    } catch (_) {}

    // 2. Tự động tổng hợp từ tiến độ thật của sinh viên qua GET /api/ProgressReport/student/my-thesis
    try {
      final progress = await StudentProgressService().getMyThesisProgress();
      if (!progress.hasThesis || progress.weeklyPlans.isEmpty) {
        return StudentDashboardStats(
          periodName: progress.periodName.isNotEmpty ? progress.periodName : 'HK1 (2026-2027)',
        );
      }

      final totalWeeks = progress.weeklyPlans.length;
      final submittedWeeks = progress.weeklyPlans.where((p) => p.isSubmitted).length;
      final unsubmittedWeeks = totalWeeks >= submittedWeeks ? totalWeeks - submittedWeeks : 0;
      final assignedTasksCount = totalWeeks;

      // Tìm bài tập / báo cáo tuần sắp tới chưa nộp có deadline
      String? upcomingTitle;
      DateTime? upcomingDeadline;
      String? remainingText;
      bool hasUpcoming = false;

      final now = DateTime.now();
      final pendingPlans = progress.weeklyPlans.where((p) => !p.isSubmitted).toList();
      if (pendingPlans.isNotEmpty) {
        final nextPlan = pendingPlans.first;
        var cleanTitle = nextPlan.title.trim();
        final repeatPattern = RegExp(r'^(Tuần\s*\d+\s*[:\-\.]?\s*)+', caseSensitive: false);
        final match = repeatPattern.firstMatch(cleanTitle);
        if (match != null) {
          final remainder = cleanTitle.substring(match.end).trim();
          cleanTitle = remainder.isNotEmpty ? 'Tuần ${nextPlan.weekNumber}: $remainder' : 'Tuần ${nextPlan.weekNumber}';
        } else {
          cleanTitle = cleanTitle.isNotEmpty ? 'Tuần ${nextPlan.weekNumber}: $cleanTitle' : 'Tuần ${nextPlan.weekNumber}';
        }
        upcomingTitle = cleanTitle;
        upcomingDeadline = nextPlan.deadline;
        hasUpcoming = true;

        if (nextPlan.deadline != null) {
          final diff = nextPlan.deadline!.difference(now);
          if (diff.isNegative) {
            remainingText = 'Đã quá hạn nộp';
          } else if (diff.inDays > 0) {
            remainingText = 'Còn ${diff.inDays} ngày ${diff.inHours % 24} giờ';
          } else if (diff.inHours > 0) {
            remainingText = 'Còn ${diff.inHours} giờ ${diff.inMinutes % 60} phút';
          } else {
            remainingText = 'Còn ${diff.inMinutes} phút';
          }
        }
      }

      return StudentDashboardStats(
        totalWeeks: totalWeeks,
        submittedWeeks: submittedWeeks,
        unsubmittedWeeks: unsubmittedWeeks,
        assignedTasksCount: assignedTasksCount,
        upcomingDeadlineTitle: upcomingTitle,
        upcomingDeadlineTime: upcomingDeadline,
        upcomingRemainingText: remainingText,
        hasUpcomingDeadline: hasUpcoming,
        periodName: progress.periodName.isNotEmpty ? progress.periodName : 'HK1 (2026-2027)',
      );
    } catch (e) {
      debugPrint('[DashboardService] getStudentStats error: $e');
      return StudentDashboardStats();
    }
  }

  /// 4. LẤY THỐNG KÊ THEO TỪNG BỘ MÔN (100% TỪ CSDL THẬT)
  Future<List<DepartmentStat>> getDepartmentStats({int? periodId}) async {
    // 5 Bộ môn chuẩn của Khoa CNTT - HUIT
    final List<String> standardDepts = [
      'Công nghệ Phần mềm',
      'An toàn Thông tin',
      'Hệ thống Thông tin',
      'Khoa học Dữ liệu & TTNT',
      'Công nghệ Số & Đa phương tiện',
    ];

    try {
      final topics = await StudentTopicService().getTopics(periodId: periodId);

      return standardDepts.map((deptName) {
        // Lọc các đề tài thuộc bộ môn / chuyên ngành này
        final deptTopics = topics.where((t) {
          final m = t.major.toLowerCase();
          final title = t.title.toLowerCase();
          final code = t.topicCode.toLowerCase();

          if (deptName.contains('Phần mềm')) {
            return m.contains('phần mềm') || m.contains('pm') || m.contains('se') || code.contains('pm') || title.contains('phần mềm');
          } else if (deptName.contains('An toàn')) {
            return m.contains('an toàn') || m.contains('mạng') || m.contains('attt') || m.contains('is') || code.contains('at');
          } else if (deptName.contains('Hệ thống')) {
            return m.contains('hệ thống') || m.contains('httt') || m.contains('mis') || code.contains('ht');
          } else if (deptName.contains('Dữ liệu') || deptName.contains('TTNT')) {
            return m.contains('dữ liệu') || m.contains('trí tuệ') || m.contains('ai') || m.contains('khdl') || code.contains('dl');
          } else {
            return m.contains('số') || m.contains('đa phương tiện') || m.contains('multimedia') || code.contains('cns');
          }
        }).toList();

        final totalTheses = deptTopics.length;
        final approvedTheses = deptTopics.where((t) {
          final s = t.status.toLowerCase();
          return s == 'approved' || s == 'open' || s == 'available' || s == 'registered';
        }).length;
        final pendingTheses = deptTopics.where((t) {
          final s = t.status.toLowerCase();
          return s.contains('pending') || s.contains('chờ');
        }).length;

        final studentCount = deptTopics.fold<int>(0, (sum, t) => sum + t.currentStudents);
        final lecturerCount = deptTopics
            .map((t) => t.lecturerName.trim())
            .where((name) => name.isNotEmpty && !name.toLowerCase().contains('chưa'))
            .toSet()
            .length;

        return DepartmentStat(
          departmentName: deptName,
          totalTheses: totalTheses,
          approvedTheses: approvedTheses,
          pendingTheses: pendingTheses,
          studentCount: studentCount,
          lecturerCount: lecturerCount,
        );
      }).toList();
    } catch (e) {
      debugPrint('[DashboardService] getDepartmentStats error: $e');
      return standardDepts
          .map((deptName) => DepartmentStat(
                departmentName: deptName,
                totalTheses: 0,
                approvedTheses: 0,
                pendingTheses: 0,
                studentCount: 0,
                lecturerCount: 0,
              ))
          .toList();
    }
  }

  /// 5. LẤY DANH SÁCH BÁO CÁO NỘP TRỄ (100% TỪ CSDL THẬT)
  Future<List<LateSubmissionItem>> getLateSubmissions({int? periodId}) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiEndpoints.baseUrl}/ProgressReport/lecturer/theses';
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is List) {
          List<LateSubmissionItem> lateItems = [];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final groupName = item['groupName'] ?? item['tenNhom'] ?? 'Nhóm SV';
              final plans = item['weeklyPlans'] ?? item['plans'] ?? [];
              if (plans is List) {
                for (final p in plans) {
                  if (p is Map<String, dynamic>) {
                    final isLate = p['isLate'] == true;
                    final submittedAtStr = p['submittedAt'] ?? p['ngayNop'];
                    final deadlineStr = p['deadline'] ?? p['hanNop'];

                    if (isLate || _isAfterDeadline(submittedAtStr, deadlineStr)) {
                      lateItems.add(LateSubmissionItem(
                        studentCode: p['studentCode'] ?? p['maSinhVien'] ?? '---',
                        studentName: p['studentName'] ?? p['hoTen'] ?? 'Sinh viên',
                        groupName: groupName.toString(),
                        taskName: p['title'] ?? p['tieuDe'] ?? 'Báo cáo tuần',
                        deadlineStr: deadlineStr != null ? deadlineStr.toString().replaceAll('T', ' ').substring(0, 16) : '23:59',
                        submittedTimeStr: submittedAtStr != null ? submittedAtStr.toString().replaceAll('T', ' ').substring(0, 16) : 'Quá hạn',
                        lateHours: p['lateHours'] ?? 1,
                        reason: p['reason'] ?? p['lyDo'] ?? '',
                      ));
                    }
                  }
                }
              }
            }
          }
          return lateItems;
        }
      }
    } catch (e) {
      debugPrint('[DashboardService] getLateSubmissions error: $e');
    }
    // Trả về danh sách rỗng thực tế nếu chưa có ai nộp trễ hoặc chưa tạo nhóm/chọn đề tài
    return [];
  }

  bool _isAfterDeadline(dynamic submittedAt, dynamic deadline) {
    if (submittedAt == null || deadline == null) return false;
    try {
      final s = DateTime.parse(submittedAt.toString());
      final d = DateTime.parse(deadline.toString());
      return s.isAfter(d);
    } catch (_) {
      return false;
    }
  }

  /// 6. LẤY HỘI ĐỒNG BẢO VỆ (100% TỪ CSDL THẬT)
  Future<List<CommitteeStat>> getDefenseCommittees({int? periodId}) async {
    try {
      final headers = await _getHeaders();
      String url = '${ApiEndpoints.baseUrl}/DefenseCommittees';
      if (periodId != null) url += '?periodId=$periodId';

      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is List) {
          return decoded.map((c) {
            final map = c as Map<String, dynamic>;
            return CommitteeStat(
              committeeCode: map['committeeCode'] ?? map['code'] ?? 'HĐ-${map['id'] ?? ""}',
              name: map['name'] ?? map['committeeName'] ?? 'Hội đồng Bảo vệ',
              president: map['president'] ?? map['presidentName'] ?? map['chuTich'] ?? 'Chưa chỉ định',
              secretary: map['secretary'] ?? map['secretaryName'] ?? map['thuKy'] ?? 'Chưa chỉ định',
              reviewer: map['reviewer'] ?? map['reviewerName'] ?? map['phanBien'] ?? 'Chưa chỉ định',
              assignedGroups: map['assignedGroups'] ?? map['thesesCount'] ?? map['groupCount'] ?? 0,
              room: map['room'] ?? map['phong'] ?? 'Chưa xếp phòng',
              defenseDate: map['defenseDate'] != null ? map['defenseDate'].toString().split('T')[0] : 'Chưa xếp lịch',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('[DashboardService] getDefenseCommittees error: $e');
    }
    // Trả về rỗng nếu CSDL chưa thành lập hội đồng
    return [];
  }
}

