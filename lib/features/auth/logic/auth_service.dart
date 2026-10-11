import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../model/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<LoginResponseModel> login(String username, String password, bool rememberMe) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.login}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final utf8Body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(utf8Body);
      } catch (_) {}

      if (response.statusCode == 200) {
        final result = LoginResponseModel.fromJson(data);
        await StorageService.saveLoginData(
          token: result.token,
          user: result.user,
          rememberMe: rememberMe,
          username: username.trim(),
        );
        return result;
      } else {
        final message = data['message'] ?? 'Đăng nhập không thành công (Mã lỗi ${response.statusCode})';
        throw Exception(message);
      }
    } on http.ClientException {
      throw Exception('Không thể kết nối đến máy chủ Backend (${ApiEndpoints.baseUrl}). Vui lòng kiểm tra xem Backend ASP.NET Core đã được khởi động chưa!');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  Future<bool> checkLoggedIn() async {
    final token = await StorageService.getToken();
    final user = await StorageService.getUser();
    return token != null && token.isNotEmpty && user != null;
  }
}
