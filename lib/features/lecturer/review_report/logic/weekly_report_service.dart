import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../../topic/model/lecturer_thesis_model.dart';
import '../model/weekly_report_model.dart';

class WeeklyReportService {
  static final WeeklyReportService _instance = WeeklyReportService._internal();
  factory WeeklyReportService() => _instance;
  WeeklyReportService._internal();

  /// 1. Lấy danh sách đợt khóa luận thật từ CSDL backend (GET /api/RegistrationPeriods)
  /// Đợt mới nhất luôn xếp đầu tiên (PeriodId giảm dần)
  Future<List<Map<String, dynamic>>> getPeriods() async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/RegistrationPeriods');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(res.bodyBytes));
        if (raw is List) {
          final List<Map<String, dynamic>> list = [];
          for (final item in raw) {
            if (item != null && item is Map) {
              final status = (item['status'] ?? item['Status'])?.toString();
              if (status != 'Draft') {
                final pId = item['periodId'] ?? item['PeriodId'];
                final pName = item['periodName'] ?? item['PeriodName'] ?? 'Đợt khóa luận';
                if (pId != null) {
                  final int? parsedId = pId is int ? pId : int.tryParse(pId.toString());
                  if (parsedId != null) {
                    list.add({
                      'periodId': parsedId,
                      'periodName': pName.toString(),
                    });
                  }
                }
              }
            }
          }
          list.sort((a, b) => (b['periodId'] as int).compareTo(a['periodId'] as int));
          return list;
        }
      }
    } catch (e) {
      debugPrint('[WeeklyReportService] Error fetching periods from database: $e');
    }
    return [];
  }

  /// 2. Lấy danh sách đề tài ĐÃ ĐƯỢC DUYỆT của Giảng viên thật từ CSDL (GET /api/RaDeTai/history)
  /// Phân loại: Đã có nhóm (has_group) và Chưa có nhóm (no_group)
  Future<List<LecturerThesisModel>> getApprovedTheses({
    int? periodId,
    String groupFilter = 'all', // 'all', 'has_group', 'no_group'
    String? searchQuery,
  }) async {
    List<LecturerThesisModel> result = [];

    try {
      final token = await StorageService.getToken();
      String urlString = '${ApiEndpoints.baseUrl}/RaDeTai/history';
      if (periodId != null) {
        urlString += '?periodId=$periodId';
      }

      final url = Uri.parse(urlString);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
        if (raw is List) {
          final list = raw
              .where((item) => item != null && item is Map)
              .map((item) => LecturerThesisModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();

          // CHỈ LẤY CÁC ĐỀ TÀI ĐÃ ĐƯỢC DUYỆT THEO YÊU CẦU NGHIỆP VỤ
          result = list.where((t) => t.isApproved).toList();
        }
      } else {
        debugPrint('[WeeklyReportService] getApprovedTheses returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[WeeklyReportService] Error fetching approved theses from database: $e');
    }

    // Lọc theo periodId nếu có
    if (periodId != null && result.isNotEmpty) {
      result = result.where((t) => t.periodId == periodId).toList();
    }

    // Phân loại: 'all', 'has_group', 'no_group'
    if (groupFilter == 'has_group') {
      result = result.where((t) => t.hasGroup).toList();
    } else if (groupFilter == 'no_group') {
      result = result.where((t) => !t.hasGroup).toList();
    }

    // Lọc tìm kiếm
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = _removeDiacritics(searchQuery.trim().toLowerCase());
      result = result.where((t) {
        final titleMatch = _removeDiacritics(t.thesisTitle.toLowerCase()).contains(q);
        final codeMatch = t.periodCode.toLowerCase().contains(q) || 'dt${t.thesisId}'.contains(q);

        final groupMatch = t.registeredGroups.any((g) {
          final groupNameMatch = _removeDiacritics(g.groupName.toLowerCase()).contains(q);
          final studentMatch = g.members.any((m) =>
              _removeDiacritics(m.fullName.toLowerCase()).contains(q) ||
              m.studentCode.toLowerCase().contains(q));
          return groupNameMatch || studentMatch;
        });

        return titleMatch || codeMatch || groupMatch;
      }).toList();
    }

    return result;
  }

  /// 3. Lấy lộ trình tiến độ 12 tuần của một đề tài thật từ CSDL
  /// GET /api/BaoCaoTienDo/thesis/{thesisId}/timeline
  Future<List<WeeklyTimelineItemModel>> getThesisTimeline(int thesisId, {String? defaultLeaderName, String? defaultLeaderCode}) async {
    try {
      final token = await StorageService.getToken();
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.thesisTimeline}/$thesisId/timeline';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
        if (raw is List) {
          return raw
              .where((e) => e != null && e is Map)
              .map((e) => WeeklyTimelineItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } else {
        debugPrint('[WeeklyReportService] getThesisTimeline status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[WeeklyReportService] Error fetching thesis timeline from database: $e');
    }

    return [];
  }

  /// 4. Giảng viên gửi đánh giá & chấm điểm tiến độ tuần thật vào CSDL
  /// POST /api/BaoCaoTienDo/feedback
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
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Đã gửi đánh giá và nhận xét thành công!'};
      } else {
        final dynamic errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final msg = errorBody is Map ? (errorBody['message'] ?? 'Lỗi từ máy chủ') : 'Lỗi từ máy chủ';
        return {'success': false, 'message': msg.toString()};
      }
    } catch (e) {
      debugPrint('[WeeklyReportService] Error submitting feedback to database: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến máy chủ: $e',
      };
    }
  }

  String _removeDiacritics(String str) {
    final regex = RegExp(r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữìíỉĩđỳýỵỷỹ]', caseSensitive: false);
    return str.replaceAllMapped(regex, (match) {
      final char = match.group(0)!;
      final lower = char.toLowerCase();
      if ('àáạảãâầấậẩẫăằắặẳẵ'.contains(lower)) return 'a';
      if ('èéẹẻẽêềếệểễ'.contains(lower)) return 'e';
      if ('òóọỏõôồốộổỗơờớợởỡ'.contains(lower)) return 'o';
      if ('ùúụủũưừứựửữ'.contains(lower)) return 'u';
      if ('ìíỉĩ'.contains(lower)) return 'i';
      if ('đ'.contains(lower)) return 'd';
      if ('ỳýỵỷỹ'.contains(lower)) return 'y';
      return char;
    });
  }
}
