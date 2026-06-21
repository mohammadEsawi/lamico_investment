import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'socket_service.dart';

class AuthService {
  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;

  static Future<UserModel> login(String email, String password) async {
    final res = await ApiService.post('/auth/login',
        data: {'email': email, 'password': password});
    final token = res.data['token'] as String;
    final user = UserModel.fromJson(res.data as Map<String, dynamic>);
    await StorageService.saveToken(token);
    await StorageService.saveUser(jsonEncode(user.toJson()));
    _currentUser = user;
    SocketService.connect(token);
    return user;
  }

  static Future<void> register(Map<String, dynamic> data) async {
    await ApiService.post('/auth/register', data: data);
  }

  static Future<void> forgotPassword(String email) async {
    await ApiService.post('/auth/forgot-password', data: {'email': email});
  }

  static Future<void> resetPassword(String token, String password) async {
    await ApiService.post('/auth/reset-password',
        data: {'token': token, 'newPassword': password});
  }

  static Future<UserModel?> restoreSession() async {
    final userJson = await StorageService.getUser();
    final token    = await StorageService.getToken();
    if (userJson != null && token != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
      SocketService.connect(token);
      return _currentUser;
    }
    return null;
  }

  static Future<void> logout() async {
    try { await ApiService.post('/auth/logout'); } catch (_) {}
    SocketService.disconnect();
    await StorageService.clear();
    _currentUser = null;
  }

  // Called by ApiService interceptor on 401 — no API call, safe from recursion
  static void clearSession() {
    SocketService.disconnect();
    _currentUser = null;
  }
}
