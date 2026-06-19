import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userKey  = 'user_data';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<void> saveUser(String json) =>
      _storage.write(key: _userKey, value: json);

  static Future<String?> getUser() => _storage.read(key: _userKey);

  static Future<void> clear() => _storage.deleteAll();
}
