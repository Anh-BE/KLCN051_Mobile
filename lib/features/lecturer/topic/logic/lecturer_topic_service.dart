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

  // Dữ liệu mẫu phong phú phục vụ kiểm thử mượt mà
  final List<LecturerThesisModel> _mockTheses = [
    LecturerThesisModel(
      thesisId: 26,
      thesisTitle: 'Nghiên cứu mô hình phân tích xu hướng cảm xúc của báo điện tử đối với thực thể bằng mô hình ngôn ngữ lớn',
      thesisType: 'Nghiên cứu',
      requirements: '- Nghiên cứu cơ sở lý thuyết về phân tích cảm xúc theo thực thể, nhận dạng thực thể (NER), Transformer, LLMs, RAG.\n- Thu thập bộ dữ liệu báo điện tử tiếng Việt, thực hiện tiền xử lý và gán nhãn.\n- Xây dựng mô hình phân tích xu hướng cảm xúc theo thực thể.',
      status: 'Approved',
      periodId: 1,
      periodName: 'Khóa luận 2026 - Đợt 1',
      periodCode: 'KLCN026',
      gvhd: 'ThS. Huỳnh Thị Cẩm Dung',
      registeredGroups: [
        RegisteredGroupItem(
          groupId: 101,
          groupName: 'Nhóm Nghiên cứu Mobile App HUIT',
          registrationStatus: 'Approved',
          registeredAt: '28/09/2026 14:30',
          memberCount: 3,
          members: [
            GroupStudentMember(
              studentId: 1,
              studentCode: '2001210123',
              fullName: 'Nguyễn Văn An',
              classCode: '12DHTH01',
              role: 'Trưởng nhóm',
              phoneNumber: '0987 654 321',
              email: 'an.nv@sinhvien.huit.edu.vn',
            ),
            GroupStudentMember(
              studentId: 2,
              studentCode: '2001210456',
              fullName: 'Trần Thị Bích',
              classCode: '12DHTH01',
              role: 'Thành viên',
              phoneNumber: '0912 345 678',
              email: 'bich.tt@sinhvien.huit.edu.vn',
            ),
            GroupStudentMember(
              studentId: 3,
              studentCode: '2001210789',
              fullName: 'Lê Hoàng Cường',
              classCode: '12DHTH02',
              role: 'Thành viên',
              phoneNumber: '0978 999 111',
              email: 'cuong.lh@sinhvien.huit.edu.vn',
            ),
          ],
        ),
      ],
      outlineObjectives: [
        OutlineObjectiveItem(
          objectiveId: 1,
          clocode: 'CLO1',
          outlineContent: 'Thu thập và gán nhãn tập dữ liệu báo điện tử tiếng Việt theo chuẩn NER',
          weightPercentage: 20.0,
          maxScore: 10.0,
          subObjectives: [
            OutlineObjectiveItem(
              objectiveId: 11,
              clocode: 'CLO1.1',
              outlineContent: 'Lập sơ đồ Use-Case nghiệp vụ, Use-Case hệ thống và sơ đồ lớp phân tích',
              weightPercentage: 10.0,
              maxScore: 1.0,
            ),
            OutlineObjectiveItem(
              objectiveId: 12,
              clocode: 'CLO1.2',
              outlineContent: 'Thu thập và tiền xử lý dữ liệu báo điện tử tiếng Việt theo chuẩn NER',
              weightPercentage: 10.0,
              maxScore: 1.0,
            ),
          ],
        ),
        OutlineObjectiveItem(
          objectiveId: 2,
          clocode: 'CLO2',
          outlineContent: 'Thiết kế hệ thống và Fine-tune mô hình ngôn ngữ lớn',
          weightPercentage: 15.0,
          maxScore: 10.0,
          subObjectives: [
            OutlineObjectiveItem(
              objectiveId: 21,
              clocode: 'CLO2.1',
              outlineContent: 'Thiết kế kiến trúc hệ thống, sơ đồ lớp thiết kế và mô hình dữ liệu CSDL',
              weightPercentage: 10.0,
              maxScore: 1.0,
            ),
            OutlineObjectiveItem(
              objectiveId: 22,
              clocode: 'CLO2.2',
              outlineContent: 'Thiết kế giao diện người dùng Website và Ứng dụng di động',
              weightPercentage: 5.0,
              maxScore: 0.5,
            ),
          ],
        ),
        OutlineObjectiveItem(
          objectiveId: 3,
          clocode: 'CLO3',
          outlineContent: 'Cài đặt và Lập trình chức năng mô hình AI',
          weightPercentage: 35.0,
          maxScore: 10.0,
          subObjectives: [
            OutlineObjectiveItem(
              objectiveId: 31,
              clocode: 'CLO3.1',
              outlineContent: 'Xây dựng các chức năng nền tảng: Đăng nhập, phân quyền, sao lưu & phục hồi dữ liệu',
              weightPercentage: 10.0,
              maxScore: 1.0,
            ),
            OutlineObjectiveItem(
              objectiveId: 32,
              clocode: 'CLO3.2',
              outlineContent: 'Huấn luyện mô hình Transformer & Fine-tune LLM theo bài toán Sentiment',
              weightPercentage: 25.0,
              maxScore: 2.5,
            ),
          ],
        ),
      ],
    ),
    LecturerThesisModel(
      thesisId: 1,
      thesisTitle: 'Hỗ trợ quản lý hồ sơ khoa học công nghệ bằng phương pháp phân loại tự động',
      thesisType: 'Tích hợp',
      requirements: 'Python, FastAPI, PyTorch, LangChain, PostgreSQL (pgvector), Flutter App.',
      status: 'Approved',
      periodId: 1,
      periodName: 'Khóa luận 2026 - Đợt 1',
      periodCode: 'KLCN001',
      gvhd: 'ThS. Huỳnh Thị Cẩm Dung',
      registeredGroups: [
        RegisteredGroupItem(
          groupId: 102,
          groupName: 'Nhóm Phát triển Hệ thống Web Cloud',
          registrationStatus: 'Approved',
          registeredAt: '29/09/2026 09:15',
          memberCount: 2,
          members: [
            GroupStudentMember(
              studentId: 4,
              studentCode: '2001210789',
              fullName: 'Lê Hoàng Nam',
              classCode: '12DHTH03',
              role: 'Trưởng nhóm',
              phoneNumber: '0903 123 456',
              email: 'nam.lh@sinhvien.huit.edu.vn',
            ),
            GroupStudentMember(
              studentId: 5,
              studentCode: '2001210999',
              fullName: 'Võ Minh Quân',
              classCode: '12DHTH03',
              role: 'Thành viên',
              phoneNumber: '0934 567 890',
              email: 'quan.vm@sinhvien.huit.edu.vn',
            ),
          ],
        ),
      ],
      outlineObjectives: [
        OutlineObjectiveItem(
          objectiveId: 4,
          clocode: 'CLO1',
          outlineContent: 'Phân tích thiết kế cơ sở dữ liệu và kiến trúc Microservices',
          weightPercentage: 40.0,
          maxScore: 10.0,
        ),
        OutlineObjectiveItem(
          objectiveId: 5,
          clocode: 'CLO2',
          outlineContent: 'Huấn luyện module trích xuất tự động văn bản khoa học',
          weightPercentage: 60.0,
          maxScore: 10.0,
        ),
      ],
    ),
    LecturerThesisModel(
      thesisId: 2,
      thesisTitle: 'Ứng dụng IoT và AI trong giám sát năng lượng thông minh cho khuôn viên trường HUIT',
      thesisType: 'Ứng dụng',
      requirements: 'Cảm biến IoT ESP32, MQTT Broker, Dashboard Grafana/Flutter, Dự báo bằng Time Series (LSTM).',
      status: 'Pending',
      periodId: 1,
      periodName: 'Khóa luận 2026 - Đợt 1',
      periodCode: 'KLCN002',
      gvhd: 'ThS. Huỳnh Thị Cẩm Dung',
      registeredGroups: [],
      outlineObjectives: [],
    ),
    LecturerThesisModel(
      thesisId: 3,
      thesisTitle: 'Xây dựng sàn thương mại điện tử phi tập trung ứng dụng Smart Contract trên blockchain Polygon',
      thesisType: 'Nghiên cứu',
      requirements: 'Solidity, Web3.js, React/Vue, Hardhat, IPFS.',
      status: 'Rejected',
      periodId: 1,
      periodName: 'Khóa luận 2026 - Đợt 1',
      periodCode: 'KLCN003',
      gvhd: 'ThS. Huỳnh Thị Cẩm Dung',
      registeredGroups: [],
      outlineObjectives: [],
    ),
  ];

  // Lấy danh sách đợt khóa luận
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
      ).timeout(const Duration(seconds: 4));

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
                  list.add({
                    'periodId': pId is int ? pId : int.tryParse(pId.toString()),
                    'periodName': pName.toString(),
                  });
                }
              }
            }
          }
          if (list.isNotEmpty) {
            return list;
          }
        }
      }
    } catch (e) {
      debugPrint('[LecturerTopicService] Error fetching periods: $e');
    }

    return [
      {'periodId': 1, 'periodName': 'Khóa luận tốt nghiệp Đợt 1 (2026 - 2027)'},
      {'periodId': 2, 'periodName': 'Khóa luận tốt nghiệp Đợt 2 (2025 - 2026)'},
      {'periodId': 3, 'periodName': 'TESTKL1'},
    ];
  }

  // Lấy danh sách đề tài của Giảng viên
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
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
        if (raw is List) {
          result = raw
              .where((item) => item != null && item is Map)
              .map((item) => LecturerThesisModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[LecturerTopicService] Failed to load from API: $e. Using local data.');
    }

    // Nếu API rỗng hoặc gọi thất bại và chưa chọn đợt lọc cụ thể, sử dụng mock data để luôn hiển thị giao diện mẫu
    if (result.isEmpty && periodId == null) {
      result = List.from(_mockTheses);
    }

    // Lọc theo periodId nếu có dữ liệu từ mock data hoặc API
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

    // Lọc theo Search Query (tìm tên đề tài, mã đề tài, tên nhóm hoặc tên SV)
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

  String _removeDiacritics(String str) {
    final regex = RegExp(r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữìíịỉĩđỳýỵỷỹ]', caseSensitive: false);
    return str.replaceAllMapped(regex, (match) {
      final char = match.group(0)!;
      final lower = char.toLowerCase();
      if ('àáạảãâầấậẩẫăằắặẳẵ'.contains(lower)) return 'a';
      if ('èéẹẻẽêềếệểễ'.contains(lower)) return 'e';
      if ('òóọỏõôồốộổỗơờớợởỡ'.contains(lower)) return 'o';
      if ('ùúụủũưừứựửữ'.contains(lower)) return 'u';
      if ('ìíịỉĩ'.contains(lower)) return 'i';
      if ('đ'.contains(lower)) return 'd';
      if ('ỳýỵỷỹ'.contains(lower)) return 'y';
      return char;
    });
  }
}
