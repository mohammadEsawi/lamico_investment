import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  Future<void> restore() async {
    final user = await AuthService.restoreSession();
    state = user;
  }

  Future<UserModel> login(String email, String password) async {
    final user = await AuthService.login(email, password);
    state = user;
    return user;
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>(
  (_) => AuthNotifier(),
);
