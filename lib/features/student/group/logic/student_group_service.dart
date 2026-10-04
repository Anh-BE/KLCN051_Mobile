import '../../../auth/model/user_model.dart';
import '../model/student_group_model.dart';

class StudentGroupService {
  static final StudentGroupService _instance = StudentGroupService._internal();
  factory StudentGroupService() => _instance;
  StudentGroupService._internal();

  // Danh sách Mock Data nhóm Khóa luận chuẩn thực tế Khoa CNTT - HUIT
  final List<StudentGroupModel> _mockGroups = [
    StudentGroupModel(
      id: '1',
      code: 'N01',
      name: 'Nhóm Nghiên cứu Mobile App HUIT',
      leaderName: 'Nguyễn Văn An',
      leaderCode: '2001210123',
      leaderPhone: '0987 654 321',
      leaderEmail: '2001210123@huit.edu.vn',
      major: 'Công nghệ phần mềm',
      currentMembers: 2,
      maxMembers: 3,
      status: 'recruiting',
      hasRequested: false,
      members: [
        GroupMemberModel(
          id: 'm1',
          fullName: 'Nguyễn Văn An',
          studentCode: '2001210123',
          role: 'leader',
          email: '2001210123@huit.edu.vn',
          phone: '0987 654 321',
        ),
        GroupMemberModel(
          id: 'm2',
          fullName: 'Trần Thị Mai',
          studentCode: '2001210456',
          role: 'member',
          email: '2001210456@huit.edu.vn',
          phone: '0912 345 678',
        ),
      ],
    ),
    StudentGroupModel(
      id: '2',
      code: 'N02',
      name: 'Nhóm Phát triển Hệ thống Web Cloud',
      leaderName: 'Lê Hoàng Nam',
      leaderCode: '2001210789',
      leaderPhone: '0903 123 456',
      leaderEmail: '2001210789@huit.edu.vn',
      major: 'Hệ thống thông tin',
      currentMembers: 3,
      maxMembers: 3,
      status: 'full',
      hasRequested: false,
      members: [
        GroupMemberModel(
          id: 'm3',
          fullName: 'Lê Hoàng Nam',
          studentCode: '2001210789',
          role: 'leader',
          email: '2001210789@huit.edu.vn',
          phone: '0903 123 456',
        ),
        GroupMemberModel(
          id: 'm4',
          fullName: 'Phạm Minh Tuấn',
          studentCode: '2001210999',
          role: 'member',
          email: '2001210999@huit.edu.vn',
        ),
        GroupMemberModel(
          id: 'm5',
          fullName: 'Võ Quốc Bảo',
          studentCode: '2001210888',
          role: 'member',
          email: '2001210888@huit.edu.vn',
        ),
      ],
    ),
    StudentGroupModel(
      id: '3',
      code: 'N03',
      name: 'Nhóm IoT & Thiết bị thông minh',
      leaderName: 'Đặng Quốc Huy',
      leaderCode: '2001210333',
      leaderPhone: '0978 999 888',
      leaderEmail: '2001210333@huit.edu.vn',
      major: 'Mạng máy tính & TT',
      currentMembers: 1,
      maxMembers: 3,
      status: 'recruiting',
      hasRequested: false,
      members: [
        GroupMemberModel(
          id: 'm6',
          fullName: 'Đặng Quốc Huy',
          studentCode: '2001210333',
          role: 'leader',
          email: '2001210333@huit.edu.vn',
          phone: '0978 999 888',
        ),
      ],
    ),
    StudentGroupModel(
      id: '4',
      code: 'N04',
      name: 'Nhóm An toàn thông tin & Web Security',
      leaderName: 'Hoàng Văn Khánh',
      leaderCode: '2001210555',
      leaderPhone: '0933 777 666',
      leaderEmail: '2001210555@huit.edu.vn',
      major: 'An toàn thông tin',
      currentMembers: 2,
      maxMembers: 3,
      status: 'recruiting',
      hasRequested: false,
      members: [
        GroupMemberModel(
          id: 'm7',
          fullName: 'Hoàng Văn Khánh',
          studentCode: '2001210555',
          role: 'leader',
          email: '2001210555@huit.edu.vn',
          phone: '0933 777 666',
        ),
        GroupMemberModel(
          id: 'm8',
          fullName: 'Đỗ Thùy Linh',
          studentCode: '2001210666',
          role: 'member',
          email: '2001210666@huit.edu.vn',
        ),
      ],
    ),
    StudentGroupModel(
      id: '5',
      code: 'N05',
      name: 'Nhóm Trí tuệ nhân tạo & Data Science',
      leaderName: 'Bùi Đức Trọng',
      leaderCode: '2001210222',
      leaderPhone: '0918 555 444',
      leaderEmail: '2001210222@huit.edu.vn',
      major: 'Khoa học dữ liệu',
      currentMembers: 3,
      maxMembers: 3,
      status: 'full',
      hasRequested: false,
      members: [
        GroupMemberModel(
          id: 'm9',
          fullName: 'Bùi Đức Trọng',
          studentCode: '2001210222',
          role: 'leader',
          email: '2001210222@huit.edu.vn',
          phone: '0918 555 444',
        ),
        GroupMemberModel(
          id: 'm10',
          fullName: 'Ngô Thanh Tùng',
          studentCode: '2001210111',
          role: 'member',
          email: '2001210111@huit.edu.vn',
        ),
        GroupMemberModel(
          id: 'm11',
          fullName: 'Vũ Ngọc Hân',
          studentCode: '2001210777',
          role: 'member',
          email: '2001210777@huit.edu.vn',
        ),
      ],
    ),
  ];

