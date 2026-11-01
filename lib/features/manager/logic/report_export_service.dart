import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/model/user_model.dart';
import '../../dashboard/logic/dashboard_service.dart';

class ReportExportData {
  final String reportCode;
  final String reportTitle;
  final String periodName;
  final List<String> headers;
  final List<List<String>> rows;

  ReportExportData({
    required this.reportCode,
    required this.reportTitle,
    required this.periodName,
    required this.headers,
    required this.rows,
  });

  /// Sinh chuỗi CSV chuẩn kèm UTF-8 BOM để Excel / Numbers mở không bao giờ lỗi font Tiếng Việt
  Uint8List toCsvBytes({required String exportedBy}) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Tiêu đề chuẩn mẫu biểu HUIT
    buffer.writeln('"TRƯỜNG ĐẠI HỌC CÔNG THƯƠNG TP. HỒ CHÍ MINH (HUIT)"');
    buffer.writeln('"KHOA CÔNG NGHỆ THÔNG TIN"');
    buffer.writeln('"BÁO CÁO: ${reportTitle.toUpperCase()}"');
    buffer.writeln('"Đợt Khóa Luận: $periodName"');
    buffer.writeln('"Thời Gian Trích Xuất: $dateStr"');
    buffer.writeln('"Người Xuất Dữ Liệu: $exportedBy - Ban Chủ Nhiệm Khoa"');
    buffer.writeln('""');

    // 2. Dòng tiêu đề cột
    buffer.writeln(headers.map(_escapeCsv).join(','));

    // 3. Các dòng dữ liệu
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsv).join(','));
    }

    // 4. Chân trang báo cáo
    buffer.writeln('""');
    buffer.writeln('"Tổng số bản ghi: ${rows.length}"');
    buffer.writeln('"Được trích xuất tự động từ Hệ thống Quản lý Khóa Luận Tốt Nghiệp HUIT."');

    final utf8Bom = [0xEF, 0xBB, 0xBF];
    final contentBytes = utf8.encode(buffer.toString());
    return Uint8List.fromList([...utf8Bom, ...contentBytes]);
  }

  String toClipboardText() {
    final buffer = StringBuffer();
    buffer.writeln('$reportTitle - HUIT ($periodName)');
    buffer.writeln(headers.join('\t'));
    for (final row in rows) {
      buffer.writeln(row.join('\t'));
    }
    return buffer.toString();
  }

  static String _escapeCsv(String val) {
    final escaped = val.replaceAll('"', '""');
    return '"$escaped"';
  }
}

class ReportExportService {
  static final ReportExportService _instance = ReportExportService._internal();
  factory ReportExportService() => _instance;
  ReportExportService._internal();

  final DashboardService _dashboardService = DashboardService();

  /// 1. TẠO BÁO CÁO 01: Danh sách Đề tài & Giảng viên Hướng dẫn
  Future<ReportExportData> prepareThesesReport({int? periodId}) async {
    final adminStats = await _dashboardService.getAdminStats(periodId: periodId);
    final deptStats = await _dashboardService.getDepartmentStats(periodId: periodId);

    final List<String> headers = [
      'STT',
      'Bộ Môn / Chuyên Ngành',
      'Tổng Số Đề Tài',
      'Đã Phê Duyệt',
      'Đang Chờ Duyệt',
      'Số Sinh Viên Đăng Ký',
      'Số Giảng Viên HD',
      'Tỷ Lệ Duyệt',
    ];

    final List<List<String>> rows = [];
    int index = 1;
    for (final dept in deptStats) {
      final rate = dept.totalTheses > 0 ? '${((dept.approvedTheses / dept.totalTheses) * 100).toInt()}%' : '0%';
      rows.add([
        '$index',
        dept.departmentName,
        '${dept.totalTheses}',
        '${dept.approvedTheses}',
        '${dept.pendingTheses}',
        '${dept.studentCount}',
        '${dept.lecturerCount}',
        rate,
      ]);
      index++;
    }

    return ReportExportData(
      reportCode: 'BC01_DanhSachDeTai_GVHD',
      reportTitle: 'Danh Sách Đề Tài & Phân Bổ Bộ Môn',
      periodName: adminStats.periodName.isNotEmpty ? adminStats.periodName : 'HK1 (2026-2027)',
      headers: headers,
      rows: rows,
    );
  }

  /// 2. TẠO BÁO CÁO 02: Tình hình Tiến độ Tuần & Thống kê Nộp trễ
  Future<ReportExportData> prepareLateSubmissionsReport({int? periodId}) async {
    final lateItems = await _dashboardService.getLateSubmissions(periodId: periodId);
    final adminStats = await _dashboardService.getAdminStats(periodId: periodId);

    final List<String> headers = [
      'STT',
      'Mã Sinh Viên',
      'Họ và Tên Sinh Viên',
      'Tên Nhóm Khóa Luận',
      'Nhiệm Vụ Báo Cáo',
      'Mốc Hạn Nộp',
      'Thời Gian Nộp Thực Tế',
      'Số Giờ Nộp Trễ',
      'Lý Do Trình Bày',
    ];

    final List<List<String>> rows = [];
    if (lateItems.isEmpty) {
      rows.add([
        '1',
        '---',
        'Không có lượt nộp trễ hạn',
        'Toàn khoa',
        'Báo cáo tuần',
        '23:59',
        'Đúng hạn',
        '0 giờ',
        'Không ghi nhận sinh viên nộp trễ hạn mốc 23:59',
      ]);
    } else {
      int index = 1;
      for (final item in lateItems) {
        rows.add([
          '$index',
          item.studentCode,
          item.studentName,
          item.groupName,
          item.taskName,
          item.deadlineStr,
          item.submittedTimeStr,
          '${item.lateHours} giờ',
          item.reason.isNotEmpty ? item.reason : 'Không nêu lý do',
        ]);
        index++;
      }
    }

    return ReportExportData(
      reportCode: 'BC02_TienDo_NopTre',
      reportTitle: 'Báo Cáo Tiến Độ Tuần & Thống Kê Nộp Trễ Hạn',
      periodName: adminStats.periodName.isNotEmpty ? adminStats.periodName : 'HK1 (2026-2027)',
      headers: headers,
      rows: rows,
    );
  }

