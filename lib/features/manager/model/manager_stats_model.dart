class DepartmentStat {
  final String departmentName;
  final int totalTheses;
  final int approvedTheses;
  final int pendingTheses;
  final int studentCount;
  final int lecturerCount;

  DepartmentStat({
    required this.departmentName,
    required this.totalTheses,
    required this.approvedTheses,
    required this.pendingTheses,
    required this.studentCount,
    required this.lecturerCount,
  });
}

class LateSubmissionItem {
  final String studentCode;
  final String studentName;
  final String groupName;
  final String taskName;
  final String deadlineStr;
  final String submittedTimeStr;
  final int lateHours;
  final String reason;

  LateSubmissionItem({
    required this.studentCode,
    required this.studentName,
    required this.groupName,
    required this.taskName,
    required this.deadlineStr,
    required this.submittedTimeStr,
    required this.lateHours,
    required this.reason,
  });
}

class CommitteeStat {
  final String committeeCode;
  final String name;
  final String president; // Chủ tịch
  final String secretary; // Thư ký
  final String reviewer;  // Phản biện
  final int assignedGroups;
  final String room;
  final String defenseDate;

  CommitteeStat({
    required this.committeeCode,
    required this.name,
    required this.president,
    required this.secretary,
    required this.reviewer,
    required this.assignedGroups,
    required this.room,
    required this.defenseDate,
  });
}
