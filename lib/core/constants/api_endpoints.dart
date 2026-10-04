import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Địa chỉ Backend ASP.NET Core:
  // - Khi chạy trên Web / Windows Desktop: gọi trực tiếp http://localhost:5293/api (hoặc https://localhost:7292/api)
  // - Khi chạy trên Android Emulator: đổi localhost thành 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:5293/api';
      }
      return 'http://localhost:5293/api';
    }
    // Dành cho Android Emulator
    return 'http://10.0.2.2:5293/api';
  }

  static const String login = '/Auth/login';
  static const String theses = '/Theses';
}
