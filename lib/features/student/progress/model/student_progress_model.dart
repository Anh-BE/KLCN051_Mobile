import 'dart:convert';

String _fixEncoding(String? text) {
  if (text == null || text.isEmpty) return '';
  try {
    if (text.contains('Ã') || text.contains('á»') || text.contains('áº') || text.contains('Ä')) {
      return utf8.decode(latin1.encode(text));
    }
  } catch (_) {}
  return text;
}

class StudentThesisProgressModel {
  final bool hasThesis;
  final String? message;
  final int thesisId;
  final String thesisTitle;
  final String supervisorName;
  final String periodName;
  final List<ThesisStudentMemberModel> students;
  final List<WeeklyPlanModel> weeklyPlans;

  StudentThesisProgressModel({
    this.hasThesis = true,
    this.message,
    this.thesisId = 0,
    this.thesisTitle = '',
    this.supervisorName = '',
    this.periodName = '',
    this.students = const [],
    this.weeklyPlans = const [],
  });

  int get submittedCount => weeklyPlans.where((p) => p.report?.submittedAt != null).length;

  int get completionPercent {
    if (weeklyPlans.isEmpty) return 0;
    return ((submittedCount / weeklyPlans.length) * 100).round();
  }

  factory StudentThesisProgressModel.fromJson(Map<String, dynamic> json) {
    if (json['hasThesis'] == false) {
      return StudentThesisProgressModel(
        hasThesis: false,
        message: json['message']?.toString() ?? 'Bạn chưa có đề tài được duyệt.',
      );
    }

    final rawStudents = json['students'] as List<dynamic>? ?? [];
    final rawPlans = json['weeklyPlans'] as List<dynamic>? ?? [];

    return StudentThesisProgressModel(
      hasThesis: true,
      message: json['message']?.toString(),
      thesisId: json['thesisId'] is int
          ? json['thesisId']
          : (int.tryParse(json['thesisId']?.toString() ?? '0') ?? 0),
      thesisTitle: _fixEncoding(json['thesisTitle']?.toString() ?? ''),
      supervisorName: _fixEncoding(json['supervisorName']?.toString() ?? 'Chưa phân công'),
      periodName: _fixEncoding(json['periodName']?.toString() ?? 'Đợt khóa luận'),
      students: rawStudents.map((e) => ThesisStudentMemberModel.fromJson(e as Map<String, dynamic>)).toList(),
      weeklyPlans: rawPlans.map((e) => WeeklyPlanModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ThesisStudentMemberModel {
  final int studentId;
  final String studentCode;
  final String fullName;
  final String classCode;
  final bool isLeader;

  ThesisStudentMemberModel({
    required this.studentId,
    required this.studentCode,
    required this.fullName,
    required this.classCode,
    required this.isLeader,
  });

  factory ThesisStudentMemberModel.fromJson(Map<String, dynamic> json) {
    return ThesisStudentMemberModel(
      studentId: json['studentId'] is int
          ? json['studentId']
          : (int.tryParse(json['studentId']?.toString() ?? '0') ?? 0),
      studentCode: json['studentCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      classCode: json['classCode']?.toString() ?? '',
      isLeader: json['isLeader'] == true,
    );
  }
}

class WeeklyPlanModel {
  final int planId;
  final int thesisId;
  final int weekNumber;
  final String title;
  final String detailedRequirements;
  final DateTime? deadline;
  final bool isOverdue;
  final ProgressReportItemModel? report;

  WeeklyPlanModel({
    required this.planId,
    required this.thesisId,
    required this.weekNumber,
    required this.title,
    required this.detailedRequirements,
    this.deadline,
    this.isOverdue = false,
    this.report,
  });

  bool get isSubmitted => report?.submittedAt != null;
  bool get isGraded => report?.isGraded ?? false;
  bool get isPassed => (report?.isGraded ?? false) && (report?.isPassed ?? false);

  factory WeeklyPlanModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDeadline;
    if (json['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(json['deadline'].toString());
    }

    return WeeklyPlanModel(
      planId: json['planId'] is int ? json['planId'] : (int.tryParse(json['planId']?.toString() ?? '0') ?? 0),
      thesisId: json['thesisId'] is int ? json['thesisId'] : (int.tryParse(json['thesisId']?.toString() ?? '0') ?? 0),
      weekNumber: json['weekNumber'] is int ? json['weekNumber'] : (int.tryParse(json['weekNumber']?.toString() ?? '0') ?? 0),
      title: _fixEncoding(json['title']?.toString() ?? ''),
      detailedRequirements: _fixEncoding(json['detailedRequirements']?.toString() ?? ''),
      deadline: parsedDeadline,
      isOverdue: json['isOverdue'] == true,
      report: json['report'] != null && json['report'] is Map<String, dynamic>
          ? ProgressReportItemModel.fromJson(json['report'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProgressReportItemModel {
  final int reportId;
  final String content;
  final String? reportFileUrl;
  final DateTime? submittedAt;
  final String submissionStatus;
  final String? supervisorFeedback;
  final double? supervisorScore;
  final bool? isPassed;
  final bool isGraded;

  ProgressReportItemModel({
    required this.reportId,
    required this.content,
    this.reportFileUrl,
    this.submittedAt,
    required this.submissionStatus,
    this.supervisorFeedback,
    this.supervisorScore,
    this.isPassed,
    required this.isGraded,
  });

  factory ProgressReportItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedSubmittedAt;
    if (json['submittedAt'] != null) {
      parsedSubmittedAt = DateTime.tryParse(json['submittedAt'].toString());
    }

    double? parsedScore;
    if (json['supervisorScore'] != null) {
      parsedScore = double.tryParse(json['supervisorScore'].toString());
    }

    return ProgressReportItemModel(
      reportId: json['reportId'] is int ? json['reportId'] : (int.tryParse(json['reportId']?.toString() ?? '0') ?? 0),
      content: _fixEncoding(json['content']?.toString() ?? ''),
      reportFileUrl: json['reportFileUrl']?.toString(),
      submittedAt: parsedSubmittedAt,
      submissionStatus: json['submissionStatus']?.toString() ?? 'Assigned',
      supervisorFeedback: json['supervisorFeedback'] != null ? _fixEncoding(json['supervisorFeedback'].toString()) : null,
      supervisorScore: parsedScore,
      isPassed: json['isPassed'] == true ? true : (json['isPassed'] == false ? false : null),
      isGraded: json['isGraded'] == true,
    );
  }
}