  /// 3. TẠO BÁO CÁO 03: Quyết định Phân công Hội đồng Bảo vệ
  Future<ReportExportData> prepareCommitteesReport({int? periodId}) async {
    final committees = await _dashboardService.getDefenseCommittees(periodId: periodId);
    final adminStats = await _dashboardService.getAdminStats(periodId: periodId);

    final List<String> headers = [
      'STT',
      'Mã Hội Đồng',
      'Tên Hội Đồng Đánh Giá',
      'Chủ Tịch Hội Đồng',
      'Thư Ký Hội Đồng',
      'Ủy Viên Phản Biện',
      'Phòng Bảo Vệ',
      'Ngày Bảo Vệ',
      'Số Nhóm SV Phân Công',
    ];

    final List<List<String>> rows = [];
    if (committees.isEmpty) {
      rows.add([
        '1',
        'HĐ-CHUA_LAP',
        'Chưa thành lập hội đồng bảo vệ trong đợt này',
        'Đang cập nhật',
        'Đang cập nhật',
        'Đang cập nhật',
        'Chưa xếp phòng',
        'Chưa xếp lịch',
        '0',
      ]);
    } else {
      int index = 1;
      for (final c in committees) {
        rows.add([
          '$index',
          c.committeeCode,
          c.name,
          c.president,
          c.secretary,
          c.reviewer,
          c.room,
          c.defenseDate,
          '${c.assignedGroups}',
        ]);
        index++;
      }
    }

    return ReportExportData(
      reportCode: 'BC03_HoiDongBaoVe',
      reportTitle: 'Quyết Định Phân Công Hội Đồng Bảo Vệ Khóa Luận',
      periodName: adminStats.periodName.isNotEmpty ? adminStats.periodName : 'HK1 (2026-2027)',
      headers: headers,
      rows: rows,
    );
  }

  /// 4. TẠO BÁO CÁO 04: Thống kê Điểm số & Xếp loại Khóa luận
  Future<ReportExportData> prepareScoringOverviewReport({int? periodId}) async {
    final adminStats = await _dashboardService.getAdminStats(periodId: periodId);
    final deptStats = await _dashboardService.getDepartmentStats(periodId: periodId);

    final List<String> headers = [
      'STT',
      'Chuyên Ngành / Bộ Môn',
      'Đề Tài Đã Giao',
      'Đề Tài Có SV Đăng Ký',
      'Tỷ Lệ Đạt Tiến Độ',
      'Đánh Giá Chung',
    ];

    final List<List<String>> rows = [];
    int index = 1;
    for (final dept in deptStats) {
      final rate = dept.totalTheses > 0 ? (dept.approvedTheses / dept.totalTheses) : 0.0;
      final rateStr = '${(rate * 100).toInt()}%';
      final status = rate >= 0.8 ? 'Rất Tốt (Hoàn thành tiến độ)' : (rate >= 0.5 ? 'Đạt yêu cầu' : 'Cần đôn đốc');

      rows.add([
        '$index',
        dept.departmentName,
        '${dept.totalTheses}',
        '${dept.approvedTheses}',
        rateStr,
        status,
      ]);
      index++;
    }

    return ReportExportData(
      reportCode: 'BC04_ThongKe_XepLoai',
      reportTitle: 'Báo Cáo Tổng Hợp Điểm Số & Đánh Giá Tiến Độ',
      periodName: adminStats.periodName.isNotEmpty ? adminStats.periodName : 'HK1 (2026-2027)',
      headers: headers,
      rows: rows,
    );
  }

  /// Xử lý xuất file chuẩn Mobile / Web
  Future<void> exportAndSaveFile({
    required BuildContext context,
    required ReportExportData data,
    required UserModel user,
  }) async {
    try {
      final bytes = data.toCsvBytes(exportedBy: user.fullName);
      final fileName = '${data.reportCode}_${DateTime.now().millisecondsSinceEpoch}.csv';

      // 1. Gọi FilePicker để mở hộp thoại lưu chuẩn đa nền tảng (Web / Mobile / Desktop)
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Chọn nơi lưu tệp báo cáo:',
        fileName: fileName,
        mimeType: 'text/csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      if (context.mounted) {
        AppToast.showSuccess(
          context,
          savedUri != null
              ? 'Tệp đã được lưu thành công tại:\n${savedUri.path}'
              : 'Đã xuất file $fileName thành công!',
          title: 'Kết xuất thành công',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(
          context,
          'Lỗi khi lưu tệp: $e',
          title: 'Xuất tệp thất bại',
        );
      }
    }
  }
}

