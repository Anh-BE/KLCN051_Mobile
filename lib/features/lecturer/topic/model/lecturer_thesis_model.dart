class LecturerThesisModel {
  final int thesisId;
  final String thesisTitle;
  final String thesisType; // Định hướng: Nghiên cứu, Ứng dụng, Tích hợp
  final String requirements;
  final String status; // Approved, Pending, Rejected
  final int? periodId;
  final String periodName;
  final String periodCode;
  final String gvhd;
  final List<RegisteredGroupItem> registeredGroups;
  final List<OutlineObjectiveItem> outlineObjectives;

  LecturerThesisModel({
    required this.thesisId,
    required this.thesisTitle,
    required this.thesisType,
    required this.requirements,
    required this.status,
    this.periodId,
    required this.periodName,
    required this.periodCode,
    required this.gvhd,
    required this.registeredGroups,
    required this.outlineObjectives,
  });

  factory LecturerThesisModel.fromJson(Map<String, dynamic> json) {
    var rawGroups = json['registeredGroups'] as List? ?? json['RegisteredGroups'] as List? ?? [];
    List<RegisteredGroupItem> groups = rawGroups
        .where((g) => g != null && g is Map)
        .map((g) => RegisteredGroupItem.fromJson(Map<String, dynamic>.from(g as Map)))
        .toList();

    var rawObjectives = json['outlineObjectives'] as List? ?? json['OutlineObjectives'] as List? ?? [];
    List<OutlineObjectiveItem> objectives = rawObjectives
        .where((o) => o != null && o is Map)
        .map((o) => OutlineObjectiveItem.fromJson(Map<String, dynamic>.from(o as Map)))
        .toList();

    int? parsedPeriodId = json['periodId'] ?? json['PeriodId'];
    final periodName = (json['periodName'] ?? json['PeriodName'] ?? '').toString();
    final periodCode = (json['periodCode'] ?? json['PeriodCode'] ?? '').toString();

    // Tự động suy luận periodId nếu backend chưa trả về field PeriodId trong object
    if (parsedPeriodId == null) {
      if (periodCode.contains('HK1') || periodName.contains('Đợt 1') || periodName.contains('D?t 1')) {
        parsedPeriodId = 1;
      } else if (periodCode.contains('HK2') || periodName.contains('Đợt 2') || periodName.contains('D?t 2')) {
        parsedPeriodId = 2;
      } else if (periodCode.contains('PeID01') || periodName.contains('TESTKL1')) {
        parsedPeriodId = 3;
      }
    }

    return LecturerThesisModel(
      thesisId: json['thesisId'] ?? json['ThesisId'] ?? 0,
      thesisTitle: json['thesisTitle'] ?? json['ThesisTitle'] ?? json['TenDeTai'] ?? '',
      thesisType: json['thesisType'] ?? json['ThesisType'] ?? json['DinhHuong'] ?? 'Ứng dụng',
      requirements: json['requirements'] ?? json['Requirements'] ?? json['YeuCau'] ?? '',
      status: json['status'] ?? json['Status'] ?? 'Approved',
      periodId: parsedPeriodId,
      periodName: periodName.isNotEmpty ? periodName : 'Khóa luận tốt nghiệp',
      periodCode: periodCode,
      gvhd: json['gvhd'] ?? json['Gvhd'] ?? '',
      registeredGroups: groups,
      outlineObjectives: objectives,
    );
  }
}

class RegisteredGroupItem {
  final int groupId;
  final String groupName;
  final String registrationStatus;
  final String registeredAt;
  final int memberCount;
  final List<GroupStudentMember> members;

  RegisteredGroupItem({
    required this.groupId,
    required this.groupName,
    required this.registrationStatus,
    required this.registeredAt,
    required this.memberCount,
    required this.members,
  });

  factory RegisteredGroupItem.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List? ?? [];
    List<GroupStudentMember> membersList = rawMembers
        .map((m) => GroupStudentMember.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return RegisteredGroupItem(
      groupId: json['groupId'] ?? 0,
      groupName: json['groupName'] ?? 'Nhóm sinh viên',
      registrationStatus: json['registrationStatus'] ?? 'Approved',
      registeredAt: json['registeredAt'] ?? '',
      memberCount: json['memberCount'] ?? membersList.length,
      members: membersList,
    );
  }
}

class GroupStudentMember {
  final int studentId;
  final String studentCode;
  final String fullName;
  final String classCode;
  final String role;
  final String phoneNumber;
  final String email;

  GroupStudentMember({
    required this.studentId,
    required this.studentCode,
    required this.fullName,
    required this.classCode,
    required this.role,
    required this.phoneNumber,
    required this.email,
  });

  factory GroupStudentMember.fromJson(Map<String, dynamic> json) {
    return GroupStudentMember(
      studentId: json['studentId'] ?? 0,
      studentCode: json['studentCode'] ?? '',
      fullName: json['fullName'] ?? '',
      classCode: json['classCode'] ?? '',
      role: json['role'] ?? 'Member',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class OutlineObjectiveItem {
  final int objectiveId;
  final String clocode;
  final String outlineContent;
  final double weightPercentage;
  final double maxScore;
  final List<OutlineObjectiveItem> subObjectives;

  OutlineObjectiveItem({
    required this.objectiveId,
    required this.clocode,
    required this.outlineContent,
    required this.weightPercentage,
    required this.maxScore,
    this.subObjectives = const [],
  });

  factory OutlineObjectiveItem.fromJson(Map<String, dynamic> json) {
    var rawSubs = json['subObjectives'] as List? ?? json['SubObjectives'] as List? ?? [];
    List<OutlineObjectiveItem> subs = rawSubs
        .where((s) => s != null && s is Map)
        .map((s) => OutlineObjectiveItem.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();

    return OutlineObjectiveItem(
      objectiveId: json['objectiveId'] ?? json['ObjectiveId'] ?? 0,
      clocode: (json['clocode'] ?? json['Clocode'] ?? json['cloCode'] ?? json['CloCode'] ?? '').toString(),
      outlineContent: (json['outlineContent'] ?? json['OutlineContent'] ?? json['content'] ?? '').toString(),
      weightPercentage: (json['weightPercentage'] as num?)?.toDouble() ??
          (json['WeightPercentage'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['maxScore'] as num?)?.toDouble() ??
          (json['MaxScore'] as num?)?.toDouble() ?? 10.0,
      subObjectives: subs,
    );
  }
}