  // Danh sách Mock yêu cầu xin vào nhóm
  final Map<String, List<GroupRequestModel>> _joinRequests = {
    '1': [
      const GroupRequestModel(
        id: 'req_1',
        studentId: 'st_101',
        studentName: 'Lê Quốc Việt',
        studentCode: '2001210345',
        studentPhone: '0945 112 233',
        major: 'Công nghệ phần mềm',
        note: 'Em có kinh nghiệm làm Flutter UI và State Management Riverpod, mong muốn được tham gia cùng nhóm anh/chị ạ!',
        createdAt: '10 phút trước',
        status: 'pending',
      ),
      const GroupRequestModel(
        id: 'req_2',
        studentId: 'st_102',
        studentName: 'Nguyễn Thị Hồng Hạnh',
        studentCode: '2001210765',
        studentPhone: '0919 887 766',
        major: 'Công nghệ phần mềm',
        note: 'Chào nhóm, em chuyên làm API ASP.NET Core và SQL Server, rất hy vọng được hợp tác làm khóa luận cùng nhóm.',
        createdAt: '1 giờ trước',
        status: 'pending',
      ),
    ],
  };

  // Danh sách Mock sinh viên chưa có nhóm để mời
  final List<CandidateStudentModel> _candidateStudents = [
    const CandidateStudentModel(
      id: 'c1',
      fullName: 'Phạm Đức Duy',
      studentCode: '2001210199',
      major: 'Công nghệ phần mềm',
      phone: '0977 123 456',
      hasInvited: false,
    ),
    const CandidateStudentModel(
      id: 'c2',
      fullName: 'Nguyễn Minh Quân',
      studentCode: '2001210288',
      major: 'Công nghệ phần mềm',
      phone: '0988 234 567',
      hasInvited: false,
    ),
    const CandidateStudentModel(
      id: 'c3',
      fullName: 'Võ Thị Thanh Thảo',
      studentCode: '2001210377',
      major: 'Hệ thống thông tin',
      phone: '0909 345 678',
      hasInvited: false,
    ),
    const CandidateStudentModel(
      id: 'c4',
      fullName: 'Trương Hoàng Phúc',
      studentCode: '2001210466',
      major: 'Mạng máy tính & TT',
      phone: '0933 456 789',
      hasInvited: false,
    ),
    const CandidateStudentModel(
      id: 'c5',
      fullName: 'Đoàn Bảo Long',
      studentCode: '2001210555',
      major: 'An toàn thông tin',
      phone: '0911 567 890',
      hasInvited: false,
    ),
  ];

