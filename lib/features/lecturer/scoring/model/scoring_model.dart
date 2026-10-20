class ScoringStudentModel {
  final int studentId;
  final String studentCode;
  final String studentName;
  final bool isLeader;
  final bool isGraded;
  final double totalScore;

  ScoringStudentModel({
    required this.studentId,
    this.studentCode = '',
    required this.studentName,
    this.isLeader = false,
    this.isGraded = false,
    required this.totalScore,
  });

  factory ScoringStudentModel.fromJson(Map<String, dynamic> json) {
    return ScoringStudentModel(
      studentId: json['studentId'] ?? json['StudentId'] ?? 0,
      studentCode: json['studentCode'] ?? json['StudentCode'] ?? '',
      studentName: json['studentName'] ?? json['StudentName'] ?? 'Sinh viên',
      isLeader: json['isLeader'] ?? json['IsLeader'] ?? false,
      isGraded: json['isGraded'] ?? json['IsGraded'] ?? false,
      totalScore: (json['totalScore'] ?? json['TotalScore'] ?? 0).toDouble(),
    );
  }

  ScoringStudentModel copyWith({
    int? studentId,
    String? studentCode,
    String? studentName,
    bool? isLeader,
    bool? isGraded,
    double? totalScore,
  }) {
    return ScoringStudentModel(
      studentId: studentId ?? this.studentId,
      studentCode: studentCode ?? this.studentCode,
      studentName: studentName ?? this.studentName,
      isLeader: isLeader ?? this.isLeader,
      isGraded: isGraded ?? this.isGraded,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  String get rank {
    if (!isGraded && totalScore == 0.0) return 'Chưa chấm';
    if (totalScore >= 9.0) return 'Xuất sắc';
    if (totalScore >= 8.0) return 'Giỏi';
    if (totalScore >= 6.5) return 'Khá';
    if (totalScore >= 5.0) return 'Trung bình';
    return 'Yếu';
  }
}

class ScoringThesisModel {
  final int thesisId;
  final String thesisCode;
  final String thesisTitle;
  final int groupId;
  final String groupName;
  final String supervisorName;
  final String reviewerName;
  final List<ScoringStudentModel> students;

  ScoringThesisModel({
    required this.thesisId,
    this.thesisCode = '',
    required this.thesisTitle,
    required this.groupId,
    required this.groupName,
    this.supervisorName = '',
    this.reviewerName = '',
    required this.students,
  });

  factory ScoringThesisModel.fromJson(Map<String, dynamic> json) {
    var rawStudents = json['students'] ?? json['Students'] ?? [];
    List<ScoringStudentModel> studentList = [];
    if (rawStudents is List) {
      studentList = rawStudents
          .map((s) => ScoringStudentModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    final id = json['thesisId'] ?? json['ThesisId'] ?? 0;
    final code = json['thesisCode'] ?? json['ThesisCode'] ?? (id > 0 ? 'DT${id.toString().padLeft(3, '0')}' : '');

    return ScoringThesisModel(
      thesisId: id,
      thesisCode: code,
      thesisTitle: json['thesisTitle'] ?? json['ThesisTitle'] ?? 'Đề tài',
      groupId: json['groupId'] ?? json['GroupId'] ?? 0,
      groupName: json['groupName'] ?? json['GroupName'] ?? 'Chưa có nhóm',
      supervisorName: json['supervisorName'] ?? json['SupervisorName'] ?? '',
      reviewerName: json['reviewerName'] ?? json['ReviewerName'] ?? '',
      students: studentList,
    );
  }

  int get gradedCount => students.where((s) => s.isGraded).length;
  int get totalStudents => students.length;
  bool get isCompleted => totalStudents > 0 && gradedCount == totalStudents;
}

class ObjectiveScoreModel {
  final int objectiveId;
  final String clocode;
  final String outlineContent;
  final double? weightPercentage;
  final double maxScore;
  double score;
  String comments;

  ObjectiveScoreModel({
    required this.objectiveId,
    this.clocode = 'CLO',
    required this.outlineContent,
    this.weightPercentage,
    required this.maxScore,
    this.score = 0.0,
    this.comments = '',
  });

  factory ObjectiveScoreModel.fromJson(Map<String, dynamic> json) {
    return ObjectiveScoreModel(
      objectiveId: json['objectiveId'] ?? json['ObjectiveId'] ?? 0,
      clocode: json['clocode'] ?? json['Clocode'] ?? 'CLO',
      outlineContent: json['outlineContent'] ?? json['OutlineContent'] ?? 'Tiêu chí đánh giá',
      weightPercentage: json['weightPercentage'] != null
          ? (json['weightPercentage'] as num).toDouble()
          : null,
      maxScore: (json['maxScore'] ?? json['MaxScore'] ?? 10.0).toDouble(),
      score: (json['score'] ?? json['Score'] ?? 0.0).toDouble(),
      comments: json['comments'] ?? json['Comments'] ?? '',
    );
  }

  ObjectiveScoreModel copy({
    double? newScore,
    String? newComments,
  }) {
    return ObjectiveScoreModel(
      objectiveId: objectiveId,
      clocode: clocode,
      outlineContent: outlineContent,
      weightPercentage: weightPercentage,
      maxScore: maxScore,
      score: newScore ?? score,
      comments: newComments ?? comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectiveId': objectiveId,
      'clocode': clocode,
      'score': score,
      'comments': comments,
    };
  }
}
