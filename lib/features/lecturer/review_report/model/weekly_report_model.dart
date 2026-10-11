import 'package:flutter/material.dart';

/// Model thông tin tiến độ làm đề tài và báo cáo tuần của Giảng viên hướng dẫn
class LecturerThesisProgressModel {
  final int thesisId;
  final String thesisCode;
  final String thesisTitle;
  final int? groupId;
  final String groupName;
  final int? leaderId;
  final String leaderCode;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final int memberCount;
  final int totalWeeks;
  final int submittedWeeksCount;
  final int approvedWeeksCount;
  final int pendingWeeksCount;
  final double progressPercentage;

  LecturerThesisProgressModel({
    required this.thesisId,
    required this.thesisCode,
    required this.thesisTitle,
    this.groupId,
    required this.groupName,
    this.leaderId,
    required this.leaderCode,
    required this.leaderName,
    required this.leaderEmail,
    required this.leaderPhone,
    this.memberCount = 1,
    this.totalWeeks = 12,
    this.submittedWeeksCount = 0,
    this.approvedWeeksCount = 0,
    this.pendingWeeksCount = 0,
    this.progressPercentage = 0.0,
  });

  factory LecturerThesisProgressModel.fromJson(Map<String, dynamic> json) {
    return LecturerThesisProgressModel(
      thesisId: json['thesisId'] is int
          ? json['thesisId']
          : int.tryParse(json['thesisId']?.toString() ?? '0') ?? 0,
      thesisCode: json['thesisCode']?.toString() ?? '',
      thesisTitle: json['thesisTitle']?.toString() ?? 'Đề tài chưa đặt tên',
      groupId: json['groupId'] is int
          ? json['groupId']
          : int.tryParse(json['groupId']?.toString() ?? ''),
      groupName: json['groupName']?.toString() ?? 'Chưa ghép nhóm',
      leaderId: json['leaderId'] is int
          ? json['leaderId']
          : int.tryParse(json['leaderId']?.toString() ?? ''),
      leaderCode: json['leaderCode']?.toString() ?? '',
      leaderName: json['leaderName']?.toString() ?? 'Chưa chỉ định',
      leaderEmail: json['leaderEmail']?.toString() ?? '',
      leaderPhone: json['leaderPhone']?.toString() ?? '',
      memberCount: json['memberCount'] is int
          ? json['memberCount']
          : int.tryParse(json['memberCount']?.toString() ?? '1') ?? 1,
      totalWeeks: json['totalWeeks'] is int
          ? json['totalWeeks']
          : int.tryParse(json['totalWeeks']?.toString() ?? '12') ?? 12,
      submittedWeeksCount: json['submittedWeeksCount'] is int
          ? json['submittedWeeksCount']
          : int.tryParse(json['submittedWeeksCount']?.toString() ?? '0') ?? 0,
      approvedWeeksCount: json['approvedWeeksCount'] is int
          ? json['approvedWeeksCount']
          : int.tryParse(json['approvedWeeksCount']?.toString() ?? '0') ?? 0,
      pendingWeeksCount: json['pendingWeeksCount'] is int
          ? json['pendingWeeksCount']
          : int.tryParse(json['pendingWeeksCount']?.toString() ?? '0') ?? 0,
      progressPercentage: json['progressPercentage'] is num
          ? (json['progressPercentage'] as num).toDouble()
          : double.tryParse(json['progressPercentage']?.toString() ?? '0') ?? 0.0,
    );
  }

  // Helper getters
  bool get hasPendingReports => pendingWeeksCount > 0;
  bool get isCompleted => approvedWeeksCount >= totalWeeks && totalWeeks > 0;
  String get representativeInfo =>
      leaderName.isNotEmpty && leaderName != 'Chưa chỉ định'
          ? '$leaderName ($leaderCode)'
          : 'Chưa có trưởng nhóm';
}

