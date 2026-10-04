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

  bool get isLeader => role == 'leader';

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      studentCode: json['studentCode'] ?? json['code'] ?? '',
      role: json['role'] ?? 'member',
      email: json['email'],
      phone: json['phone'],
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
    required this.createdAt,
    this.status = 'pending',
  });

  bool get isPending => status == 'pending';

  factory GroupRequestModel.fromJson(Map<String, dynamic> json) {
    return GroupRequestModel(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName'] ?? '',
      studentCode: json['studentCode'] ?? '',
      studentPhone: json['studentPhone'] ?? '',
      major: json['major'] ?? 'Công nghệ thông tin',
      note: json['note'],
      createdAt: json['createdAt'] ?? 'Hôm nay',
      status: json['status'] ?? 'pending',
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
    'createdAt': createdAt,
    'status': status,
  };
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
  final String status; // 'recruiting' or 'full'
  final String? topicName;
  final String? description;
  final bool hasRequested;
  final List<GroupMemberModel> members;

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
  });

  bool get isRecruiting => status == 'recruiting' && currentMembers < maxMembers;
  bool get isFull => currentMembers >= maxMembers || status == 'full';

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
    );
  }

  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List? ?? [];
    List<GroupMemberModel> memberList = rawMembers
        .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return StudentGroupModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      leaderName: json['leaderName'] ?? '',
      leaderCode: json['leaderCode'] ?? '',
      leaderPhone: json['leaderPhone'] ?? '',
      leaderEmail: json['leaderEmail'] ?? '',
      major: json['major'] ?? 'Công nghệ thông tin',
      currentMembers: json['currentMembers'] ?? memberList.length,
      maxMembers: json['maxMembers'] ?? 3,
      status: json['status'] ?? 'recruiting',
      topicName: json['topicName'],
      description: json['description'],
      hasRequested: json['hasRequested'] ?? false,
      members: memberList,
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
  };
}
