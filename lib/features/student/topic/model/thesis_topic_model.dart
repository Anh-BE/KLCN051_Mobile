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
  final String? registeredGroupName;
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
    this.registeredGroupName,
    this.periodName = 'Đợt 1 - KLCN - CNTT',
    this.researchDirection = 'Ứng dụng',
    this.targetOutput,
  });

  bool get isOpen => status == 'open' || status == 'available';

  String get statusDisplay {
    if (isMyTopic) return 'Đã đăng ký';
    if (isOpen) return 'Mở';
    return 'Đóng';
  }

  String get studentLimitDisplay {
    if (maxStudents <= 0) return 'Chưa giới hạn SV';
    return 'Tối đa $maxStudents SV (Hiện có $currentStudents SV)';
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

  factory ThesisTopicModel.fromJson(Map<String, dynamic> json) {
    return ThesisTopicModel(
      id: (json['thesisId'] ?? json['id'] ?? '').toString(),
      topicCode: (json['thesisCode'] ?? json['topicCode'] ?? json['code'] ?? 'CNTT-KLCN001').toString(),
      title: json['thesisName'] ?? json['title'] ?? json['topicName'] ?? '',
      titleEn: json['thesisNameEn'] ?? json['titleEn'],
      description: json['description'] ?? json['objective'] ?? 'Chưa có mô tả chi tiết.',
      requirements: json['requirements'] ?? json['techStack'] ?? 'Nắm vững kiến thức chuyên ngành.',
      major: json['majorName'] ?? json['major'] ?? 'Công nghệ thông tin',
      lecturerName: json['lecturerName'] ?? json['supervisorName'] ?? 'Bùi Công Danh',
      lecturerTitle: json['lecturerTitle'] ?? json['academicTitle'] ?? 'ThS.',
      lecturerEmail: json['lecturerEmail'] ?? json['email'],
      lecturerPhone: json['lecturerPhone'] ?? json['phone'],
      maxStudents: json['maxStudents'] != null ? int.tryParse(json['maxStudents'].toString()) ?? 0 : 0,
      currentStudents: json['currentStudents'] != null ? int.tryParse(json['currentStudents'].toString()) ?? 0 : 0,
      status: json['status'] ?? 'open',
      isMyTopic: json['isMyTopic'] == true,
      registeredGroupName: json['groupName'] ?? json['registeredGroupName'],
      periodName: json['periodName'] ?? 'Đợt 1 - KLCN - CNTT',
      researchDirection: json['researchDirection'] ?? json['direction'] ?? 'Tích hợp',
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
    String? registeredGroupName,
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
      registeredGroupName: registeredGroupName ?? this.registeredGroupName,
      periodName: periodName ?? this.periodName,
      researchDirection: researchDirection ?? this.researchDirection,
      targetOutput: targetOutput ?? this.targetOutput,
    );
  }
}
