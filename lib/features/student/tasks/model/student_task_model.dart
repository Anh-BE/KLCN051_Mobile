import 'package:flutter/material.dart';

enum TaskStatus {
  pending,      // Chưa đến hạn
  overdue,      // Quá hạn chưa nộp
  submittedOnTime, // Đã nộp đúng hạn
  submittedLate,   // Đã nộp trễ (vượt qua 23:59)
}

class StudentTaskItem {
  final String id;
  final String title;
  final String description;
  final DateTime deadline; // Mốc deadline luôn là 23:59:59 của ngày hết hạn
  final String weekName;
  final String target;
  bool isSubmitted;
  DateTime? submittedAt;
  bool isLate;
  String? submissionNote;
  String? attachmentLink;

  StudentTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.weekName,
    required this.target,
    this.isSubmitted = false,
    this.submittedAt,
    this.isLate = false,
    this.submissionNote,
    this.attachmentLink,
  });

  TaskStatus get status {
    final now = DateTime.now();
    if (isSubmitted) {
      return isLate ? TaskStatus.submittedLate : TaskStatus.submittedOnTime;
    }
    if (now.isAfter(deadline)) {
      return TaskStatus.overdue;
    }
    return TaskStatus.pending;
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.pending:
        return 'Chưa nộp (Còn hạn)';
      case TaskStatus.overdue:
        return 'Quá hạn chưa nộp';
      case TaskStatus.submittedOnTime:
        return 'Đã nộp đúng hạn';
      case TaskStatus.submittedLate:
        return 'Nộp trễ';
    }
  }

  Color get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFF0284C7);
      case TaskStatus.overdue:
        return const Color(0xFFDC2626);
      case TaskStatus.submittedOnTime:
        return const Color(0xFF10B981);
      case TaskStatus.submittedLate:
        return const Color(0xFFEA580C);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFFE0F2FE);
      case TaskStatus.overdue:
        return const Color(0xFFFEE2E2);
      case TaskStatus.submittedOnTime:
        return const Color(0xFFD1FAE5);
      case TaskStatus.submittedLate:
        return const Color(0xFFFFEDD5);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TaskStatus.pending:
        return Icons.timer_outlined;
      case TaskStatus.overdue:
        return Icons.warning_amber_rounded;
      case TaskStatus.submittedOnTime:
        return Icons.check_circle_rounded;
      case TaskStatus.submittedLate:
        return Icons.assignment_late_rounded;
    }
  }

  // Tính thời gian còn lại hoặc quá hạn
  String get remainingTimeFormatted {
    final now = DateTime.now();
    if (isSubmitted) {
      final diff = submittedAt != null ? submittedAt!.difference(deadline) : Duration.zero;
      if (isLate) {
        return 'Đã nộp trễ ${diff.inHours.abs()} giờ (${submittedAt!.hour.toString().padLeft(2, '0')}:${submittedAt!.minute.toString().padLeft(2, '0')})';
      } else {
        return 'Nộp lúc ${submittedAt!.hour.toString().padLeft(2, '0')}:${submittedAt!.minute.toString().padLeft(2, '0')} ngày ${submittedAt!.day}/${submittedAt!.month}';
      }
    }

    final diff = deadline.difference(now);
    if (diff.isNegative) {
      final lateHours = diff.abs().inHours;
      final lateDays = diff.abs().inDays;
      if (lateDays > 0) {
        return 'Đã quá hạn $lateDays ngày (vẫn được nộp trễ)';
      }
      return 'Đã quá hạn $lateHours giờ (vẫn được nộp trễ)';
    } else {
      if (diff.inDays > 0) {
        final hours = diff.inHours % 24;
        return 'Còn ${diff.inDays} ngày $hours giờ (hạn 23:59)';
      } else if (diff.inHours > 0) {
        return 'Còn ${diff.inHours} giờ ${diff.inMinutes % 60} phút (hạn 23:59)';
      } else {
        return 'Sắp hết hạn! Còn ${diff.inMinutes} phút';
      }
    }
  }
}
