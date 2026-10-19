class RegistrationPeriodModel {
  final int periodId;
  final String periodCode;
  final String periodName;
  final String semester;
  final String academicYear;
  final String degreeType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? thesisTitle;
  final String? supervisorName;
  final String? groupName;
  final int currentWeek;
  final int totalWeeks;

  RegistrationPeriodModel({
    required this.periodId,
    required this.periodCode,
    required this.periodName,
    required this.semester,
    required this.academicYear,
    required this.degreeType,
    this.startDate,
    this.endDate,
    this.thesisTitle,
    this.supervisorName,
    this.groupName,
    this.currentWeek = 1,
    this.totalWeeks = 12,
  });

  factory RegistrationPeriodModel.fromJson(Map<String, dynamic> json) {
    final rawPeriodId = json['periodId'] ?? json['PeriodId'] ?? json['id'] ?? 0;
    final int parsedPeriodId = rawPeriodId is int
        ? rawPeriodId
        : int.tryParse(rawPeriodId.toString()) ?? 0;

    final String rawPeriodCode = (json['periodCode'] ?? json['PeriodCode'] ?? '').toString();
    final String rawPeriodName = (json['periodName'] ?? json['PeriodName'] ?? '').toString();
    final String rawSemester = (json['semester'] ?? json['Semester'] ?? '').toString();
    final String rawAcademicYear = (json['academicYear'] ?? json['AcademicYear'] ?? '').toString();
    final String rawDegreeType = (json['degreeType'] ?? json['DegreeType'] ?? 'Bachelor').toString();

    DateTime? parsedStartDate;
    final rawStart = json['startDate'] ?? json['StartDate'];
    if (rawStart != null) {
      parsedStartDate = DateTime.tryParse(rawStart.toString());
    }

    DateTime? parsedEndDate;
    final rawEnd = json['endDate'] ?? json['EndDate'];
    if (rawEnd != null) {
      parsedEndDate = DateTime.tryParse(rawEnd.toString());
    }

    final rawTotalWeeks = json['executionDurationWeeks'] ?? json['totalWeeks'] ?? 12;
    final int totalWeeksParsed = rawTotalWeeks is int
        ? rawTotalWeeks
        : int.tryParse(rawTotalWeeks.toString()) ?? 12;

    int computedWeek = 1;
    if (parsedStartDate != null) {
      final now = DateTime.now();
      if (now.isAfter(parsedStartDate)) {
        final diffDays = now.difference(parsedStartDate).inDays;
        final week = (diffDays / 7).ceil();
        if (week > 0) {
          computedWeek = week;
        }
      }
    }
    if (computedWeek > totalWeeksParsed) {
      computedWeek = totalWeeksParsed;
    }

    return RegistrationPeriodModel(
      periodId: parsedPeriodId,
      periodCode: rawPeriodCode,
      periodName: rawPeriodName,
      semester: rawSemester,
      academicYear: rawAcademicYear,
      degreeType: rawDegreeType,
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      thesisTitle: (json['thesisTitle'] ?? json['ThesisTitle'])?.toString(),
      supervisorName: (json['supervisorName'] ?? json['SupervisorName'])?.toString(),
      groupName: (json['groupName'] ?? json['GroupName'])?.toString(),
      currentWeek: computedWeek,
      totalWeeks: totalWeeksParsed,
    );
  }

  bool get isEngineer {
    final lower = degreeType.toLowerCase();
    if (lower.contains('kỹ sư')) {
      return true;
    }
    if (lower.contains('engineer')) {
      return true;
    }
    return false;
  }

  String get degreeBadgeText {
    if (isEngineer) {
      return 'Bậc Kỹ sư';
    }
    return 'Bậc Cử nhân';
  }
}
