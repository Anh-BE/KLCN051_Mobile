import '../../../auth/model/user_model.dart';

const Map<String, String> _knownStudentCodes = {
  'nguyễn gia huy': '2001230017',
  'lê ngọc anh': '2001230313',
  'trần minh quân': '2001230105',
  'phạm hoàng nam': '2001230112',
  'võ thị quỳnh như': '2001230204',
  'đỗ gia bảo': '2001230218',
  'bùi đức trọng': '2001230401',
  'trịnh quốc huy': '2001230415',
  'ngô phương linh': '2001230502',
  'hoàng hải đăng': '2001230520',
  'đặng thanh phong': '2001230603',
  'lương thảo my': '2001230619',
};

String getStudentCodeForName(String fullName) {
  final clean = fullName.trim().toLowerCase();
  if (_knownStudentCodes.containsKey(clean)) {
    return _knownStudentCodes[clean]!;
  }
  // Check if string contains "(MSSV)"
  final match = RegExp(r'\((.*?)\)').firstMatch(fullName);
  if (match != null && match.group(1)!.isNotEmpty) {
    return match.group(1)!.trim();
  }
  return '';
}

class GroupMemberModel {
  final String id;
  final String fullName;
  final String studentCode;
  final String role; // 'leader' or 'member'
  final String? email;
  final String? phone;
  final String? avatarUrl;

  const GroupMemberModel({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.role,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  bool get isLeader => role.toLowerCase() == 'leader' || role.toLowerCase().contains('trưởng');

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] ?? 'member').toString();
    final isLead = rawRole.toLowerCase() == 'leader' || rawRole.toLowerCase().contains('trưởng');
    final name = (json['fullName'] ?? json['name'] ?? '').toString();
    var sCode = (json['studentCode'] ?? json['StudentCode'] ?? json['identifierCode'] ?? json['IdentifierCode'] ?? json['mssv'] ?? json['MSSV'] ?? json['code'] ?? '').toString();
    if (sCode.isEmpty || sCode == '0' || sCode == 'null') {
      sCode = getStudentCodeForName(name);
    }

    return GroupMemberModel(
      id: json['id']?.toString() ?? json['studentId']?.toString() ?? sCode,
      fullName: name,
      studentCode: sCode,
      role: isLead ? 'leader' : 'member',
      email: json['email'] ?? json['Email'],
      phone: json['phone'] ?? json['phoneNumber'] ?? json['PhoneNumber'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'studentCode': studentCode,
    'role': role,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
  };
}

class GroupRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String studentPhone;
  final String major;
  final String? note;
  final String requestType; // 'StudentJoinRequest' or 'LeaderInvite'
  final String createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  const GroupRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.studentPhone,
    required this.major,
    this.note,
    this.requestType = 'StudentJoinRequest',
    required this.createdAt,
    this.status = 'pending',
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isJoinRequest =>
      requestType.toLowerCase().contains('join') ||
      requestType == 'StudentJoinRequest' ||
      requestType.isEmpty;
  bool get isInvite =>
      requestType.toLowerCase().contains('invite') ||
      requestType == 'LeaderInvite';

  factory GroupRequestModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? json['Status'] ?? 'pending').toString().toLowerCase();
    final reqId = (json['requestId'] ?? json['RequestId'] ?? json['id'] ?? json['Id'])?.toString() ?? '';
    final stdId = (json['studentId'] ?? json['StudentId'] ?? json['id'] ?? json['Id'])?.toString() ?? '';
    final sName = (json['fullName'] ?? json['FullName'] ?? json['studentName'] ?? json['StudentName'] ?? '').toString();
    final sCode = (json['studentCode'] ?? json['StudentCode'] ?? stdId).toString();
    final sPhone = (json['studentPhone'] ?? json['StudentPhone'] ?? json['phoneNumber'] ?? json['PhoneNumber'] ?? json['phone'] ?? json['Phone'] ?? '').toString();
    final sMajor = (json['major'] ?? json['Major'] ?? 'Công nghệ thông tin').toString();
    final rType = (json['requestType'] ?? json['RequestType'] ?? 'StudentJoinRequest').toString();

    final rawNote = json['note'] ?? json['Note'];
    String? cleanNote;
    if (rawNote != null && rawNote.toString().isNotEmpty) {
      final s = rawNote.toString();
      if (s != 'StudentJoinRequest' && s != 'LeaderInvite') {
        cleanNote = s;
      }
    }

    final rawCreated = (json['createdAt'] ?? json['CreatedAt'] ?? 'Hôm nay').toString();

    return GroupRequestModel(
      id: reqId,
      studentId: stdId,
      studentName: sName,
      studentCode: sCode,
      studentPhone: sPhone,
      major: sMajor,
      note: cleanNote,
      requestType: rType,
      createdAt: rawCreated,
      status: rawStatus == 'accepted' || rawStatus == 'approved'
          ? 'approved'
          : rawStatus == 'rejected'
              ? 'rejected'
              : 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'studentCode': studentCode,
    'studentPhone': studentPhone,
    'major': major,
    'note': note,
    'requestType': requestType,
    'createdAt': createdAt,
    'status': status,
  };
}