/// Model 1 tuần trong lộ trình 12 tuần
class WeeklyTimelineItemModel {
  final int planId;
  final int thesisId;
  final int weekNumber;
  final String title;
  final String detailedRequirements;
  final DateTime deadline;
  final String formattedDeadline;

  // Dữ liệu báo cáo sinh viên nộp
  final int? reportId;
  final String? content;
  final String? reportFileUrl;
  final DateTime? submittedAt;
  final String? formattedSubmittedAt;
  final String submissionStatus; // NotSubmitted, Pending, Approved, NeedsRevision, Overdue

  // CỐ ĐỊNH SINH VIÊN ĐẠI DIỆN NỘP LÀ NHÓM TRƯỞNG
  final String submitterRole;
  final String? submitterName;
  final String? submitterCode;

  // Nhận xét của Giảng viên hướng dẫn
  final String? supervisorFeedback;
  final double? supervisorScore;
  final bool? isPassed;

  WeeklyTimelineItemModel({
    required this.planId,
    required this.thesisId,
    required this.weekNumber,
    required this.title,
    required this.detailedRequirements,
    required this.deadline,
    required this.formattedDeadline,
    this.reportId,
    this.content,
    this.reportFileUrl,
    this.submittedAt,
    this.formattedSubmittedAt,
    this.submissionStatus = 'NotSubmitted',
    this.submitterRole = 'Nhóm trưởng (Đại diện nộp)',
    this.submitterName,
    this.submitterCode,
    this.supervisorFeedback,
    this.supervisorScore,
    this.isPassed,
  });

  factory WeeklyTimelineItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDeadline = DateTime.now();
    if (json['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(json['deadline'].toString()) ?? DateTime.now();
    }

    DateTime? parsedSubmittedAt;
    if (json['submittedAt'] != null) {
      parsedSubmittedAt = DateTime.tryParse(json['submittedAt'].toString());
    }

    return WeeklyTimelineItemModel(
      planId: json['planId'] is int
          ? json['planId']
          : int.tryParse(json['planId']?.toString() ?? '0') ?? 0,
      thesisId: json['thesisId'] is int
          ? json['thesisId']
          : int.tryParse(json['thesisId']?.toString() ?? '0') ?? 0,
      weekNumber: json['weekNumber'] is int
          ? json['weekNumber']
          : int.tryParse(json['weekNumber']?.toString() ?? '1') ?? 1,
      title: json['title']?.toString() ?? 'Nhiệm vụ tuần',
      detailedRequirements: json['detailedRequirements']?.toString() ?? '',
      deadline: parsedDeadline,
      formattedDeadline: json['formattedDeadline']?.toString() ?? '',
      reportId: json['reportId'] is int
          ? json['reportId']
          : int.tryParse(json['reportId']?.toString() ?? ''),
      content: json['content']?.toString(),
      reportFileUrl: json['reportFileUrl']?.toString(),
      submittedAt: parsedSubmittedAt,
      formattedSubmittedAt: json['formattedSubmittedAt']?.toString(),
      submissionStatus: json['submissionStatus']?.toString() ?? 'NotSubmitted',
      submitterRole: json['submitterRole']?.toString() ?? 'Nhóm trưởng (Đại diện nộp)',
      submitterName: json['submitterName']?.toString(),
      submitterCode: json['submitterCode']?.toString(),
      supervisorFeedback: json['supervisorFeedback']?.toString(),
      supervisorScore: json['supervisorScore'] is num
          ? (json['supervisorScore'] as num).toDouble()
          : double.tryParse(json['supervisorScore']?.toString() ?? ''),
      isPassed: json['isPassed'] is bool ? json['isPassed'] : null,
    );
  }

