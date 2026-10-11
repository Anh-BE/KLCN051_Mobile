import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../model/lecturer_thesis_model.dart';

class LecturerTopicService {
  static final LecturerTopicService _instance = LecturerTopicService._internal();
  factory LecturerTopicService() => _instance;
  LecturerTopicService._internal();

  /// 1. Lấy danh sách đợt khóa luận thật từ CSDL backend (GET /api/RegistrationPeriods)
  /// Đợt mới nhất luôn được sắp xếp ở đầu danh sách (index 0).
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

          // Sắp xếp đợt mới nhất lên đầu danh sách (PeriodId giảm dần)
          list.sort((a, b) => (b['periodId'] as int).compareTo(a['periodId'] as int));
          return list;
        }
      } else {
        debugPrint('[LecturerTopicService] getPeriods returned status: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[LecturerTopicService] Error fetching periods from database: $e');
    }

    return [];
  }

  /// 2. Lấy danh sách đề tài của Giảng viên thật từ CSDL (GET /api/RaDeTai/history)
  Future<List<LecturerThesisModel>> getTheses({
    int? periodId,
    String? statusFilter, // 'all', 'Approved', 'Pending', 'Rejected'
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
          result = raw
              .where((item) => item != null && item is Map)
              .map((item) => LecturerThesisModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      } else {
        debugPrint('[LecturerTopicService] getTheses returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[LecturerTopicService] Error fetching theses from database: $e');
    }

    // Lọc theo periodId nếu người dùng chọn và backend trả về danh sách rộng
    if (periodId != null && result.isNotEmpty) {
      result = result.where((t) => t.periodId == periodId).toList();
    }

    // Lọc theo Status (Tất cả, Đã duyệt, Chờ duyệt, Từ chối)
    if (statusFilter != null && statusFilter != 'all') {
      result = result.where((t) {
        final st = t.status.toLowerCase();
        if (statusFilter == 'Approved') {
          return st == 'approved' || st == 'daduyet';
        }
        if (statusFilter == 'Pending') {
          return st.contains('pending') || st.contains('wait') || st.contains('choduyet');
        }
        if (statusFilter == 'Rejected') {
          return st.contains('reject') || st.contains('revision') || st.contains('tuchoi');
        }
        return st == statusFilter.toLowerCase();
      }).toList();
    }

    // Lọc theo Search Query (tìm tên đề tài, mã đề tài, tên nhóm hoặc tên sinh viên)
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = _removeDiacritics(searchQuery.trim().toLowerCase());
      result = result.where((t) {
        final titleMatch = _removeDiacritics(t.thesisTitle.toLowerCase()).contains(q);
        final codeMatch = t.periodCode.toLowerCase().contains(q) || 'dt${t.thesisId}'.contains(q);
        final typeMatch = _removeDiacritics(t.thesisType.toLowerCase()).contains(q);

        final groupMatch = t.registeredGroups.any((g) {
          final groupNameMatch = _removeDiacritics(g.groupName.toLowerCase()).contains(q);
          final studentMatch = g.members.any((m) =>
              _removeDiacritics(m.fullName.toLowerCase()).contains(q) ||
              m.studentCode.toLowerCase().contains(q));
          return groupNameMatch || studentMatch;
        });

        return titleMatch || codeMatch || typeMatch || groupMatch;
      }).toList();
    }

    return result;
  }

  /// 3. Lấy nội dung kế hoạch các tuần của đề tài từ CSDL thật (GET /api/RaDeTai/{thesisId}/weekly-plans)
  Future<List<Map<String, dynamic>>> getThesisWeeklyPlans(int thesisId) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/RaDeTai/$thesisId/weekly-plans');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(res.bodyBytes));
        if (raw is List) {
          final list = raw
              .where((e) => e != null && e is Map)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          list.sort((a, b) {
            final wA = (a['weekNumber'] ?? a['WeekNumber'] ?? 0) as int;
            final wB = (b['weekNumber'] ?? b['WeekNumber'] ?? 0) as int;
            return wA.compareTo(wB);
          });
          return list;
        }
      }
    } catch (e) {
      debugPrint('[LecturerTopicService] Error fetching weekly plans: $e');
    }
    return [];
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