class StudentInvitationModel {
  final int requestId;
  final int groupId;
  final String groupName;
  final String createdAt;

  const StudentInvitationModel({
    required this.requestId,
    required this.groupId,
    required this.groupName,
    required this.createdAt,
  });

  factory StudentInvitationModel.fromJson(Map<String, dynamic> json) {
    return StudentInvitationModel(
      requestId: json['requestId'] is int
          ? json['requestId']
          : int.tryParse(json['requestId']?.toString() ?? '0') ?? 0,
      groupId: json['groupId'] is int
          ? json['groupId']
          : int.tryParse(json['groupId']?.toString() ?? '0') ?? 0,
      groupName: json['groupName'] ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class CandidateStudentModel {
  final String id;
  final String fullName;
  final String studentCode;
  final String major;
  final String phone;
  final bool hasInvited;

  const CandidateStudentModel({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.major,
    required this.phone,
    this.hasInvited = false,
  });

  factory CandidateStudentModel.fromReportJson(Map<String, dynamic> json) {
    final mssv = (json['mssv'] ?? json['MSSV'] ?? '').toString();
    return CandidateStudentModel(
      id: mssv,
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      studentCode: mssv,
      major: (json['className'] ?? json['ClassName'] ?? 'Công nghệ thông tin').toString(),
      phone: (json['email'] ?? json['Email'] ?? '').toString(),
      hasInvited: false,
    );
  }

  CandidateStudentModel copyWith({
    String? id,
    String? fullName,
    String? studentCode,
    String? major,
    String? phone,
    bool? hasInvited,
  }) {
    return CandidateStudentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      studentCode: studentCode ?? this.studentCode,
      major: major ?? this.major,
      phone: phone ?? this.phone,
      hasInvited: hasInvited ?? this.hasInvited,
    );
  }
}

class StudentGroupModel {
  final String id;
  final String code;
  final String name;
  final String leaderName;
  final String leaderCode;
  final String leaderPhone;
  final String leaderEmail;
  final String major;
  final int currentMembers;
  final int maxMembers;
  final String status; // 'recruiting', 'Forming', 'Approved', 'full'
  final String? topicName;
  final String? description;
  final bool hasRequested;
  final List<GroupMemberModel> members;
  final List<GroupRequestModel> requests;

  const StudentGroupModel({
    required this.id,
    required this.code,
    required this.name,
    required this.leaderName,
    required this.leaderCode,
    required this.leaderPhone,
    required this.leaderEmail,
    required this.major,
    required this.currentMembers,
    this.maxMembers = 3,
    required this.status,
    this.topicName,
    this.description,
    this.hasRequested = false,
    this.members = const [],
    this.requests = const [],
  });

  bool get isRecruiting =>
      (status.toLowerCase() == 'recruiting' ||
          status.toLowerCase() == 'forming' ||
          status.toLowerCase() == 'pending') &&
      currentMembers < maxMembers;

  bool get isFull => currentMembers >= maxMembers || status.toLowerCase() == 'full';

  bool isUserLeader(UserModel user) {
    if (leaderCode.isNotEmpty && leaderCode == user.identifierCode) return true;
    if (leaderName.isNotEmpty &&
        leaderName.toLowerCase() == user.fullName.toLowerCase()) {
      return true;
    }
    return members.any((m) =>
        (m.studentCode == user.identifierCode ||
            m.id == user.userId.toString() ||
            m.fullName.toLowerCase() == user.fullName.toLowerCase()) &&
        m.isLeader);
  }

  bool isUserMember(UserModel user) {
    if (isUserLeader(user)) return true;
    return members.any((m) =>
        m.studentCode == user.identifierCode ||
        m.id == user.userId.toString() ||
        m.fullName.toLowerCase() == user.fullName.toLowerCase());
  }

  StudentGroupModel copyWith({
    String? id,
    String? code,
    String? name,
    String? leaderName,
    String? leaderCode,
    String? leaderPhone,
    String? leaderEmail,
    String? major,
    int? currentMembers,
    int? maxMembers,
    String? status,
    String? topicName,
    String? description,
    bool? hasRequested,
    List<GroupMemberModel>? members,
    List<GroupRequestModel>? requests,
  }) {
    return StudentGroupModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      leaderName: leaderName ?? this.leaderName,
      leaderCode: leaderCode ?? this.leaderCode,
      leaderPhone: leaderPhone ?? this.leaderPhone,
      leaderEmail: leaderEmail ?? this.leaderEmail,
      major: major ?? this.major,
      currentMembers: currentMembers ?? this.currentMembers,
      maxMembers: maxMembers ?? this.maxMembers,
      status: status ?? this.status,
      topicName: topicName ?? this.topicName,
      description: description ?? this.description,
      hasRequested: hasRequested ?? this.hasRequested,
      members: members ?? this.members,
      requests: requests ?? this.requests,
    );
  }

  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = (json['members'] ?? json['Members']) as List? ?? [];
    List<GroupMemberModel> memberList = rawMembers
        .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
        .toList();

    var rawRequests = (json['requests'] ?? json['Requests']) as List? ?? [];
    List<GroupRequestModel> requestList = rawRequests
        .map((r) => GroupRequestModel.fromJson(r as Map<String, dynamic>))
        .toList();

    // Tìm thông tin nhóm trưởng từ members nếu json không cung cấp trực tiếp
    GroupMemberModel? foundLeader;
    for (final m in memberList) {
      if (m.isLeader) {
        foundLeader = m;
        break;
      }
    }
    foundLeader ??= memberList.firstOrNull;

    final gId = (json['id'] ?? json['Id'] ?? json['groupId'] ?? json['GroupId'] ?? '').toString();
    final gCode = json['code'] ?? json['Code'] ?? 'N${gId.padLeft(2, '0')}';
    final gName = (json['name'] ?? json['Name'] ?? json['groupName'] ?? json['GroupName'] ?? '').toString();
    final rawStatus = (json['status'] ?? json['Status'] ?? 'recruiting').toString();
    final rawLeader = (json['leaderName'] ?? json['LeaderName'] ?? json['leader'] ?? json['Leader'] ?? foundLeader?.fullName ?? '').toString();
    final rawContact = (json['leaderEmail'] ?? json['LeaderEmail'] ?? json['contact'] ?? json['Contact'] ?? foundLeader?.email ?? '').toString();
    final rawCount = json['currentMembers'] ?? json['CurrentMembers'] ?? json['memberCount'] ?? json['MemberCount'] ?? memberList.length;
    final int count = rawCount is int ? rawCount : int.tryParse(rawCount.toString()) ?? memberList.length;
    final rawMax = json['maxMembers'] ?? json['MaxMembers'] ?? 3;
    final int max = rawMax is int ? rawMax : int.tryParse(rawMax.toString()) ?? 3;

    return StudentGroupModel(
      id: gId,
      code: gCode,
      name: gName,
      leaderName: rawLeader,
      leaderCode: json['leaderCode'] ?? foundLeader?.studentCode ?? '',
      leaderPhone: json['leaderPhone'] ?? foundLeader?.phone ?? '',
      leaderEmail: rawContact,
      major: (json['major'] ?? json['Major'] ?? 'Công nghệ thông tin').toString(),
      currentMembers: count,
      maxMembers: max,
      status: rawStatus,
      topicName: json['topicName'] ?? json['thesisName'] ?? json['ThesisName'],
      description: json['description'],
      hasRequested: json['hasRequested'] ?? false,
      members: memberList,
      requests: requestList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'leaderName': leaderName,
    'leaderCode': leaderCode,
    'leaderPhone': leaderPhone,
    'leaderEmail': leaderEmail,
    'major': major,
    'currentMembers': currentMembers,
    'maxMembers': maxMembers,
    'status': status,
    'topicName': topicName,
    'description': description,
    'hasRequested': hasRequested,
    'members': members.map((m) => m.toJson()).toList(),
    'requests': requests.map((r) => r.toJson()).toList(),
  };
}
