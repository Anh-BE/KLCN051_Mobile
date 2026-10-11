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
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // Callback thông báo nổi In-App khi nhận tin mới
  void Function(NotificationModel notification)? onNotificationReceived;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  /// Khởi tạo kết nối SignalR với Backend
  Future<void> initSignalR() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;

    if (_hubConnection != null &&
        _hubConnection!.state == HubConnectionState.Connected) {
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
        debugPrint('[SignalR] Đã kết nối lại thành công: $connectionId');
        fetchUnreadCount();
      });

      _hubConnection!.onclose(({error}) {
        debugPrint('[SignalR] Kết nối đã đóng: $error');
      });

      await _hubConnection!.start();
      debugPrint('[SignalR] Đã kết nối NotificationHub thành công!');

      // Tải số lượng chưa đọc ban đầu
      await fetchUnreadCount();
    } catch (e) {
      debugPrint('[SignalR] Lỗi kết nối NotificationHub: $e');
    } finally {
      _isConnecting = false;
    }
  }

  void _handleIncomingNotification(List<dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final raw = arguments[0];
      Map<String, dynamic> data = {};
      if (raw is Map) {
        data = Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        data = jsonDecode(raw);
      }

      final notif = NotificationModel.fromJson(data);

      // Thêm vào đầu danh sách thông báo
      _notifications.removeWhere((n) => n.notificationId == notif.notificationId);
      _notifications.insert(0, notif);
      _unreadCount++;
      notifyListeners();

      // Bắn callback để hiện banner nổi nếu app đang mở
      onNotificationReceived?.call(notif);
    } catch (e) {
      debugPrint('[SignalR] Lỗi phân giải dữ liệu thông báo: $e');
    }
  }

  /// Tải danh sách lịch sử thông báo từ REST API
  Future<void> fetchNotifications({int limit = 20}) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notifications}?limit=$limit');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List<dynamic> listJson = jsonDecode(utf8Body);
        _notifications = listJson.map((e) => NotificationModel.fromJson(e)).toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('[NotificationService] Lỗi fetchNotifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải số lượng thông báo chưa đọc
  Future<void> fetchUnreadCount() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationsUnreadCount}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(utf8Body);
        _unreadCount = data['unreadCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationService] Lỗi fetchUnreadCount: $e');
    }
  }

  /// Đánh dấu 1 thông báo là đã đọc
  Future<bool> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationMarkAsRead(notificationId)}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NotificationService] Lỗi markAsRead: $e');
      return false;
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<bool> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationMarkAllAsRead}');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NotificationService] Lỗi markAllAsRead: $e');
      return false;
    }
  }

  /// Dừng kết nối SignalR và dọn dẹp bộ nhớ (khi đăng xuất)
  Future<void> stop() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (_) {}
      _hubConnection = null;
    }
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
