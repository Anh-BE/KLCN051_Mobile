class ScoringStudentModel {
  final int studentId;
  final String studentName;
  final double totalScore;

  ScoringStudentModel({
    required this.studentId,
    required this.studentName,
    required this.totalScore,
  });

  factory ScoringStudentModel.fromJson(Map<String, dynamic> json) {
    return ScoringStudentModel(
      studentId: json['studentId'] ?? json['StudentId'] ?? 0,
      studentName: json['studentName'] ?? json['StudentName'] ?? 'Sinh viên',
      totalScore: (json['totalScore'] ?? json['TotalScore'] ?? 0).toDouble(),
    );
  }

  ScoringStudentModel copyWith({
    int? studentId,
    String? studentName,
    double? totalScore,
  }) {
    return ScoringStudentModel(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}

class ScoringThesisModel {
  final int thesisId;
  final String thesisTitle;
  final int groupId;
  final String groupName;
  final List<ScoringStudentModel> students;

  ScoringThesisModel({
    required this.thesisId,
    required this.thesisTitle,
    required this.groupId,
    required this.groupName,
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

    return ScoringThesisModel(
      thesisId: json['thesisId'] ?? json['ThesisId'] ?? 0,
      thesisTitle: json['thesisTitle'] ?? json['ThesisTitle'] ?? 'Đề tài',
      groupId: json['groupId'] ?? json['GroupId'] ?? 0,
      groupName: json['groupName'] ?? json['GroupName'] ?? 'Chưa có nhóm',
      students: studentList,
    );
  }
}

class ObjectiveScoreModel {
  final int objectiveId;
  final String outlineContent;
  final double maxScore;
  double score;
  String comments;

  ObjectiveScoreModel({
    required this.objectiveId,
    required this.outlineContent,
    required this.maxScore,
    this.score = 0.0,
    this.comments = '',
  });

  factory ObjectiveScoreModel.fromJson(Map<String, dynamic> json) {
    return ObjectiveScoreModel(
      objectiveId: json['objectiveId'] ?? json['ObjectiveId'] ?? 0,
      outlineContent: json['outlineContent'] ?? json['OutlineContent'] ?? 'Tiêu chí đánh giá',
      maxScore: (json['maxScore'] ?? json['MaxScore'] ?? 10.0).toDouble(),
      score: (json['score'] ?? json['Score'] ?? 0.0).toDouble(),
      comments: json['comments'] ?? json['Comments'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectiveId': objectiveId,
      'score': score,
      'comments': comments,
    };
  }
}