  WeeklyTimelineItemModel copyWith({
    int? reportId,
    String? content,
    String? reportFileUrl,
    DateTime? submittedAt,
    String? formattedSubmittedAt,
    String? submissionStatus,
    String? submitterRole,
    String? submitterName,
    String? submitterCode,
    String? supervisorFeedback,
    double? supervisorScore,
    bool? isPassed,
  }) {
    return WeeklyTimelineItemModel(
      planId: planId,
      thesisId: thesisId,
      weekNumber: weekNumber,
      title: title,
      detailedRequirements: detailedRequirements,
      deadline: deadline,
      formattedDeadline: formattedDeadline,
      reportId: reportId ?? this.reportId,
      content: content ?? this.content,
      reportFileUrl: reportFileUrl ?? this.reportFileUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      formattedSubmittedAt: formattedSubmittedAt ?? this.formattedSubmittedAt,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submitterRole: submitterRole ?? this.submitterRole,
      submitterName: submitterName ?? this.submitterName,
      submitterCode: submitterCode ?? this.submitterCode,
      supervisorFeedback: supervisorFeedback ?? this.supervisorFeedback,
      supervisorScore: supervisorScore ?? this.supervisorScore,
      isPassed: isPassed ?? this.isPassed,
    );
  }

  // Getters trạng thái
  bool get isSubmitted => reportId != null;
  bool get isApproved =>
      submissionStatus.toLowerCase() == 'approved' ||
      submissionStatus.toLowerCase() == 'daduyet';
  bool get isPending =>
      submissionStatus.toLowerCase() == 'pending' ||
      submissionStatus.toLowerCase() == 'choduyet';
  bool get isNeedsRevision =>
      submissionStatus.toLowerCase() == 'needsrevision' ||
      submissionStatus.toLowerCase() == 'canchinhsua';
  bool get isOverdue =>
      submissionStatus.toLowerCase() == 'overdue' ||
      submissionStatus.toLowerCase() == 'quahan';
  bool get isNotSubmitted =>
      submissionStatus.toLowerCase() == 'notsubmitted' ||
      submissionStatus.toLowerCase() == 'chuanop';

  // Nhãn hiển thị trạng thái chuẩn App_Mobile.md
  String get statusDisplayText {
    if (isApproved) return 'Đã duyệt';
    if (isPending) return 'Chờ duyệt';
    if (isNeedsRevision) return 'Cần chỉnh sửa';
    if (isOverdue) return 'Quá hạn';
    return 'Chưa nộp';
  }

  // Màu sắc trạng thái theo Design System
  Color get statusColor {
    if (isApproved) return const Color(0xFF10B981); // Emerald Green
    if (isPending) return const Color(0xFFF59E0B); // Amber Orange
    if (isNeedsRevision || isOverdue) return const Color(0xFFEF4444); // Red
    return const Color(0xFF64748B); // Slate Grey
  }

  Color get statusBgColor {
    if (isApproved) return const Color(0xFFD1FAE5);
    if (isPending) return const Color(0xFFFEF3C7);
    if (isNeedsRevision || isOverdue) return const Color(0xFFFEE2E2);
    return const Color(0xFFF1F5F9);
  }

  IconData get statusIcon {
    if (isApproved) return Icons.check_circle_rounded;
    if (isPending) return Icons.hourglass_top_rounded;
    if (isNeedsRevision) return Icons.edit_note_rounded;
    if (isOverdue) return Icons.warning_amber_rounded;
    return Icons.radio_button_unchecked_rounded;
  }
}

/// Request nộp nhận xét & chấm điểm tiến độ
class FeedbackRequestModel {
  final int reportId;
  final int planId;
  final int thesisId;
  final String supervisorFeedback;
  final double? supervisorScore;
  final bool isPassed;
  final String submissionStatus; // "Approved" or "NeedsRevision"

  FeedbackRequestModel({
    required this.reportId,
    required this.planId,
    required this.thesisId,
    required this.supervisorFeedback,
    this.supervisorScore,
    required this.isPassed,
    required this.submissionStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'planId': planId,
      'thesisId': thesisId,
      'supervisorFeedback': supervisorFeedback,
      'supervisorScore': supervisorScore,
      'isPassed': isPassed,
      'submissionStatus': submissionStatus,
    };
  }
}
