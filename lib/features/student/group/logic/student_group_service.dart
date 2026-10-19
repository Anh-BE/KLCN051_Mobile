import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/model/user_model.dart';
import '../../model/registration_period_model.dart';
import '../model/student_group_model.dart';

class StudentGroupService {
  static final StudentGroupService _instance = StudentGroupService._internal();
  factory StudentGroupService() => _instance;
  StudentGroupService._internal();

  int? _cachedPeriodId;
  List<RegistrationPeriodModel>? _cachedMyPeriods;
  StudentGroupModel? _cachedMyGroup;

  // Lấy Headers có Bearer Token
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void invalidateGroupCache() {
    _cachedMyGroup = null;
  }

  void invalidatePeriodCache() {
    _cachedPeriodId = null;
    _cachedMyPeriods = null;
    _cachedMyGroup = null;
  }

  // Lấy danh sách các đợt mà sinh viên hiện tại tham gia (GET /api/RegistrationPeriods/my-periods)
  Future<List<RegistrationPeriodModel>> getMyPeriods({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedMyPeriods != null && _cachedMyPeriods!.isNotEmpty) {
      return _cachedMyPeriods!;
    }

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.myRegistrationPeriods}');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is List) {
          final list = decoded.map((item) {
            return RegistrationPeriodModel.fromJson(item as Map<String, dynamic>);
          }).toList();
          _cachedMyPeriods = list;
          return list;
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: getMyPeriods error: $e');
    }

    return [];
  }

  // Chuyển đổi đợt làm việc
  Future<void> switchPeriod(RegistrationPeriodModel period) async {
    _cachedPeriodId = period.periodId;
    await StorageService.setSelectedPeriod(
      periodId: period.periodId,
      periodName: period.periodName,
    );
    invalidateGroupCache();
  }

  // 1. Lấy mã đợt đăng ký hiện tại (periodId)
  Future<int> getCurrentPeriodId() async {
    if (_cachedPeriodId != null) {
      return _cachedPeriodId!;
    }

    // 1.1. Kiểm tra ID đã lưu trong SharedPreferences
    final savedPeriodId = await StorageService.getSelectedPeriodId();
    if (savedPeriodId != null && savedPeriodId > 0) {
      _cachedPeriodId = savedPeriodId;
      return savedPeriodId;
    }

    try {
      // 1.2. Lấy danh sách đợt của sinh viên
      final periods = await getMyPeriods();
      if (periods.isNotEmpty) {
        if (periods.length == 1) {
          final onlyPeriod = periods.first;
          _cachedPeriodId = onlyPeriod.periodId;
          await StorageService.setSelectedPeriod(
            periodId: onlyPeriod.periodId,
            periodName: onlyPeriod.periodName,
          );
          return _cachedPeriodId!;
        } else {
          // Khi sinh viên có từ 2 đợt trở lên: tạm dùng đợt đầu tiên cho các lệnh gọi API ban đầu
          // NHƯNG tuyệt đối KHÔNG lưu vào Storage để StudentHomeView biết sinh viên chưa chọn và bắt buộc hiện Popup chọn đợt!
          return periods.first.periodId;
        }
      }

      final headers = await _getHeaders();
      // Thử gọi /api/RegistrationPeriods/my-period
      final myPeriodRes = await http
          .get(
            Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.myRegistrationPeriod}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (myPeriodRes.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(myPeriodRes.bodyBytes));
        final pId = decoded['periodId'] ?? decoded['id'];
        if (pId != null) {
          final parsed = pId is int ? pId : int.tryParse(pId.toString());
          if (parsed != null) {
            _cachedPeriodId = parsed;
            return _cachedPeriodId!;
          }
        }
      }

      // Thử lấy danh sách /api/RegistrationPeriods
      final periodsRes = await http
          .get(
            Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.registrationPeriods}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (periodsRes.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(periodsRes.bodyBytes));
        if (decoded is List && decoded.isNotEmpty) {
          final active = decoded.firstWhere(
            (p) {
              return p['status'] != 'Completed';
            },
            orElse: () {
              return decoded.first;
            },
          );
          final pId = active['periodId'] ?? active['id'];
          if (pId != null) {
            final parsed = pId is int ? pId : int.tryParse(pId.toString());
            if (parsed != null) {
              _cachedPeriodId = parsed;
              return _cachedPeriodId!;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: getCurrentPeriodId fallback to default: $e');
    }

    _cachedPeriodId = 1; // Mặc định đợt 1 theo CSDL hệ thống
    return _cachedPeriodId!;
  }

  // 2. Lấy thông tin nhóm của tôi (GET /api/ChucNangCuaSinhvien/MyGroup?periodId={id})
  Future<StudentGroupModel?> getMyGroup(UserModel user) async {
    try {
      final periodId = await getCurrentPeriodId();
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentMyGroup}?periodId=$periodId');

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final gId = (decoded['id'] ?? decoded['Id'] ?? decoded['groupId'] ?? decoded['GroupId'] ?? '').toString();
          if (gId.isNotEmpty && gId != '0' && gId != 'null') {
            final group = StudentGroupModel.fromJson(decoded);
            _cachedMyGroup = group;
            return group;
          }
        }
        _cachedMyGroup = null;
        return null;
      } else if (response.statusCode == 404) {
        _cachedMyGroup = null;
        return null;
      }
    } catch (e) {
      debugPrint('StudentGroupService: getMyGroup error: $e');
    }

    return null;
  }

  // 3. Tạo nhóm mới (POST /api/ChucNangCuaSinhvien/Create)
  Future<StudentGroupModel> createGroup({
    required String name,
    required String major,
    required String phone,
    required UserModel user,
  }) async {
    try {
      final periodId = await getCurrentPeriodId();
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentGroupCreate}');

      final body = jsonEncode({
        'periodId': periodId,
        'groupName': name.trim(),
      });

      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Tải lại dữ liệu nhóm mới từ Backend
        final freshGroup = await getMyGroup(user);
        if (freshGroup != null) return freshGroup;
        return StudentGroupModel(
          id: 'new',
          code: '',
          name: name.trim(),
          leaderName: user.fullName,
          leaderCode: user.identifierCode,
          leaderPhone: phone.trim(),
          leaderEmail: user.email,
          major: major,
                currentMembers: 1,
                maxMembers: 2,
                status: 'recruiting',
          members: [
            GroupMemberModel(
              id: 'm_${user.userId}',
              fullName: user.fullName,
              studentCode: user.identifierCode,
              role: 'leader',
              email: user.email,
              phone: phone,
              avatarUrl: user.avatarUrl,
            )
          ],
        );
      } else {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final msg = decoded['message'] ?? 'Lỗi tạo nhóm (Mã ${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('StudentGroupService: createGroup network error: $e');
      rethrow;
    }
  }

  // 4. Lấy danh sách yêu cầu xin vào nhóm (Chỉ lấy yêu cầu xin vào, không lấy lời mời từ leader)
  Future<List<GroupRequestModel>> getJoinRequests(String groupId) async {
    if (_cachedMyGroup != null && _cachedMyGroup!.id == groupId && _cachedMyGroup!.requests.isNotEmpty) {
      return _cachedMyGroup!.requests.where((r) => r.isPending && r.isJoinRequest).toList();
    }

    try {
      final user = await StorageService.getUser();
      if (user != null) {
        final group = await getMyGroup(user);
        if (group != null) {
          return group.requests.where((r) => r.isPending && r.isJoinRequest).toList();
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: getJoinRequests error: $e');
    }

    return [];
  }

  // 5. Duyệt yêu cầu vào nhóm (POST /api/ChucNangCuaSinhvien/{groupId}/Requests/{requestId}/Approve)
  Future<bool> approveJoinRequest(String groupId, GroupRequestModel request) async {
    final gId = int.tryParse(groupId) ?? 0;
    final rId = int.tryParse(request.id) ?? -1;
    if (gId > 0 && rId >= 0) {
      try {
        final headers = await _getHeaders();
        final url = Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.studentGroupApproveRequest(gId, rId)}',
        );

        final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          _cachedMyGroup = null;
          return true;
        } else {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final msg = decoded['message'] ?? 'Duyệt yêu cầu không thành công (Mã lỗi ${response.statusCode})';
          throw Exception(msg);
        }
      } catch (e) {
        debugPrint('StudentGroupService: approveJoinRequest API error: $e');
        if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      }
    }

    _cachedMyGroup = null;
    return false;
  }

  // 6. Từ chối yêu cầu vào nhóm (POST /api/ChucNangCuaSinhvien/{groupId}/Requests/{requestId}/Reject)
  Future<bool> rejectJoinRequest(String groupId, String requestId) async {
    final gId = int.tryParse(groupId) ?? 0;
    final rId = int.tryParse(requestId) ?? -1;
    if (gId > 0 && rId >= 0) {
      try {
        final headers = await _getHeaders();
        final url = Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.studentGroupRejectRequest(gId, rId)}',
        );

        final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          _cachedMyGroup = null;
          return true;
        } else {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final msg = decoded['message'] ?? 'Từ chối yêu cầu không thành công (Mã lỗi ${response.statusCode})';
          throw Exception(msg);
        }
      } catch (e) {
        debugPrint('StudentGroupService: rejectJoinRequest API error: $e');
        if (e is Exception && !e.toString().contains('ClientException')) rethrow;
      }
    }

    _cachedMyGroup = null;
    return false;
  }

  // 7. Gửi yêu cầu xin tham gia nhóm (POST /api/ChucNangCuaSinhvien/{groupId}/RequestJoin)
  Future<bool> requestJoinGroup(String groupId, {String? note, UserModel? user}) async {
    final currentUser = user ?? await StorageService.getUser();
    if (currentUser != null) {
      final myGroup = await getMyGroup(currentUser);
      if (myGroup != null) {
        if (myGroup.id == groupId) {
          throw Exception('Nhóm do bạn làm Nhóm trưởng/Thành viên tạo ra, không thể gửi yêu cầu xin vào nhóm của chính mình!');
        } else {
          throw Exception('Bạn đã tham gia nhóm "${myGroup.name}". Theo quy định, mỗi sinh viên chỉ được tham gia 1 nhóm khóa luận!');
        }
      }
    }

    try {
      final gId = int.tryParse(groupId) ?? 0;
      if (gId > 0) {
        final headers = await _getHeaders();
        final url = Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.studentGroupRequestJoin(gId)}',
        );

        final body = jsonEncode({'note': note ?? ''});
        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          return true;
        } else {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final msg = decoded['message'] ?? 'Lỗi gửi yêu cầu xin vào nhóm';
          throw Exception(msg);
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: requestJoinGroup error: $e');
      if (e is Exception && !e.toString().contains('ClientException')) {
        rethrow;
      }
    }

    return false;
  }

  // 8. Mời sinh viên vào nhóm (POST /api/ChucNangCuaSinhvien/{groupId}/Invite)
  Future<bool> inviteStudent({required String groupId, required String studentCodeOrId}) async {
    try {
      final gId = int.tryParse(groupId) ?? 0;
      int sId = int.tryParse(studentCodeOrId) ?? 0;
      if (sId == 0) {
        final code = getStudentCodeForName(studentCodeOrId);
        sId = int.tryParse(code) ?? 0;
      }

      if (gId > 0 && sId > 0) {
        final headers = await _getHeaders();
        final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentGroupInvite(gId)}');
        final body = jsonEncode({'studentId': sId});

        final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          return true;
        } else {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final msg = decoded['message'] ?? 'Không thể gửi lời mời';
          throw Exception(msg);
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: inviteStudent API error: $e');
      if (e is Exception && !e.toString().contains('ClientException')) {
        rethrow;
      }
    }

    return false;
  }

  // 9. Lấy danh sách lời mời gửi đến tôi (GET /api/ChucNangCuaSinhvien/MyInvitations?periodId={id})
  Future<List<StudentInvitationModel>> getMyInvitations() async {
    try {
      final periodId = await getCurrentPeriodId();
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentMyInvitations}?periodId=$periodId');

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded.map((item) => StudentInvitationModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: getMyInvitations API error: $e');
    }
    return [];
  }

  // 10. Chấp nhận lời mời (POST /api/ChucNangCuaSinhvien/Invitations/{requestId}/Accept)
  Future<bool> acceptInvitation(int requestId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentAcceptInvitation(requestId)}');

      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _cachedMyGroup = null; // Xóa cache để getMyGroup load nhóm mới lập tức
        return true;
      } else {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(decoded['message'] ?? 'Lỗi chấp nhận lời mời');
      }
    } catch (e) {
      debugPrint('StudentGroupService: acceptInvitation API error: $e');
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
    }
    return false;
  }

  // 11. Từ chối lời mời (POST /api/ChucNangCuaSinhvien/Invitations/{requestId}/Reject)
  Future<bool> rejectInvitation(int requestId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentRejectInvitation(requestId)}');

      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return true;
      } else {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(decoded['message'] ?? 'Lỗi từ chối lời mời (Mã ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('StudentGroupService: rejectInvitation API error: $e');
      if (e is Exception && !e.toString().contains('ClientException')) rethrow;
    }
    return false;
  }

  // 12. Tìm kiếm sinh viên chưa có nhóm (GET /api/ThongKeBaoCao/chi-tiet-sv-chua-nhom)
  Future<List<CandidateStudentModel>> searchCandidateStudents(String query) async {
    List<CandidateStudentModel> candidates = [];

    try {
      final periodId = await getCurrentPeriodId();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentsWithoutGroup}?periodId=$periodId');

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          candidates = decoded.map((item) => CandidateStudentModel.fromReportJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: searchCandidateStudents API fallback: $e');
    }

    if (query.trim().isEmpty) return candidates;

    final q = query.trim().toLowerCase();
    return candidates
        .where((s) =>
            s.fullName.toLowerCase().contains(q) ||
            s.studentCode.toLowerCase().contains(q) ||
            s.major.toLowerCase().contains(q))
        .toList();
  }

  // 13. Lấy danh sách nhóm khóa luận (GET /api/ChucNangCuaSinhvien/AllGroups & fallback)
  Future<List<StudentGroupModel>> getGroups({
    String? query,
    String? statusFilter, // 'all', 'recruiting', 'full'
    String? majorFilter,
  }) async {
    List<StudentGroupModel> realGroups = [];

    try {
      final periodId = await getCurrentPeriodId();
      final headers = await _getHeaders();

      // 1. Thử gọi API sinh viên chuẩn: /api/ChucNangCuaSinhvien/AllGroups?periodId={id}
      final allGroupsUrl = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentAllGroups}?periodId=$periodId');
      final allGroupsRes = await http.get(allGroupsUrl, headers: headers).timeout(const Duration(seconds: 5));

      if (allGroupsRes.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(allGroupsRes.bodyBytes));
        if (decoded is List && decoded.isNotEmpty) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              realGroups.add(StudentGroupModel.fromJson(item));
            }
          }
        }
      }

      // 2. Nếu AllGroups rỗng hoặc không phản hồi, fallback sang /api/ThongKeBaoCao/chi-tiet-nhom
      if (realGroups.isEmpty) {
        final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.reportGroupList}?periodId=$periodId');
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is List && decoded.isNotEmpty) {
            int idx = 1;
            for (final item in decoded) {
              final membersStr = (item['members'] ?? '').toString();
              final memberNames = membersStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final leaderName = memberNames.isNotEmpty ? memberNames.first : 'Nhóm trưởng';
              final leaderCode = getStudentCodeForName(leaderName);

              final membersList = memberNames.map((name) {
                final studentCode = getStudentCodeForName(name);
                return GroupMemberModel(
                  id: 'rm_$name',
                  fullName: name,
                  studentCode: studentCode,
                  role: name == leaderName ? 'leader' : 'member',
                  email: '$studentCode@student.huit.edu.vn',
                );
              }).toList();

              final rawMax = item['maxMembers'] ?? item['MaxMembers'] ?? 2;
              final int groupMax = rawMax is int
                  ? rawMax
                  : int.tryParse(rawMax.toString()) ?? 2;

              realGroups.add(StudentGroupModel(
                id: '$idx',
                code: 'N${idx.toString().padLeft(2, '0')}',
                name: item['groupName'] ?? 'Nhóm $idx',
                leaderName: leaderName,
                leaderCode: leaderCode,
                leaderPhone: '',
                leaderEmail: '$leaderCode@student.huit.edu.vn',
                major: 'Công nghệ thông tin',
                currentMembers: memberNames.length,
                maxMembers: groupMax,
                status: memberNames.length >= groupMax ? 'full' : 'recruiting',
                topicName: item['thesisName'],
                members: membersList,
              ));
              idx++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('StudentGroupService: getGroups API error, using fallback: $e');
    }

    var list = realGroups;

    if (statusFilter != null && statusFilter != 'all') {
      if (statusFilter == 'recruiting') {
        list = list.where((g) => g.isRecruiting).toList();
      } else if (statusFilter == 'full') {
        list = list.where((g) => g.isFull).toList();
      }
    }

    if (majorFilter != null && majorFilter.isNotEmpty && majorFilter != 'all') {
      list = list.where((g) => g.major.toLowerCase() == majorFilter.toLowerCase()).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((g) {
        return g.name.toLowerCase().contains(q) ||
            g.code.toLowerCase().contains(q) ||
            g.leaderName.toLowerCase().contains(q) ||
            g.leaderCode.toLowerCase().contains(q) ||
            g.major.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  // --- CÁC THAO TÁC BACKEND CHƯA CÓ ENDPOINT (Xử lý fallback local) ---

  Future<bool> cancelInvitation(String studentId) async {
    debugPrint('StudentGroupService: cancelInvitation - Backend endpoint not yet implemented.');
    return true;
  }

  Future<bool> cancelJoinRequest(String groupId) async {
    debugPrint('StudentGroupService: cancelJoinRequest - Backend endpoint not yet implemented.');
    return true;
  }

}
