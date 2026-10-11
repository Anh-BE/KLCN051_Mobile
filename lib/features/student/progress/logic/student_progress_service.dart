import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../model/student_progress_model.dart';

class StudentProgressService {
  static final StudentProgressService _instance = StudentProgressService._internal();
  factory StudentProgressService() => _instance;
  StudentProgressService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 1. Lấy thông tin đề tài và toàn bộ kế hoạch báo cáo tuần của sinh viên
  Future<StudentThesisProgressModel> getMyThesisProgress() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.studentMyThesisProgress}');
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return StudentThesisProgressModel.fromJson(decoded);
        }
      } else if (res.statusCode == 404) {
        return StudentThesisProgressModel(
          hasThesis: false,
          message: 'Không tìm thấy thông tin đề tài hoặc nhóm của bạn.',
        );
      } else {
        try {
          final errDecoded = jsonDecode(utf8.decode(res.bodyBytes));
          return StudentThesisProgressModel(
            hasThesis: false,
            message: errDecoded['message'] ?? 'Chưa có thông tin đề tài được duyệt.',
          );
        } catch (_) {
          return StudentThesisProgressModel(
            hasThesis: false,
            message: 'Chưa có thông tin đề tài được duyệt.',
          );
        }
      }
      return StudentThesisProgressModel(hasThesis: false, message: 'Chưa có thông tin đề tài.');
    } catch (e) {
      // Khi Backend chưa có dữ liệu hoặc mất kết nối
      return StudentThesisProgressModel(
        hasThesis: false,
        message: 'Chưa có thông tin kế hoạch tiến độ (Đang chờ nạp dữ liệu).',
      );
    }
  }

  /// 2. Nộp bài báo cáo tuần (Turn In)
  Future<Map<String, dynamic>> submitReport({
    required int planId,
    required String content,
    String? reportFileUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.submitProgressReport}');
      final body = jsonEncode({
        'planId': planId,
        'content': content.trim(),
        'reportFileUrl': reportFileUrl?.trim() ?? '',
      });

      final res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Nộp bài báo cáo thành công!',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Không thể nộp bài báo cáo (Mã lỗi: ${res.statusCode}).',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối khi nộp bài: $e',
      };
    }
  }

  /// 3. Hủy nộp bài (Unsubmit)
  Future<Map<String, dynamic>> unsubmitReport(int reportId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.unsubmitProgressReport(reportId)}');

      final res = await http.post(url, headers: headers).timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Đã hủy nộp bài thành công.',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Không thể hủy nộp bài.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối khi hủy nộp bài: $e',
      };
    }
  }

  /// 4. Tải tệp đính kèm lên máy chủ (Upload file báo cáo: PDF, DOCX, ZIP, v.v.)
  Future<Map<String, dynamic>> uploadReportFile({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.uploadReportFile}');
      final request = http.MultipartRequest('POST', url);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      } else if (fileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      } else {
        return {'success': false, 'message': 'Không tìm thấy tệp để tải lên.'};
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 40));
      final res = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200) {
        return {
          'success': true,
          'fileName': decoded['fileName'] ?? fileName,
          'fileUrl': decoded['fileUrl'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Tải tệp thất bại (Mã lỗi: ${res.statusCode}).',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối khi tải tệp: $e',
      };
    }
  }
}
