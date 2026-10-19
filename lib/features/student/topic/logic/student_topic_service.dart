import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/model/user_model.dart';
import '../../group/logic/student_group_service.dart';
import '../../group/model/student_group_model.dart';
import '../model/thesis_topic_model.dart';

class StudentTopicService {
  static final StudentTopicService _instance = StudentTopicService._internal();
  factory StudentTopicService() => _instance;
  StudentTopicService._internal();

  String? _myRegisteredTopicId;

  // Lấy danh sách đề tài trực tiếp từ cơ sở dữ liệu qua Backend API theo đợt
  Future<List<ThesisTopicModel>> getTopics({
    String? query,
    String? lecturerFilter,
    String? directionFilter,
    String? statusFilter,
    UserModel? currentUser,
    int? periodId,
  }) async {
    List<ThesisTopicModel> topics = [];

    try {
      final token = await StorageService.getToken();
      final pId = periodId ?? await StudentGroupService().getCurrentPeriodId();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.theses}?periodId=$pId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final dynamic decoded = jsonDecode(utf8Body);
        if (decoded is List) {
          topics = decoded
              .map((item) => ThesisTopicModel.fromJson(item as Map<String, dynamic>))
              .where((t) {
                final st = t.status.trim().toLowerCase();
                // Bỏ qua các đề tài chưa duyệt (chờ duyệt hoặc bị từ chối)
                if (st.contains('pending') ||
                    st.contains('reject') ||
                    st.contains('chờ') ||
                    st.contains('từ chối')) {
                  return false;
                }
                // Chỉ lấy các đề tài đã được duyệt
                return st == 'approved' ||
                    st == 'open' ||
                    st == 'assigned' ||
                    st.contains('approved') ||
                    st == 'đã duyệt' ||
                    st == 'daduyet';
              })
              .toList();
        }
      }
    } catch (e) {
      debugPrint('StudentTopicService: Backend API /PhanCongDeTai/Theses error: $e');
    }

    // Nếu không có đề tài trong DB, trả về danh sách rỗng (không dùng mock)
    if (topics.isEmpty) {
      return [];
    }

    // Lấy thông tin nhóm của người dùng hiện tại để đánh dấu đề tài chính xác
    StudentGroupModel? myGroup;
    if (currentUser != null) {
      try {
        myGroup = await StudentGroupService().getMyGroup(currentUser);
      } catch (_) {}
    }

    // Cập nhật trạng thái đề tài của sinh viên
    topics = topics.map((t) {
      final isMine = (myGroup != null && t.registeredGroupId != null && t.registeredGroupId == myGroup.id) ||
          (_myRegisteredTopicId != null && t.id == _myRegisteredTopicId) ||
          (myGroup != null && myGroup.registeredThesisId != null && t.id == myGroup.registeredThesisId) ||
          (myGroup != null && myGroup.topicName != null && myGroup.topicName!.trim().isNotEmpty && t.title.trim().toLowerCase() == myGroup.topicName!.trim().toLowerCase());

      return t.copyWith(
        isMyTopic: isMine,
        registeredGroupId: isMine && myGroup != null ? myGroup.id : t.registeredGroupId,
        registeredGroupName: isMine && myGroup != null ? myGroup.name : t.registeredGroupName,
      );
    }).toList();

    // Lọc theo Giảng viên
    if (lecturerFilter != null && lecturerFilter.isNotEmpty && lecturerFilter != 'Tất cả' && lecturerFilter != 'Giảng viên') {
      topics = topics.where((t) {
        return t.lecturerName.toLowerCase().contains(lecturerFilter.toLowerCase());
      }).toList();
    }

    // Lọc theo Hướng đề tài
    if (directionFilter != null && directionFilter.isNotEmpty && directionFilter != 'Tất cả' && directionFilter != 'Hướng đề tài') {
      topics = topics.where((t) {
        return t.researchDirection.toLowerCase() == directionFilter.toLowerCase();
      }).toList();
    }

    // Lọc theo Trạng thái
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'Tất cả' && statusFilter != 'Trạng thái') {
      final s = statusFilter.toLowerCase();
      topics = topics.where((t) {
        final isMy = t.isRegisteredByMyGroup(myGroup?.id);
        final isTakenByOther = t.isRegisteredByOther(myGroup?.id);
        final isOpenForReg = t.isOpen && !isTakenByOther && !isMy && !t.isMyTopic;

        if (s.contains('mở')) {
          return isOpenForReg;
        } else if (s.contains('nhóm')) {
          return isTakenByOther || isMy || t.isMyTopic;
        } else if (s.contains('đóng')) {
          return !isOpenForReg;
        }
        return true;
      }).toList();
    }

    // Tìm kiếm theo tên hoặc mã đề tài
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      topics = topics.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.topicCode.toLowerCase().contains(q) ||
            t.lecturerName.toLowerCase().contains(q) ||
            t.researchDirection.toLowerCase().contains(q) ||
            t.periodName.toLowerCase().contains(q);
      }).toList();
    }

    return topics;
  }

  // Lấy danh sách giảng viên từ dữ liệu đề tài thực tế
  List<String> getLecturers({List<ThesisTopicModel>? fromTopics}) {
    if (fromTopics == null || fromTopics.isEmpty) {
      return ['Tất cả'];
    }
    final list = fromTopics
        .map((t) => t.lecturerName.trim())
        .where((l) => l.isNotEmpty && l != 'Chưa phân công')
        .toSet()
        .toList();
    list.sort();
    return ['Tất cả', ...list];
  }

  // Lấy danh sách hướng đề tài từ dữ liệu đề tài thực tế
  List<String> getDirections({List<ThesisTopicModel>? fromTopics}) {
    if (fromTopics == null || fromTopics.isEmpty) {
      return ['Tất cả'];
    }
    final list = fromTopics
        .map((t) => t.researchDirection.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    list.sort();
    return ['Tất cả', ...list];
  }

  // Lấy đề tài đã đăng ký của tôi
  Future<ThesisTopicModel?> getMyRegisteredTopic(UserModel user) async {
    final list = await getTopics(currentUser: user);
    for (final t in list) {
      if (t.isMyTopic || t.id == _myRegisteredTopicId) {
        return t;
      }
    }
    return null;
  }

  // Đăng ký đề tài (Bắt chặt logic: Chỉ Nhóm trưởng, Nhóm chưa có đề tài, Đề tài còn mở)
  Future<bool> registerTopic({
    required String topicId,
    required UserModel user,
    String? note,
  }) async {
    // 1. Kiểm tra sinh viên đã có nhóm chưa
    final groupService = StudentGroupService();
    final group = await groupService.getMyGroup(user);

    if (group == null) {
      throw Exception('Bạn chưa tham gia nhóm khóa luận nào. Vui lòng tạo nhóm hoặc gia nhập một nhóm trước khi đăng ký đề tài!');
    }

    // 2. Kiểm tra quyền Nhóm trưởng
    final isLeader = group.leaderCode == user.identifierCode ||
        group.leaderName.toLowerCase() == user.fullName.toLowerCase() ||
        group.members.any((m) =>
            (m.studentCode == user.identifierCode || m.id == user.userId.toString()) &&
            m.isLeader);

    if (!isLeader) {
      throw Exception('Chỉ Nhóm trưởng (${group.leaderName}) mới có quyền đăng ký đề tài cho nhóm!');
    }

    // 3. Kiểm tra nhóm đã đăng ký đề tài nào trước đó chưa
    if (group.topicName != null && group.topicName!.trim().isNotEmpty) {
      throw Exception('Nhóm của bạn đã đăng ký đề tài "${group.topicName}". Mỗi nhóm chỉ được đăng ký tối đa 1 đề tài!');
    }

    // 4. Kiểm tra nhóm đã đủ số lượng thành viên theo quy định của đợt chưa
    if (!group.isFull) {
      throw Exception(
        'Nhóm chưa đủ số lượng thành viên (${group.currentMembers}/${group.maxMembers} sinh viên). Vui lòng mời đủ thành viên trước khi đăng ký đề tài!',
      );
    }

    // 5. Gửi yêu cầu đăng ký lên Backend ASP.NET Core
    final gId = int.tryParse(group.id) ?? 0;
    final tId = int.tryParse(topicId) ?? 0;

    if (gId <= 0 || tId <= 0) {
      throw Exception('Thông tin nhóm hoặc đề tài không hợp lệ (Mã nhóm: $gId, Mã đề tài: $tId).');
    }

    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentGroupRegisterThesis(gId)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tId),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _myRegisteredTopicId = topicId;
        return true;
      } else {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final msg = decoded['message'] ?? 'Đăng ký đề tài không thành công (Mã ${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('StudentTopicService: registerTopic API call error: $e');
      if (e is Exception && !e.toString().contains('ClientException')) {
        rethrow;
      }
    }

    return false;
  }

  // Hủy đăng ký đề tài
  Future<bool> cancelTopicRegistration({
    required String topicId,
    required UserModel user,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Theses/$topicId/cancel');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'studentId': user.userId}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        if (_myRegisteredTopicId == topicId) {
          _myRegisteredTopicId = null;
        }
        return true;
      }
    } catch (e) {
      debugPrint('StudentTopicService: cancelTopicRegistration error: $e');
    }

    if (_myRegisteredTopicId == topicId) {
      _myRegisteredTopicId = null;
    }
    return false;
  }
}