  Future<List<StudentGroupModel>> getGroups({
    String? query,
    String? statusFilter, // 'all', 'recruiting', 'full'
    String? majorFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var list = List<StudentGroupModel>.from(_mockGroups);

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

  // Tìm nhóm của sinh viên hiện tại
  Future<StudentGroupModel?> getMyGroup(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final group in _mockGroups) {
      final isLeader = group.leaderCode == user.identifierCode || group.leaderName.toLowerCase() == user.fullName.toLowerCase();
      final isMember = group.members.any((m) => m.studentCode == user.identifierCode || m.fullName.toLowerCase() == user.fullName.toLowerCase());
      if (isLeader || isMember) {
        return group;
      }
    }
    return null;
  }

  // Tạo nhóm mới
  Future<StudentGroupModel> createGroup({
    required String name,
    required String major,
    required String phone,
    required UserModel user,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newId = '${_mockGroups.length + 1}';
    final newCode = 'N0${_mockGroups.length + 1}';

    final leaderMember = GroupMemberModel(
      id: 'm_${user.userId}',
      fullName: user.fullName,
      studentCode: user.identifierCode,
      role: 'leader',
      email: user.email,
      phone: phone,
      avatarUrl: user.avatarUrl,
    );

    final newGroup = StudentGroupModel(
      id: newId,
      code: newCode,
      name: name.trim(),
      leaderName: user.fullName,
      leaderCode: user.identifierCode,
      leaderPhone: phone.trim(),
      leaderEmail: user.email.isNotEmpty ? user.email : '${user.identifierCode}@huit.edu.vn',
      major: major,
      currentMembers: 1,
      maxMembers: 3,
      status: 'recruiting',
      members: [leaderMember],
    );

    _mockGroups.insert(0, newGroup);
    return newGroup;
  }

  // Lấy danh sách yêu cầu xin vào nhóm
  Future<List<GroupRequestModel>> getJoinRequests(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final requests = _joinRequests[groupId] ?? [];
    return requests.where((r) => r.isPending).toList();
  }

  // Duyệt yêu cầu vào nhóm
  Future<bool> approveJoinRequest(String groupId, GroupRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final groupIndex = _mockGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final currentGroup = _mockGroups[groupIndex];
      if (currentGroup.currentMembers < currentGroup.maxMembers) {
        final newMember = GroupMemberModel(
          id: 'm_${request.studentId}',
          fullName: request.studentName,
          studentCode: request.studentCode,
          role: 'member',
          phone: request.studentPhone,
          email: '${request.studentCode}@huit.edu.vn',
        );

        final updatedMembers = [...currentGroup.members, newMember];
        final newCount = updatedMembers.length;
        _mockGroups[groupIndex] = currentGroup.copyWith(
          members: updatedMembers,
          currentMembers: newCount,
          status: newCount >= currentGroup.maxMembers ? 'full' : 'recruiting',
        );

        // Đánh dấu request đã duyệt
        final reqList = _joinRequests[groupId];
        if (reqList != null) {
          reqList.removeWhere((r) => r.id == request.id);
        }
        return true;
      }
    }
    return false;
  }

  // Từ chối yêu cầu vào nhóm
  Future<bool> rejectJoinRequest(String groupId, String requestId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final reqList = _joinRequests[groupId];
    if (reqList != null) {
      reqList.removeWhere((r) => r.id == requestId);
      return true;
    }
    return false;
  }

  // Xóa thành viên khỏi nhóm
  Future<bool> removeMember(String groupId, String memberId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final groupIndex = _mockGroups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final currentGroup = _mockGroups[groupIndex];
      final updatedMembers = currentGroup.members.where((m) => m.id != memberId).toList();
      _mockGroups[groupIndex] = currentGroup.copyWith(
        members: updatedMembers,
        currentMembers: updatedMembers.length,
        status: updatedMembers.length < currentGroup.maxMembers ? 'recruiting' : 'full',
      );
      return true;
    }
    return false;
  }

  // Tìm kiếm ứng viên sinh viên để mời
  Future<List<CandidateStudentModel>> searchCandidateStudents(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.trim().isEmpty) {
      return List<CandidateStudentModel>.from(_candidateStudents);
    }
    final q = query.trim().toLowerCase();
    return _candidateStudents
        .where((s) => s.fullName.toLowerCase().contains(q) || s.studentCode.toLowerCase().contains(q) || s.major.toLowerCase().contains(q))
        .toList();
  }

  // Mời sinh viên vào nhóm
  Future<bool> inviteStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _candidateStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      _candidateStudents[index] = _candidateStudents[index].copyWith(hasInvited: true);
      return true;
    }
    return false;
  }

  // Hủy lời mời
  Future<bool> cancelInvitation(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _candidateStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      _candidateStudents[index] = _candidateStudents[index].copyWith(hasInvited: false);
      return true;
    }
    return false;
  }

  Future<bool> requestJoinGroup(String groupId, {String? note}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _mockGroups[index] = _mockGroups[index].copyWith(hasRequested: true);
      return true;
    }
    return false;
  }

  Future<bool> cancelJoinRequest(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _mockGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _mockGroups[index] = _mockGroups[index].copyWith(hasRequested: false);
      return true;
    }
    return false;
  }
}
