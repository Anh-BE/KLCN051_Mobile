class ThesisTopicModel {
  final String id;
  final String topicCode;
  final String title;
  final String? titleEn;
  final String description;
  final String requirements;
  final String major;
  final String lecturerName;
  final String? lecturerTitle;
  final String? lecturerEmail;
  final String? lecturerPhone;
  final int maxStudents;
  final int currentStudents;
  final String status; // 'open' ('Mở'), 'closed' ('Đóng'), 'registered'
  final bool isMyTopic;
  final String? registeredGroupId;
  final String? registeredGroupName;
  final List<String> memberNames;
  final String periodName;
  final String researchDirection; // Hướng đề tài: 'Tích hợp', 'Nghiên cứu', 'Ứng dụng'
  final String? targetOutput;

  const ThesisTopicModel({
    required this.id,
    required this.topicCode,
    required this.title,
    this.titleEn,
    required this.description,
    required this.requirements,
    required this.major,
    required this.lecturerName,
    this.lecturerTitle,
    this.lecturerEmail,
    this.lecturerPhone,
    this.maxStudents = 0, // 0 = Chưa giới hạn SV
    this.currentStudents = 0,
    this.status = 'open',
    this.isMyTopic = false,
    this.registeredGroupId,
    this.registeredGroupName,
    this.memberNames = const [],
    this.periodName = 'Đợt 1 - KLCN - CNTT',
    this.researchDirection = 'Ứng dụng',
    this.targetOutput,
  });

  bool get hasGroup {
    return (registeredGroupId != null && registeredGroupId!.isNotEmpty && registeredGroupId != '0') ||
        (registeredGroupName != null && registeredGroupName!.trim().isNotEmpty);
  }

  bool get isOpen {
    final s = status.toLowerCase();
    final isApprovedOrOpen = s == 'open' || s == 'approved' || s == 'available';
    return isApprovedOrOpen && !hasGroup;
  }

  bool isRegisteredByOther(String? myGroupId) {
    if (registeredGroupId == null || registeredGroupId!.isEmpty || registeredGroupId == '0') {
      return false;
    }
    return myGroupId == null || registeredGroupId != myGroupId;
  }

  bool isRegisteredByMyGroup(String? myGroupId) {
    if (registeredGroupId == null || registeredGroupId!.isEmpty || registeredGroupId == '0') {
      return isMyTopic;
    }
    return isMyTopic || (myGroupId != null && registeredGroupId == myGroupId);
  }

  String statusDisplayForGroup(String? myGroupId) {
    if (isRegisteredByMyGroup(myGroupId)) return 'Đã đăng ký';
    if (isRegisteredByOther(myGroupId)) return 'Đã có nhóm';
    if (isOpen) return 'Mở';
    return 'Đóng';
  }

  String get statusDisplay {
    if (isMyTopic) return 'Đã đăng ký';
    if (isOpen) return 'Mở';
    return 'Đóng';
  }

  String get studentLimitDisplay {
    if (maxStudents <= 0) {
      return 'Chưa giới hạn SV';
    }
    return 'Tối đa $maxStudents SV';
  }

  String get lecturerInitials {
    final clean = lecturerName.replaceAll(RegExp(r'(TS\.|ThS\.|PGS\.TS\.|GS\.TS\.|Thầy|Cô)\s*'), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'GV';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get lecturerDisplayName {
    if (lecturerTitle != null && lecturerTitle!.isNotEmpty) {
      return '$lecturerTitle $lecturerName';
    }
    return lecturerName;
  }

  List<String> getDisplayMemberNames({List<String>? fallbackMembers}) {
    if (memberNames.isNotEmpty) return memberNames;
    if (fallbackMembers != null && fallbackMembers.isNotEmpty) {
      return fallbackMembers;
    }
    return [];
  }

  factory ThesisTopicModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['thesisId'] ?? json['id'] ?? '').toString();
    final padId = rawId.isNotEmpty && int.tryParse(rawId) != null ? rawId.padLeft(3, '0') : '001';

    var rawMembers = json['memberNames'] as List? ?? json['MemberNames'] as List? ?? json['members'] as List? ?? [];
    List<String> parsedMembers = [];
    for (var m in rawMembers) {
      if (m is String && m.trim().isNotEmpty) {
        parsedMembers.add(m.trim());
      } else if (m is Map) {
        final name = (m['fullName'] ?? m['FullName'] ?? m['name'] ?? m['studentName'] ?? '').toString();
        if (name.trim().isNotEmpty) parsedMembers.add(name.trim());
      }
    }

    return ThesisTopicModel(
      id: rawId,
      topicCode: (json['thesisCode'] ?? json['topicCode'] ?? json['code'] ?? 'CNTT-KLCN$padId').toString(),
      title: json['thesisTitle'] ?? json['thesisName'] ?? json['title'] ?? json['topicName'] ?? '',
      titleEn: json['thesisNameEn'] ?? json['titleEn'],
      description: json['description'] ?? json['objective'] ?? json['requirements'] ?? 'Chưa có mô tả chi tiết.',
      requirements: json['requirements'] ?? json['techStack'] ?? 'Nắm vững kiến thức chuyên ngành.',
      major: json['majorName'] ?? json['major'] ?? 'Công nghệ thông tin',
      lecturerName: json['supervisorName'] ?? json['lecturerName'] ?? 'Chưa phân công',
      lecturerTitle: json['lecturerTitle'] ?? json['academicTitle'] ?? 'ThS.',
      lecturerEmail: json['lecturerEmail'] ?? json['email'],
      lecturerPhone: json['lecturerPhone'] ?? json['phone'],
      maxStudents: json['maxStudentsAllowed'] != null
          ? int.tryParse(json['maxStudentsAllowed'].toString()) ?? 2
          : (json['maxStudents'] != null ? int.tryParse(json['maxStudents'].toString()) ?? 2 : 2),
      currentStudents: json['currentStudents'] != null ? int.tryParse(json['currentStudents'].toString()) ?? 0 : 0,
      status: json['status'] ?? 'Open',
      isMyTopic: json['isMyTopic'] == true,
      registeredGroupId: json['groupId']?.toString(),
      registeredGroupName: json['groupName'] ?? json['registeredGroupName'],
      memberNames: parsedMembers,
      periodName: json['periodName'] ?? 'Đợt 1 - KLCN - CNTT',
      researchDirection: json['researchDirection'] ?? json['direction'] ?? 'Ứng dụng',
      targetOutput: json['targetOutput'] ?? 'Hệ thống phần mềm hoàn chỉnh + Báo cáo khóa luận',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicCode': topicCode,
      'title': title,
      'titleEn': titleEn,
      'description': description,
      'requirements': requirements,
      'major': major,
      'lecturerName': lecturerName,
      'lecturerTitle': lecturerTitle,
      'lecturerEmail': lecturerEmail,
      'lecturerPhone': lecturerPhone,
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      'status': status,
      'isMyTopic': isMyTopic,
      'registeredGroupName': registeredGroupName,
      'memberNames': memberNames,
      'periodName': periodName,
      'researchDirection': researchDirection,
      'targetOutput': targetOutput,
    };
  }

  ThesisTopicModel copyWith({
    String? id,
    String? topicCode,
    String? title,
    String? titleEn,
    String? description,
    String? requirements,
    String? major,
    String? lecturerName,
    String? lecturerTitle,
    String? lecturerEmail,
    String? lecturerPhone,
    int? maxStudents,
    int? currentStudents,
    String? status,
    bool? isMyTopic,
    String? registeredGroupId,
    String? registeredGroupName,
    List<String>? memberNames,
    String? periodName,
    String? researchDirection,
    String? targetOutput,
  }) {
    return ThesisTopicModel(
      id: id ?? this.id,
      topicCode: topicCode ?? this.topicCode,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      major: major ?? this.major,
      lecturerName: lecturerName ?? this.lecturerName,
      lecturerTitle: lecturerTitle ?? this.lecturerTitle,
      lecturerEmail: lecturerEmail ?? this.lecturerEmail,
      lecturerPhone: lecturerPhone ?? this.lecturerPhone,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      status: status ?? this.status,
      isMyTopic: isMyTopic ?? this.isMyTopic,
      registeredGroupId: registeredGroupId ?? this.registeredGroupId,
      registeredGroupName: registeredGroupName ?? this.registeredGroupName,
      memberNames: memberNames ?? this.memberNames,
      periodName: periodName ?? this.periodName,
      researchDirection: researchDirection ?? this.researchDirection,
      targetOutput: targetOutput ?? this.targetOutput,
    );
  }
}
