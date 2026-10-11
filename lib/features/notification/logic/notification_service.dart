import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../model/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<int> getUnreadCount() async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Notifications/unread-count');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['unreadCount'] ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<List<AppNotification>> getNotifications({int limit = 30}) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Notifications?limit=$limit');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Notifications/$notificationId/read');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}/Notifications/read-all');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
