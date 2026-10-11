import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/storage_service.dart';
import '../model/scoring_model.dart';

class ScoringService {
  static final ScoringService _instance = ScoringService._internal();
  factory ScoringService() => _instance;
  ScoringService._internal();

  /// 1. Lấy danh sách đề tài và sinh viên cần chấm điểm theo loại (type: 'Supervisor' hoặc 'Reviewer')
  Future<List<ScoringThesisModel>> getThesesForScoring(String type) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.scoringTheses}?type=$type');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(res.bodyBytes));
        if (raw is List) {
          return raw
              .map((item) => ScoringThesisModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        debugPrint('[ScoringService] getThesesForScoring failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[ScoringService] Error getThesesForScoring: $e');
    }
    return [];
  }

  /// 2. Lấy danh sách tiêu chí Chuẩn đầu ra (CLO / Objectives) của đề tài để chấm điểm cho sinh viên
  Future<List<ObjectiveScoreModel>> getObjectivesForScoring({
    required int thesisId,
    required int studentId,
    required String evaluationType,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.scoringObjectives}/$thesisId?studentId=$studentId&evaluationType=$evaluationType',
      );
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final dynamic raw = jsonDecode(utf8.decode(res.bodyBytes));
        if (raw is List) {
          return raw
              .map((item) => ObjectiveScoreModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        debugPrint('[ScoringService] getObjectivesForScoring failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[ScoringService] Error getObjectivesForScoring: $e');
    }
    return [];
  }

  /// 3. Lưu điểm chuẩn đầu ra lên server
  Future<bool> saveScores({
    required int thesisId,
    required int studentId,
    required String evaluationType,
    required List<ObjectiveScoreModel> objectives,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.saveScore}');
      final body = jsonEncode({
        'thesisId': thesisId,
        'studentId': studentId,
        'evaluationType': evaluationType,
        'scores': objectives.map((o) => o.toJson()).toList(),
      });

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return true;
      } else {
        debugPrint('[ScoringService] saveScores failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[ScoringService] Error saveScores: $e');
    }
    return false;
  }
}
