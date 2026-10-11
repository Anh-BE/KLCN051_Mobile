import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../model/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  HubConnection? _hubConnection;
  bool _isConnecting = false;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  void Function(AppNotification notification)? onNotificationReceived;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  /// Khởi tạo kết nối SignalR với Backend
  Future<void> initSignalR() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;

    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      return;
    }

    if (_isConnecting) return;
    _isConnecting = true;

    try {
      final hubUrl = ApiEndpoints.hubUrl;
      debugPrint('[SignalR] Đang kết nối tới: $hubUrl');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => (await StorageService.getToken()) ?? '',
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('ReceiveNotification', (arguments) {
        _handleIncomingNotification(arguments);
      });

      _hubConnection!.onreconnected(({connectionId}) {
        debugPrint('[SignalR] Đã kết nối lại: $connectionId');
        fetchUnreadCount();
      });

      _hubConnection!.onclose(({error}) {
        debugPrint('[SignalR] Kết nối đã đóng: $error');
      });

      await _hubConnection!.start();
      debugPrint('[SignalR] Đã kết nối NotificationHub thành công!');

      await fetchUnreadCount();
    } catch (e) {
      debugPrint('[SignalR] Lỗi kết nối SignalR: $e');
    } finally {
      _isConnecting = false;
    }
  }

  void _handleIncomingNotification(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final data = arguments.first;
      AppNotification notif;
      if (data is Map) {
        notif = AppNotification.fromJson(data);
      } else if (data is String) {
        final decoded = jsonDecode(data);
        notif = AppNotification.fromJson(decoded);
      } else {
        return;
      }

      _notifications.insert(0, notif);
      _unreadCount++;
      notifyListeners();

      onNotificationReceived?.call(notif);
    } catch (e) {
      debugPrint('[SignalR] Lỗi xử lý thông báo nhận về: $e');
    }
  }

  /// Lấy số lượng thông báo chưa đọc từ API
  Future<int> getUnreadCount() async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationsUnreadCount}');
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
        final count = (data is Map && data['unreadCount'] is int) ? data['unreadCount'] as int : 0;
        _unreadCount = count;
        notifyListeners();
        return count;
      }
    } catch (_) {}
    return _unreadCount;
  }

  Future<void> fetchUnreadCount() async {
    await getUnreadCount();
  }

  /// Lấy danh sách thông báo
  Future<List<AppNotification>> getNotifications({int limit = 30}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notifications}?limit=$limit');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final List<AppNotification> list = [];
          for (final item in decoded) {
            if (item is Map) {
              list.add(AppNotification.fromJson(item));
            }
          }
          _notifications = list;
          return list;
        }
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _notifications;
  }

  Future<void> fetchNotifications({int limit = 30}) async {
    await getNotifications(limit: limit);
  }

  /// Đánh dấu một thông báo đã đọc
  Future<bool> markAsRead(int notificationId) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationMarkAsRead(notificationId)}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          if (_unreadCount > 0) _unreadCount--;
          notifyListeners();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<bool> markAllAsRead() async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationMarkAllAsRead}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Dừng kết nối SignalR (khi logout)
  Future<void> stop() async {
    try {
      if (_hubConnection != null) {
        await _hubConnection!.stop();
        _hubConnection = null;
      }
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[SignalR] Lỗi dừng kết nối: $e');
    }
  }
}
