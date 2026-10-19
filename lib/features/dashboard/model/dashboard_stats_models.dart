class LecturerDashboardStats {
  final int totalProposed;
  final int approvedCount;
  final int needsRevisionCount;
  final int rejectedCount;
  final int supervisedThesesCount;
  final int supervisedGroupsCount;
  final String periodName;

  LecturerDashboardStats({
    this.totalProposed = 0,
    this.approvedCount = 0,
    this.needsRevisionCount = 0,
    this.rejectedCount = 0,
    this.supervisedThesesCount = 0,
    this.supervisedGroupsCount = 0,
    this.periodName = 'HK1 (2026-2027)',
  });

  factory LecturerDashboardStats.fromJson(Map<String, dynamic> json) {
    return LecturerDashboardStats(
      totalProposed: json['totalProposed'] ?? 0,
      approvedCount: json['approvedCount'] ?? 0,
      needsRevisionCount: json['needsRevisionCount'] ?? 0,
      rejectedCount: json['rejectedCount'] ?? 0,
      supervisedThesesCount: json['supervisedThesesCount'] ?? 0,
      supervisedGroupsCount: json['supervisedGroupsCount'] ?? 0,
      periodName: json['periodName'] ?? 'HK1 (2026-2027)',
    );
  }
}

class AdminDashboardStats {
  final int totalTheses;
  final int registeredTheses;
  final int supervisedTheses;
  final int activeLecturersCount;
  final String periodName;

  AdminDashboardStats({
    this.totalTheses = 0,
    this.registeredTheses = 0,
    this.supervisedTheses = 0,
    this.activeLecturersCount = 0,
    this.periodName = 'HK1 (2026-2027)',
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalTheses: json['totalTheses'] ?? 0,
      registeredTheses: json['registeredTheses'] ?? 0,
      supervisedTheses: json['supervisedTheses'] ?? 0,
      activeLecturersCount: json['activeLecturersCount'] ?? 0,
      periodName: json['periodName'] ?? 'HK1 (2026-2027)',
    );
  }
}

class StudentDashboardStats {
  final int totalWeeks;
  final int submittedWeeks;
  final int unsubmittedWeeks;
  final int assignedTasksCount;
  final String? upcomingDeadlineTitle;
  final DateTime? upcomingDeadlineTime;
  final String? upcomingRemainingText;
  final bool hasUpcomingDeadline;
  final String periodName;

  StudentDashboardStats({
    this.totalWeeks = 0,
    this.submittedWeeks = 0,
    this.unsubmittedWeeks = 0,
    this.assignedTasksCount = 0,
    this.upcomingDeadlineTitle,
    this.upcomingDeadlineTime,
    this.upcomingRemainingText,
    this.hasUpcomingDeadline = false,
    this.periodName = 'HK1 (2026-2027)',
  });

  factory StudentDashboardStats.fromJson(Map<String, dynamic> json) {
    DateTime? deadline;
    if (json['upcomingDeadlineTime'] != null) {
      deadline = DateTime.tryParse(json['upcomingDeadlineTime'].toString());
    }

    return StudentDashboardStats(
      totalWeeks: json['totalWeeks'] ?? 0,
      submittedWeeks: json['submittedWeeks'] ?? 0,
      unsubmittedWeeks: json['unsubmittedWeeks'] ?? 0,
      assignedTasksCount: json['assignedTasksCount'] ?? 0,
      upcomingDeadlineTitle: json['upcomingDeadlineTitle'],
      upcomingDeadlineTime: deadline,
      upcomingRemainingText: json['upcomingRemainingText'],
      hasUpcomingDeadline: json['hasUpcomingDeadline'] == true,
      periodName: json['periodName'] ?? 'HK1 (2026-2027)',
    );
  }
}
